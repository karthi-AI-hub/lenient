import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/lenient_app_bar.dart';
import '../utils/pdf_generator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' show Offset;
import 'dart:typed_data';
import 'package:hive/hive.dart';
import '../models/form_entry.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_dialog.dart';
import 'package:uuid/uuid.dart';
import 'pdf_preview_screen.dart';
import 'package:path_provider/path_provider.dart';

class FormEntryScreen extends StatefulWidget {
  final String? formId;
  const FormEntryScreen({super.key, this.formId});

  @override
  State<FormEntryScreen> createState() => _FormEntryScreenState();
}

class _FormEntryScreenState extends State<FormEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String taskId = '';
  String dateTime = '';
  String companyName = '';
  String phone = '';
  String addressLine = '';
  String addressCity = '';
  String reportedBy = 'Durai';
  String problemDescription = '';
  String reportDescription = '';
  String materialsDelivered = '';
  String materialsReceived = '';
  List<File> beforePhotos = [];
  List<File> afterPhotos = [];
  String customerName = '';
  String customerSignature = '';
  int rating = 4;
  List<Offset?> signaturePoints = [];
  final _taskIdFocus = FocusNode();
  final _dateTimeFocus = FocusNode();
  final _companyNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _problemDescFocus = FocusNode();
  final _reportDescFocus = FocusNode();
  final _customerNameFocus = FocusNode();
  final _signatureBoxKey = GlobalKey();
  bool _isSigning = false;
  final ScrollController _scrollController = ScrollController();
  Uint8List? signaturePreview;
  final TextEditingController _dateTimeController = TextEditingController();
  FormEntry? formEntry;
  bool _loading = true;
  final TextEditingController _taskIdController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLineController = TextEditingController();
  final TextEditingController _addressCityController = TextEditingController();
  final TextEditingController _problemDescController = TextEditingController();
  final TextEditingController _reportDescController = TextEditingController();
  final TextEditingController _materialsDeliveredController = TextEditingController();
  final TextEditingController _materialsReceivedController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (dateTime.isEmpty) {
      final now = DateTime.now();
      final time = TimeOfDay.fromDateTime(now);
      dateTime = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} '
          '${time.format(context)}';
      _dateTimeController.text = dateTime;
    } else {
      _dateTimeController.text = dateTime;
    }
  }

  Future<void> _loadForm() async {
    final box = Hive.box<FormEntry>('forms');
    formEntry = box.get(widget.formId);
    if (formEntry != null) {
      debugPrint('Loaded form: \n$formEntry');
      setState(() {
        _loading = false;
        taskId = formEntry!.taskId;
        _taskIdController.text = formEntry!.taskId;
        dateTime = formEntry!.dateTime;
        companyName = formEntry!.companyName;
        _companyNameController.text = formEntry!.companyName;
        phone = formEntry!.phone;
        _phoneController.text = formEntry!.phone;
        addressLine = formEntry!.addressLine;
        _addressLineController.text = formEntry!.addressLine;
        addressCity = formEntry!.addressCity;
        _addressCityController.text = formEntry!.addressCity;
        reportedBy = formEntry!.reportedBy;
        problemDescription = formEntry!.problemDescription;
        _problemDescController.text = formEntry!.problemDescription;
        reportDescription = formEntry!.reportDescription;
        _reportDescController.text = formEntry!.reportDescription;
        materialsDelivered = formEntry!.materialsDelivered;
        _materialsDeliveredController.text = formEntry!.materialsDelivered;
        materialsReceived = formEntry!.materialsReceived;
        _materialsReceivedController.text = formEntry!.materialsReceived;
        beforePhotos = formEntry!.beforePhotoPaths.map((p) => File(p)).toList();
        afterPhotos = formEntry!.afterPhotoPaths.map((p) => File(p)).toList();
        customerName = formEntry!.customerName;
        _customerNameController.text = formEntry!.customerName;
        signaturePreview = formEntry!.signatureImage;
        rating = formEntry!.rating;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _saveForm() async {
    bool valid = _formKey.currentState!.validate();
    if (!valid) {
      _focusFirstInvalidField();
      LenientSnackbar.showError(context, 'Please fill all required fields.');
      return;
    }
    _formKey.currentState!.save();
    final box = Hive.box<FormEntry>('forms');
    if (formEntry == null) {
      final id = const Uuid().v4();
      formEntry = FormEntry(
        id: id,
        taskId: taskId,
        dateTime: dateTime,
        companyName: companyName,
        phone: phone,
        addressLine: addressLine,
        addressCity: addressCity,
        reportedBy: reportedBy,
        problemDescription: problemDescription,
        reportDescription: reportDescription,
        materialsDelivered: materialsDelivered,
        materialsReceived: materialsReceived,
        beforePhotoPaths: beforePhotos.map((f) => f.path).toList(),
        afterPhotoPaths: afterPhotos.map((f) => f.path).toList(),
        customerName: customerName,
        signatureImage: signaturePreview,
        rating: rating,
        status: FormStatus.saved,
        formType: 1,
      );
    } else {
      formEntry!
        ..taskId = taskId
        ..dateTime = dateTime
        ..companyName = companyName
        ..phone = phone
        ..addressLine = addressLine
        ..addressCity = addressCity
        ..reportedBy = reportedBy
        ..problemDescription = problemDescription
        ..reportDescription = reportDescription
        ..materialsDelivered = materialsDelivered
        ..materialsReceived = materialsReceived
        ..beforePhotoPaths = beforePhotos.map((f) => f.path).toList()
        ..afterPhotoPaths = afterPhotos.map((f) => f.path).toList()
        ..customerName = customerName
        ..signatureImage = signaturePreview
        ..rating = rating
        ..status = FormStatus.saved;
    }
    debugPrint('Saving form: \n$formEntry');
    await box.put(formEntry!.id, formEntry!);

    FocusScope.of(context).unfocus();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    LenientSnackbar.showSuccess(context, 'Form saved.', milliseconds: 1200);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context).pop();
  }

  void _focusFirstInvalidField() {
    if (taskId.isEmpty || !taskId.startsWith('LTS-')) {
      FocusScope.of(context).requestFocus(_taskIdFocus);
    } else if (dateTime.isEmpty) {
      FocusScope.of(context).requestFocus(_dateTimeFocus);
    } else if (companyName.isEmpty) {
      FocusScope.of(context).requestFocus(_companyNameFocus);
    } else if (phone.isEmpty) {
      FocusScope.of(context).requestFocus(_phoneFocus);
    } else if (problemDescription.isEmpty) {
      FocusScope.of(context).requestFocus(_problemDescFocus);
    } else if (reportDescription.isEmpty) {
      FocusScope.of(context).requestFocus(_reportDescFocus);
    } else if (customerName.isEmpty) {
      FocusScope.of(context).requestFocus(_customerNameFocus);
    }
  }

  Future<void> _pickImage(List<File> photoList) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        photoList.add(File(picked.path));
      });
    }
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          dateTime = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
              '${time.format(context)}';
          _dateTimeController.text = dateTime;
        });
      }
    }
  }

  void _clearSignature() {
    setState(() {
      signaturePoints.clear();
    });
  }

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
                            onPressed: () {
                              setState(() {
                                signaturePoints = List.from(tempPoints);
                                signaturePreview = tempImage;
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
          child: Stack(
            children: [
              const LenientAppBar(),
              SizedBox(
                height: 72,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () async {
                          final shouldPop = await _onWillPop();
                          if (shouldPop && mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: _isSigning ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormLabel('Task ID', required: true),
                _FormTextField(
                  hint: 'LTS-',
                  controller: _taskIdController,
                  onSaved: (v) => taskId = v ?? '',
                  validator: (v) => v == null || v.isEmpty ? 'Task ID is required' : null,
                  focusNode: _taskIdFocus,
                ),
                _FormLabel('Date-Time'),
                GestureDetector(
                  onTap: () => _pickDateTime(context),
                  child: AbsorbPointer(
                    child: _FormTextField(
                      hint: 'dd-mm-yyyy  HH:MM AM/PM',
                      controller: _dateTimeController,
                      onSaved: (v) => dateTime = v ?? '',
                      focusNode: _dateTimeFocus,
                    ),
                  ),
                ),
                _FormLabel('Company / Contact name', required: true),
                _FormTextField(
                  controller: _companyNameController,
                  onSaved: (v) => companyName = v ?? '',
                  validator: (v) => v == null || v.isEmpty ? 'Company/Contact name is required' : null,
                  focusNode: _companyNameFocus,
                ),
                _FormLabel('Phone'),
                _FormTextField(
                  hint: '(+91) 9876543210',
                  controller: _phoneController,
                  onSaved: (v) => phone = v ?? '',
                  focusNode: _phoneFocus,
                ),
                _FormLabel('Address'),
                Row(
                  children: [
                    Expanded(
                      child: _FormTextField(
                        hint: 'Line',
                        controller: _addressLineController,
                        onSaved: (v) => addressLine = v ?? '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormTextField(
                        hint: 'City',
                        controller: _addressCityController,
                        onSaved: (v) => addressCity = v ?? '',
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
                  controller: _problemDescController,
                  maxLines: 4,
                  onSaved: (v) => problemDescription = v ?? '',
                  focusNode: _problemDescFocus,
                ),
                _FormLabel('Report Description'),
                _FormTextField(
                  controller: _reportDescController,
                  maxLines: 4,
                  onSaved: (v) => reportDescription = v ?? '',
                  focusNode: _reportDescFocus,
                ),
                _FormLabel('Materials Delivered'),
                _FormTextField(
                  controller: _materialsDeliveredController,
                  maxLines: 3,
                  onSaved: (v) => materialsDelivered = v ?? '',
                ),
                _FormLabel('Materials Received'),
                _FormTextField(
                  controller: _materialsReceivedController,
                  maxLines: 3,
                  onSaved: (v) => materialsReceived = v ?? '',
                ),
                _FormLabel('Before (Max 3 Photos)'),
                _PhotoGrid(
                  photos: beforePhotos,
                  onAdd: () => _pickImage(beforePhotos),
                  onRemove: (i) => setState(() => beforePhotos.removeAt(i)),
                ),
                _FormLabel('After (Max 3 Photos)'),
                _PhotoGrid(
                  photos: afterPhotos,
                  onAdd: () => _pickImage(afterPhotos),
                  onRemove: (i) => setState(() => afterPhotos.removeAt(i)),
                ),
                _FormLabel('Customer Name / Designation', required: true),
                _FormTextField(
                  controller: _customerNameController,
                  onSaved: (v) => customerName = v ?? '',
                  validator: (v) => v == null || v.isEmpty ? 'Customer Name is required' : null,
                  focusNode: _customerNameFocus,
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
                        : const Text('Tap to sign', style: TextStyle(color: Colors.grey)),
                  ),
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
      return _taskIdController.text != formEntry!.taskId ||
          _dateTimeController.text != formEntry!.dateTime ||
          _companyNameController.text != formEntry!.companyName ||
          _phoneController.text != formEntry!.phone ||
          _addressLineController.text != formEntry!.addressLine ||
          _addressCityController.text != formEntry!.addressCity ||
          reportedBy != formEntry!.reportedBy ||
          _problemDescController.text != formEntry!.problemDescription ||
          _reportDescController.text != formEntry!.reportDescription ||
          _materialsDeliveredController.text != formEntry!.materialsDelivered ||
          _materialsReceivedController.text != formEntry!.materialsReceived ||
          beforePhotos.map((f) => f.path).toList().toString() != formEntry!.beforePhotoPaths.toString() ||
          afterPhotos.map((f) => f.path).toList().toString() != formEntry!.afterPhotoPaths.toString() ||
          _customerNameController.text != formEntry!.customerName ||
          rating != formEntry!.rating ||
          signaturePreview != formEntry!.signatureImage;
    } else {
      return _taskIdController.text.isNotEmpty ||
          _companyNameController.text.isNotEmpty ||
          _phoneController.text.isNotEmpty ||
          _addressLineController.text.isNotEmpty ||
          _addressCityController.text.isNotEmpty ||
          reportedBy != 'Durai' ||
          _problemDescController.text.isNotEmpty ||
          _reportDescController.text.isNotEmpty ||
          _materialsDeliveredController.text.isNotEmpty ||
          _materialsReceivedController.text.isNotEmpty ||
          beforePhotos.isNotEmpty ||
          afterPhotos.isNotEmpty ||
          _customerNameController.text.isNotEmpty ||
          rating != 4 ||
          signaturePreview != null;
    }
  }
}

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
  final FocusNode? focusNode;
  final TextEditingController? controller;
  const _FormTextField({this.hint, this.maxLines = 1, this.onSaved, this.validator, this.initialValue, this.focusNode, this.controller});

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
        focusNode: focusNode,
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
  final List<File> photos;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  const _PhotoGrid({required this.photos, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
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
            if (i < photos.length) {
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
                        image: FileImage(photos[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
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
            } else if (i == photos.length && photos.length < 3) {
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
            onTap: onAdd,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.black,
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