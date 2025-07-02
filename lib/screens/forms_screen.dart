import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/form_entry.dart';
import 'form_entry_screen.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_dialog.dart';
import 'pdf_preview_screen.dart';
import '../utils/pdf_generator.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:printing/printing.dart';

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

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
            child: ValueListenableBuilder(
              valueListenable: Hive.box<FormEntry>('forms').listenable(),
              builder: (context, Box<FormEntry> box, _) {
                final allForms = box.values.toList()
                  ..sort((a, b) => b.key.compareTo(a.key));
                final filtered = _search.isEmpty
                    ? allForms
                    : allForms.where((f) {
                        final q = _search.toLowerCase();
                        return f.taskId.toLowerCase().contains(q) ||
                          f.companyName.toLowerCase().contains(q) ||
                          f.phone.toLowerCase().contains(q) ||
                          f.problemDescription.toLowerCase().contains(q) ||
                          f.reportDescription.toLowerCase().contains(q) ||
                          f.materialsDelivered.toLowerCase().contains(q) ||
                          f.materialsReceived.toLowerCase().contains(q) ||
                          f.customerName.toLowerCase().contains(q) ||
                          f.addressLine.toLowerCase().contains(q) ||
                          f.addressCity.toLowerCase().contains(q);
                      }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Text('No forms found.\nCreate a new form from Home.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey[600])),
                    ),
                  );
                }
                return ListView.separated(
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
                          form.dateTime,
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
                                final pdfBytes = await generateTaskReportPDF(
                                  context: context,
                                  taskId: form.taskId,
                                  dateTime: form.dateTime,
                                  companyName: form.companyName,
                                  phone: form.phone,
                                  addressLine: form.addressLine,
                                  addressCity: form.addressCity,
                                  reportedBy: form.reportedBy,
                                  problemDescription: form.problemDescription,
                                  reportDescription: form.reportDescription,
                                  materialsDelivered: form.materialsDelivered,
                                  materialsReceived: form.materialsReceived,
                                  beforePhotos: form.beforePhotoPaths.map((p) => File(p)).toList(),
                                  afterPhotos: form.afterPhotoPaths.map((p) => File(p)).toList(),
                                  customerName: form.customerName,
                                  signaturePoints: [],
                                  signatureImage: form.signatureImage ?? Uint8List.fromList([]),
                                  rating: form.rating,
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
                                  await Printing.sharePdf(bytes: pdfBytes, filename: '${form.taskId}_${form.companyName}.pdf');
                                }
                              } catch (e) {
                                Navigator.of(context, rootNavigator: true).pop();
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
                                LenientSnackbar.showError(context, 'Form deleted');
                                await Hive.box<FormEntry>('forms').delete(form.id);
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
                            MaterialPageRoute(builder: (context) => FormEntryScreen(formId: form.id)),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 