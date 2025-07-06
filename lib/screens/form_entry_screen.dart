import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/lenient_app_bar.dart';
import '../utils/pdf_generator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' show Offset;
import 'dart:typed_data';
import '../models/form_model.dart';
import '../services/supabase_service.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_dialog.dart';
import 'package:uuid/uuid.dart';
import 'pdf_preview_screen.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class FormEntryScreen extends StatefulWidget {
  final String? formId;
  const FormEntryScreen({super.key, this.formId});

  @override
  State<FormEntryScreen> createState() => _FormEntryScreenState();
}

class _FormEntryScreenState extends State<FormEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController taskIdController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressLineController = TextEditingController();
  final TextEditingController addressCityController = TextEditingController();
  final TextEditingController problemDescriptionController = TextEditingController();
  final TextEditingController reportDescriptionController = TextEditingController();
  final TextEditingController materialsDeliveredController = TextEditingController();
  final TextEditingController materialsReceivedController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  String reportedBy = 'Durai';
  List<File> beforePhotos = [];
  List<String> beforePhotoUrls = [];
  List<File> afterPhotos = [];
  List<String> afterPhotoUrls = [];
  int rating = 4;
  String? signatureUrl;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingSignature = false;
  Uint8List? signaturePreview;
  List<Offset?> signaturePoints = [];
  FormModel? formEntry;
  DateTime createdAt = DateTime.now().toUtc();
  DateTime updatedAt = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _loadForm();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    taskIdController.dispose();
    companyNameController.dispose();
    phoneController.dispose();
    addressLineController.dispose();
    addressCityController.dispose();
    problemDescriptionController.dispose();
    reportDescriptionController.dispose();
    materialsDeliveredController.dispose();
    materialsReceivedController.dispose();
    customerNameController.dispose();
    super.dispose();
  }

  /// Loads the form from Supabase if editing, otherwise prepares for new entry.
  Future<void> _loadForm() async {
    try {
      formEntry = await SupabaseService.getForm(widget.formId!);
      if (formEntry != null) {
        setState(() {
          _loading = false;
          taskIdController.text = formEntry!.taskId;
          companyNameController.text = formEntry!.companyName ?? '';
          phoneController.text = formEntry!.phone ?? '';
          addressLineController.text = formEntry!.addressLine ?? '';
          addressCityController.text = formEntry!.addressCity ?? '';
          reportedBy = formEntry!.reportedBy ?? '';
          problemDescriptionController.text = formEntry!.problemDescription ?? '';
          reportDescriptionController.text = formEntry!.reportDescription ?? '';
          materialsDeliveredController.text = formEntry!.materialsDelivered ?? '';
          materialsReceivedController.text = formEntry!.materialsReceived ?? '';
          customerNameController.text = formEntry!.customeName ?? '';
          beforePhotos = [];
          beforePhotoUrls = (formEntry!.beforePhotoUrls ?? []);
          afterPhotos = [];
          afterPhotoUrls = (formEntry!.afterPhotoUrls ?? []);
          rating = formEntry!.rating ?? 0;
          signatureUrl = formEntry!.signatureUrl;
          createdAt = formEntry!.createdAt;
          updatedAt = formEntry!.updatedAt;
        });
      } else {
        setState(() { _loading = false; });
        LenientSnackbar.showWarning(context, 'Form not found.');
      }
    } catch (e) {
      setState(() { _loading = false; });
      LenientSnackbar.showError(context, getFriendlyErrorMessage(e));
    }
  }

  /// Saves the form to Supabase. Shows loading indicator and error feedback.
  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; });
    await Future.delayed(const Duration(milliseconds: 100)); // Let UI update
    try {
      // Track removed images
      final removedBeforeUrls = <String>[];
      final removedAfterUrls = <String>[];
      if (formEntry != null) {
        for (final url in formEntry!.beforePhotoUrls ?? []) {
          if (!beforePhotoUrls.contains(url)) removedBeforeUrls.add(url);
        }
        for (final url in formEntry!.afterPhotoUrls ?? []) {
          if (!afterPhotoUrls.contains(url)) removedAfterUrls.add(url);
        }
      }
      // debugPrint('Removed before image URLs: $removedBeforeUrls');
      // debugPrint('Removed after image URLs: $removedAfterUrls');
      final form = FormModel(
        id: formEntry?.id ?? const Uuid().v4(),
        taskId: taskIdController.text,
        formType: 'Form1',
        companyName: companyNameController.text,
        phone: phoneController.text,
        addressLine: addressLineController.text,
        addressCity: addressCityController.text,
        reportedBy: reportedBy,
        problemDescription: problemDescriptionController.text,
        reportDescription: reportDescriptionController.text,
        materialsDelivered: materialsDeliveredController.text,
        materialsReceived: materialsReceivedController.text,
        customeName: customerNameController.text,
        rating: rating,
        signatureUrl: formEntry?.signatureUrl,
        beforePhotoUrls: beforePhotoUrls,
        afterPhotoUrls: afterPhotoUrls,
        createdAt: formEntry?.createdAt ?? DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      // debugPrint('Calling SupabaseService.uploadForm with isEdit: ${formEntry != null}');
      final newForm = await SupabaseService.uploadForm(
        form: form,
        signatureBytes: signaturePreview,
        before: beforePhotos,
        after: afterPhotos,
        isEdit: formEntry != null,
        oldBeforeUrls: removedBeforeUrls,
        oldAfterUrls: removedAfterUrls,
        oldSignatureUrl: formEntry?.signatureUrl,
      );
      // debugPrint('Form upload complete. New form: ${newForm.toMap()}');
      setState(() {
        formEntry = newForm;
        beforePhotos.clear();
        afterPhotos.clear();
      });
      // Clean up cache files
      for (final file in beforePhotos) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      for (final file in afterPhotos) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (mounted) {
        LenientSnackbar.showSuccess(context, 'Form saved successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      // debugPrint('Error in _saveForm: $e');
      LenientSnackbar.showError(context, getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  /// Shows a dialog to choose image source (camera or gallery) and picks image.
  Future<void> _showImageSourceDialog(List<File> photoList) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(photoList, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(photoList, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Picks an image from the specified source and adds it to the given photo list.
  Future<void> _pickImage(List<File> photoList, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          photoList.add(File(picked.path));
        });
      } else {
        // Always show error if no image is selected (either cancel or permission denied)
        // LenientSnackbar.showError(context, 'No image selected or permission denied.');
      }
    } catch (e) {
      LenientSnackbar.showError(context, 'Failed to pick image: $e');
    }
  }

  /// Shows a dialog for the user to draw and upload a signature.
  Future<void> _showSignatureDialog() async {
    List<Offset?> tempPoints = List.from(signaturePoints);
    Uint8List? tempImage;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Customer Signature'),
          content: SizedBox(
            width: 350,
            height: 200,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: _SignatureBox(
                          points: tempPoints,
                          onDraw: (pts) async {
                            setStateDialog(() => tempPoints = List.from(pts));
                            if (pts.isNotEmpty) {
                              tempImage = await convertSignatureToImage(pts, width: 350, height: 120);
                            }
                          },
                          onClear: () {
                            setStateDialog(() {
                              tempPoints = [];
                              tempImage = null;
                            });
                          },
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_uploadingSignature)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                tempPoints = [];
                                tempImage = null;
                              });
                              setState(() {
                                signaturePoints = [];
                                signaturePreview = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7ED957),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: _uploadingSignature
                                ? null
                                : () async {
                                    if (tempPoints.isEmpty) {
                                      LenientSnackbar.showWarning(context, 'Please provide a signature.');
                                      return;
                                    }
                                    setState(() {
                                      signaturePreview = tempImage;
                                      signaturePoints = List.from(tempPoints);
                                    });
                                    Navigator.of(context).pop();
                                  },
                            child: const Text('Capture'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: AppBar(
            backgroundColor: const Color(0xFFF7F9FB),
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) Navigator.of(context).pop();
                },
              ),
            ),
            title: const Text('', style: TextStyle(color: Colors.black)),
            toolbarHeight: 72,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormLabel('Task ID', required: true),
                _FormTextField(
                  hint: 'LTS-',
                  controller: taskIdController,
                  validator: (v) => v == null || v.isEmpty ? 'Task ID is required' : null,
                ),
                _FormLabel('Company / Contact name', required: true),
                _FormTextField(
                  controller: companyNameController,
                  validator: (v) => v == null || v.isEmpty ? 'Company/Contact name is required' : null,
                ),
                _FormLabel('Phone'),
                _FormTextField(
                  hint: '(+91) 9876543210',
                  controller: phoneController,
                ),
                _FormLabel('Address'),
                Row(
                  children: [
                    Expanded(
                      child: _FormTextField(
                        hint: 'Line',
                        controller: addressLineController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormTextField(
                        hint: 'City',
                        controller: addressCityController,
                      ),
                    ),
                  ],
                ),
                _FormLabel('Reported By'),
                _FormDropdown(
                  items: const ['Durai', 'Elango', 'Lenin', 'Mani', 'Mohan ID', 'Mohan', 'Nandhini ', 'Priya', 'Seeni', 'Other'],
                  value: reportedBy,
                  onChanged: (v) => setState(() => reportedBy = v ?? 'Durai'),
                ),
                _FormLabel('Problem Description'),
                _FormTextField(
                  controller: problemDescriptionController,
                  maxLines: 4,
                ),
                _FormLabel('Report Description'),
                _FormTextField(
                  controller: reportDescriptionController,
                  maxLines: 4,
                ),
                _FormLabel('Materials Delivered'),
                _FormTextField(
                  controller: materialsDeliveredController,
                  maxLines: 3,
                ),
                _FormLabel('Materials Received'),
                _FormTextField(
                  controller: materialsReceivedController,
                  maxLines: 3,
                ),
                _FormLabel('Before (Max 3 Photos)'),
                _PhotoGrid(
                  files: beforePhotos,
                  urls: beforePhotoUrls,
                  onAdd: () => _showImageSourceDialog(beforePhotos),
                  onRemoveFile: (i) => setState(() => beforePhotos.removeAt(i)),
                  onRemoveUrl: (i) => setState(() => beforePhotoUrls.removeAt(i)),
                ),
                _FormLabel('After (Max 3 Photos)'),
                _PhotoGrid(
                  files: afterPhotos,
                  urls: afterPhotoUrls,
                  onAdd: () => _showImageSourceDialog(afterPhotos),
                  onRemoveFile: (i) => setState(() => afterPhotos.removeAt(i)),
                  onRemoveUrl: (i) => setState(() => afterPhotoUrls.removeAt(i)),
                ),
                _FormLabel('Customer Name'),
                _FormTextField(
                  controller: customerNameController,
                ),
                _FormLabel('Customer Signature (only Customers)'),
                GestureDetector(
                  onTap: _showSignatureDialog,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    alignment: Alignment.center,
                    child: signaturePreview != null
                        ? Image.memory(signaturePreview!, height: 64)
                        : (signatureUrl != null
                            ? Image.network(signatureUrl!, height: 64)
                            : const Text('Tap to sign', style: TextStyle(color: Colors.grey))),
                  ),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                _FormLabel('Customer Rating (only Customers)'),
                _StarRating(
                  rating: rating,
                  onChanged: (v) => setState(() => rating = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7ED957),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saveForm,
                    child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges()) {
      final confirm = await LenientDialog.showConfirm(
        context,
        title: 'Discard changes?',
        content: 'You have unsaved changes. Are you sure you want to discard them?',
        confirmText: 'Discard',
        cancelText: 'Cancel',
        confirmColor: Colors.red,
        cancelColor: Colors.black,
      );
      return confirm == true;
    }
    return true;
  }

  bool _hasUnsavedChanges() {
    if (formEntry != null) {
      return taskIdController.text != formEntry!.taskId ||
          companyNameController.text != formEntry!.companyName ||
          phoneController.text != formEntry!.phone ||
          addressLineController.text != formEntry!.addressLine ||
          addressCityController.text != formEntry!.addressCity ||
          reportedBy != formEntry!.reportedBy ||
          problemDescriptionController.text != formEntry!.problemDescription ||
          reportDescriptionController.text != formEntry!.reportDescription ||
          materialsDeliveredController.text != formEntry!.materialsDelivered ||
          materialsReceivedController.text != formEntry!.materialsReceived ||
          customerNameController.text != formEntry!.customeName ||
          beforePhotoUrls.toString() != formEntry!.beforePhotoUrls.toString() ||
          afterPhotoUrls.toString() != formEntry!.afterPhotoUrls.toString() ||
          signatureUrl != formEntry!.signatureUrl ||
          rating != formEntry!.rating;
    } else {
      return taskIdController.text.isNotEmpty ||
          companyNameController.text.isNotEmpty ||
          phoneController.text.isNotEmpty ||
          addressLineController.text.isNotEmpty ||
          addressCityController.text.isNotEmpty ||
          reportedBy != 'Durai' ||
          problemDescriptionController.text.isNotEmpty ||
          reportDescriptionController.text.isNotEmpty ||
          materialsDeliveredController.text.isNotEmpty ||
          materialsReceivedController.text.isNotEmpty ||
          customerNameController.text.isNotEmpty ||
          beforePhotoUrls.isNotEmpty ||
          afterPhotoUrls.isNotEmpty ||
          signatureUrl != null ||
          rating != 4;
    }
  }

  String getFriendlyErrorMessage(dynamic error) {
    final msg = error.toString();
    if (msg.contains('duplicate key value') && msg.contains('forms_task_id_key')) {
      return 'Task ID already exists. Try another Task ID';
    } else if (msg.contains('row-level security policy') || msg.contains('Unauthorized')) {
      return 'Not authorized to perform this action.';
    } else if (msg.contains('StorageException')) {
      return 'Upload failed. Try again';
    }
    return 'Something went wrong.';
  }
}

// --- Helper Widgets ---

class _FormLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FormLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 15),
          ),
          if (required)
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 15)),
        ],
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final String? hint;
  final int maxLines;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final String? initialValue;
  final TextEditingController? controller;
  const _FormTextField({this.hint, this.maxLines = 1, this.onSaved, this.validator, this.initialValue, this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        onSaved: onSaved,
        validator: validator,
        initialValue: controller == null ? initialValue : null,
        controller: controller,
      ),
    );
  }
}

class _FormDropdown extends StatelessWidget {
  final List<String> items;
  final String value;
  final Function(String?) onChanged;
  const _FormDropdown({required this.items, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
        onChanged: onChanged,
        value: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<File> files;
  final List<String> urls;
  final VoidCallback onAdd;
  final Function(int) onRemoveFile;
  final Function(int) onRemoveUrl;
  const _PhotoGrid({required this.files, required this.urls, required this.onAdd, required this.onRemoveFile, required this.onRemoveUrl});

  @override
  Widget build(BuildContext context) {
    // debugPrint('PhotoGrid: urls=$urls, files=${files.map((f) => f.path).toList()}');
    final total = files.length + urls.length;
    final canAdd = total < 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          ...List.generate(3, (i) {
            if (i < urls.length) {
              // debugPrint('PhotoGrid: showing network image: ${urls[i]}');
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(urls[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemoveUrl(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            } else if (i < urls.length + files.length) {
              final fileIdx = i - urls.length;
              // debugPrint('PhotoGrid: showing file image: ${files[fileIdx].path}');
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(files[fileIdx]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemoveFile(fileIdx),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            } else if (i == total && canAdd) {
              return GestureDetector(
                onTap: onAdd,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              );
            } else {
              return const SizedBox(width: 64);
            }
          }),
          const Spacer(),
          GestureDetector(
            onTap: canAdd
                ? onAdd
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maximum 3 images allowed.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: canAdd ? Colors.black : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureBox extends StatefulWidget {
  final List<Offset?> points;
  final ValueChanged<List<Offset?>> onDraw;
  final VoidCallback onClear;
  final double height;
  const _SignatureBox({this.points = const [], required this.onDraw, required this.onClear, this.height = 80});

  @override
  State<_SignatureBox> createState() => _SignatureBoxState();
}

class _SignatureBoxState extends State<_SignatureBox> {
  List<Offset?> _points = [];

  @override
  void initState() {
    super.initState();
    _points = widget.points;
  }

  @override
  void didUpdateWidget(covariant _SignatureBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points != oldWidget.points) {
      setState(() {
        _points = widget.points;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          RenderBox? box = context.findRenderObject() as RenderBox?;
          Offset point = box!.globalToLocal(details.globalPosition);
          setState(() {
            _points = List.from(_points)..add(point);
            widget.onDraw(_points);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _points = List.from(_points)..add(null);
            widget.onDraw(_points);
          });
        },
        child: CustomPaint(
          painter: _SignaturePainter(_points),
          child: Container(),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => oldDelegate.points != points;
}

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: SvgPicture.asset(
            index < rating
                ? 'assets/fill-star-icon.svg'
                : 'assets/stroke-star-icon.svg',
            width: 36,
            height: 36,
          ),
          onPressed: () => onChanged(index + 1),
        );
      }),
    );
  }
} 