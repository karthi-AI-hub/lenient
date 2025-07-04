import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/form_model.dart';
import 'form_entry_screen.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_dialog.dart';
import 'pdf_preview_screen.dart';
import '../utils/pdf_generator.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../services/supabase_service.dart';
import '../utils/lenient_refresh_indicator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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

Future<Uint8List> downloadSignature(String? url) async {
  if (url == null || url.isEmpty) return Uint8List(0);
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  return Uint8List(0);
}

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FB),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              elevation: 1.5,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'Search forms...',
                  hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7ED957)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<FormModel>>(
              key: ValueKey(_refreshKey),
              stream: SupabaseService.streamForms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Something went wrong. Please try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Retry', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7ED957),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() {
                                _refreshKey++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Text('No forms found.\nCreate a new form from Home.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey[600])),
                    ),
                  );
                } else {
                  final allForms = snapshot.data!;
                  final filtered = _search.isEmpty
                      ? allForms
                      : allForms.where((f) {
                          final q = _search.toLowerCase();
                          return f.taskId.toLowerCase().contains(q) ||
                            (f.companyName?.toLowerCase().contains(q) ?? false) ||
                            (f.phone?.toLowerCase().contains(q) ?? false) ||
                            (f.problemDescription?.toLowerCase().contains(q) ?? false) ||
                            (f.reportDescription?.toLowerCase().contains(q) ?? false) ||
                            (f.materialsDelivered?.toLowerCase().contains(q) ?? false) ||
                            (f.materialsReceived?.toLowerCase().contains(q) ?? false) ||
                            (f.addressLine?.toLowerCase().contains(q) ?? false) ||
                            (f.addressCity?.toLowerCase().contains(q) ?? false);
                        }).toList();
                  return LenientRefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _refreshKey++;
                      });
                    },
                    successMessage: 'Data refreshed',
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final form = filtered[i];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1.5,
                          color: Colors.white,
                          shadowColor: const Color(0xFF7ED957).withOpacity(0.08),
                          child: ListTile(
                            title: Text(
                              '${form.taskId}_${form.companyName}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: const Color(0xFF222222),
                                    fontFamily: 'Poppins',
                                  ),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(
                                form.createdAt.toUtc().add(const Duration(hours: 5, minutes: 30))
                              ),
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Nunito'),
                            ),
                            trailing: PopupMenuButton<String>(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              icon: const Icon(Icons.more_vert, color: Color(0xFF7ED957)),
                              onSelected: (value) async {
                                if (value == 'preview' || value == 'share') {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    debugPrint('Generating PDF for form:');
                                    debugPrint('taskId: \\${form.taskId}');
                                    debugPrint('dateTime: \\${form.createdAt.toIso8601String()}');
                                    debugPrint('companyName: \\${form.companyName}');
                                    debugPrint('phone: \\${form.phone}');
                                    debugPrint('addressLine: \\${form.addressLine}');
                                    debugPrint('addressCity: \\${form.addressCity}');
                                    debugPrint('reportedBy: \\${form.reportedBy}');
                                    debugPrint('problemDescription: \\${form.problemDescription}');
                                    debugPrint('reportDescription: \\${form.reportDescription}');
                                    debugPrint('materialsDelivered: \\${form.materialsDelivered}');
                                    debugPrint('materialsReceived: \\${form.materialsReceived}');
                                    debugPrint('beforePhotos: \\${(form.beforePhotoUrls ?? []).toString()}');
                                    debugPrint('afterPhotos: \\${(form.afterPhotoUrls ?? []).toString()}');
                                    debugPrint('customerName: ');
                                    debugPrint('signaturePoints: []');
                                    debugPrint('signatureImage: empty');
                                    debugPrint('rating: \\${form.rating}');
                                    final pdfBytes = await generateTaskReportPDF(
                                      context: context,
                                      taskId: form.taskId,
                                      dateTime: form.createdAt.toIso8601String(),
                                      companyName: form.companyName ?? '',
                                      phone: form.phone ?? '',
                                      addressLine: form.addressLine ?? '',
                                      addressCity: form.addressCity ?? '',
                                      reportedBy: form.reportedBy ?? '',
                                      problemDescription: form.problemDescription ?? '',
                                      reportDescription: form.reportDescription ?? '',
                                      materialsDelivered: form.materialsDelivered ?? '',
                                      materialsReceived: form.materialsReceived ?? '',
                                      beforePhotoUrls: form.beforePhotoUrls ?? [],
                                      afterPhotoUrls: form.afterPhotoUrls ?? [],
                                      customerName: form.customeName ?? '',
                                      signaturePoints: [],
                                      signatureImage: await downloadSignature(form.signatureUrl),
                                      rating: form.rating ?? 0,
                                    );
                                    Navigator.of(context, rootNavigator: true).pop();
                                    if (value == 'preview') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfPreviewScreen(
                                            pdfBytes: pdfBytes,
                                            taskId: form.taskId,
                                            companyName: form.companyName,
                                          ),
                                        ),
                                      );
                                    } else if (value == 'share') {
                                      await Printing.sharePdf(bytes: pdfBytes, filename: '\\${form.taskId}_\\${form.companyName}.pdf');
                                    }
                                  } catch (e, st) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                    debugPrint('Error generating PDF: $e');
                                    debugPrint('StackTrace: $st');
                                    LenientSnackbar.showError(context, 'Failed to generate PDF: $e');
                                  }
                                } else if (value == 'delete') {
                                  final confirm = await LenientDialog.showConfirm(
                                    context,
                                    title: 'Delete Form',
                                    content: 'Are you sure you want to delete this form?',
                                    confirmText: 'Delete',
                                    cancelText: 'Cancel',
                                    confirmColor: Colors.red,
                                  );
                                  if (confirm == true) {
                                    try {
                                      await SupabaseService.deleteForm(
                                        form.id,
                                        [...?form.beforePhotoUrls, ...?form.afterPhotoUrls],
                                        form.signatureUrl,
                                        taskId: form.taskId,
                                      );
                                      LenientSnackbar.showSuccess(context, 'Form deleted');
                                      setState(() { _refreshKey++; });
                                    } catch (e) {
                                      LenientSnackbar.showError(context, getFriendlyErrorMessage(e));
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'preview',
                                  child: ListTile(
                                    leading: Icon(Icons.picture_as_pdf, color: Color(0xFF7ED957)),
                                    title: Text('Preview / Download PDF', style: TextStyle(fontFamily: 'Poppins')),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: ListTile(
                                    leading: Icon(Icons.share, color: Color(0xFF7ED957)),
                                    title: Text('Share PDF', style: TextStyle(fontFamily: 'Poppins')),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete, color: Colors.red),
                                    title: Text('Delete', style: TextStyle(fontFamily: 'Poppins')),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FormEntryScreen(formId: form.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
} 