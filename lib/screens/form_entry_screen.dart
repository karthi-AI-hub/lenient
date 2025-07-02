import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/lenient_app_bar.dart';
import '../utils/pdf_generator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' show Offset;
import 'dart:typed_data';

class FormEntryScreen extends StatefulWidget {
  const FormEntryScreen({super.key});

  @override
  State<FormEntryScreen> createState() => _FormEntryScreenState();
}

class _FormEntryScreenState extends State<FormEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  // Form fields
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
  // Signature pad state
  List<Offset?> signaturePoints = [];
  // Add focus nodes for required fields
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

  @override
  void initState() {
    super.initState();
    // Remove dateTime initialization from here
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
    }
  }

  void _saveForm() {
    // For demo: just print to console or store in memory
    bool valid = _formKey.currentState!.validate();
    if (!valid) {
      _focusFirstInvalidField();
      return;
    }
    debugPrint('Form saved: $taskId, $dateTime, $companyName, ...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Form saved for further process.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF7ED957),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  void _focusFirstInvalidField() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_taskIdFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_taskIdFocus);
      } else if (_dateTimeFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_dateTimeFocus);
      } else if (_companyNameFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_companyNameFocus);
      } else if (_phoneFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_phoneFocus);
      } else if (_problemDescFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_problemDescFocus);
      } else if (_reportDescFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_reportDescFocus);
      } else if (_customerNameFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_customerNameFocus);
      }
    });
  }

  Future<void> _finalizeForm() async {
    bool valid = _formKey.currentState!.validate();
    if (!valid) {
      _focusFirstInvalidField();
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Final Submit', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to generate the PDF?\n\nYou won't be able to edit the form after this. Please review all details before proceeding.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7ED957),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Generate PDF'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _formKey.currentState!.save();
    if (signaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please capture customer signature', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF7ED957),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
      return;
    }
    final signatureImage = signaturePreview ?? await convertSignatureToImage(signaturePoints, width: 300, height: 80);
    await generateTaskReportPDF(
      context: context,
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
      beforePhotos: beforePhotos,
      afterPhotos: afterPhotos,
      customerName: customerName,
      signaturePoints: signaturePoints,
      signatureImage: signatureImage,
      rating: rating,
    );
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setStateDialog(() {
                                tempPoints = [];
                                tempImage = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                signaturePoints = List.from(tempPoints);
                                signaturePreview = tempImage;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('Capture'),
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
    return Scaffold(
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
                      onPressed: () => Navigator.of(context).pop(),
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
                onSaved: (v) => taskId = v ?? '',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Task ID is required';
                  if (!v.startsWith('LTS-')) return 'Task ID must start with LTS-';
                  return null;
                },
                focusNode: _taskIdFocus,
              ),
              _FormLabel('Date-Time', required: true),
              GestureDetector(
                onTap: () => _pickDateTime(context),
                child: AbsorbPointer(
                  child: _FormTextField(
                    hint: 'dd-mm-yyyy  HH:MM AM/PM',
                    controller: _dateTimeController,
                    onSaved: (v) => dateTime = v ?? '',
                    validator: (v) => (_dateTimeController.text.isEmpty) ? 'Date-Time is required' : null,
                    focusNode: _dateTimeFocus,
                  ),
                ),
              ),
              _FormLabel('Company / Contact name', required: true),
              _FormTextField(
                onSaved: (v) => companyName = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Company/Contact name is required' : null,
                focusNode: _companyNameFocus,
              ),
              _FormLabel('Phone', required: true),
              _FormTextField(
                hint: '(+91) 234-567-89',
                onSaved: (v) => phone = v ?? '',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone is required';
                  final phoneReg = RegExp(r'^(\+\d{1,3}[- ]?)?\d{10,}$');
                  if (!phoneReg.hasMatch(v)) return 'Enter a valid phone number';
                  return null;
                },
                focusNode: _phoneFocus,
              ),
              _FormLabel('Address'),
              Row(
                children: [
                  Expanded(
                    child: _FormTextField(
                      hint: 'Line',
                      onSaved: (v) => addressLine = v ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormTextField(
                      hint: 'City',
                      onSaved: (v) => addressCity = v ?? '',
                    ),
                  ),
                ],
              ),
              _FormLabel('Reported By', required: true),
              _FormDropdown(
                items: const ['Durai', 'Elango', 'Lenin', 'Mani', 'Mohan ID', 'Mohan', 'Nandhini ', 'Priya', 'Seeni', 'Other'],
                value: reportedBy,
                onChanged: (v) => setState(() => reportedBy = v ?? 'Durai'),
              ),
              _FormLabel('Problem Description', required: true),
              _FormTextField(
                maxLines: 4,
                onSaved: (v) => problemDescription = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Problem Description is required' : null,
                focusNode: _problemDescFocus,
              ),
              _FormLabel('Report Description', required: true),
              _FormTextField(
                maxLines: 4,
                onSaved: (v) => reportDescription = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Report Description is required' : null,
                focusNode: _reportDescFocus,
              ),
              _FormLabel('Materials Delivered'),
              _FormTextField(
                maxLines: 3,
                onSaved: (v) => materialsDelivered = v ?? '',
              ),
              _FormLabel('Materials Received'),
              _FormTextField(
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
                onSaved: (v) => customerName = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Customer Name is required' : null,
                focusNode: _customerNameFocus,
              ),
              _FormLabel('Customer Signature (only Customers)', required: true),
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveForm,
                      child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED957),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _finalizeForm,
                      child: const Text('Final Submit', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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