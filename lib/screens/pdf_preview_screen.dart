import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/permission_manager.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List? pdfBytes;
  final String? pdfPath;
  final String? taskId;
  final String? companyName;
  const PdfPreviewScreen({super.key, this.pdfBytes, this.pdfPath, this.taskId, this.companyName});

  Future<Uint8List> _loadBytes() async {
    if (pdfBytes != null) return pdfBytes!;
    if (pdfPath != null) return await File(pdfPath!).readAsBytes();
    throw Exception('No PDF data provided');
  }

  Future<String> getLenientDownloadPath(String filename) async {
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download/Lenient');
      if (!(await downloadsDir.exists())) {
        await downloadsDir.create(recursive: true);
      }
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    }
    if (downloadsDir == null) throw Exception('Cannot access storage');
    return '${downloadsDir.path}/$filename';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.5,
        title: const Text('Preview PDF', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Uint8List>(
        future: _loadBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return PdfPreview(
            build: (format) async => snapshot.data!,
            initialPageFormat: PdfPageFormat.a4,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            pdfFileName: '${taskId ?? 'document'}_${companyName ?? ''}.pdf',
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7ED957),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (!await PermissionManager.ensureStoragePermission(context)) return;
                  try {
                    final bytes = await _loadBytes();
                    String filename = '${taskId ?? 'document'}_${companyName ?? ''}.pdf';
                    final path = await getLenientDownloadPath(filename);
                    final file = File(path);
                    await file.writeAsBytes(bytes);
                    // Trigger media scan on Android
                    if (Platform.isAndroid) {
                      await MediaScanner.loadMedia(path: file.path);
                    }
                    if (context.mounted) {
                      LenientSnackbar.showSuccess(context, 'PDF saved successfully');
                      // Return to Forms screen after download
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      LenientSnackbar.showError(context, 'Failed to save PDF: $e');
                    }
                  }
                },
                child: const Text('Download PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 