import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:ui' as ui;
import 'dart:ui' show Offset;
import 'package:http/http.dart' as http;

Future<Uint8List> getImageBytes(String path) async {
  if (path.startsWith('http')) {
    final response = await http.get(Uri.parse(path));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image from $path');
    }
  } else {
    return await File(path).readAsBytes();
  }
}

Future<pw.ImageProvider?> fileImage(String? path) async {
  if (path == null) return null;
  try {
    final bytes = await getImageBytes(path);
    return pw.MemoryImage(bytes);
  } catch (e) {
    return null;
  }
}

// Future<pw.Widget> buildPhotoRow(List<String> photoPaths) async {
//   final imgs = await Future.wait(photoPaths.take(3).map((p) => fileImage(p)));
//   return pw.Row(
//     mainAxisAlignment: pw.MainAxisAlignment.start,
//     children: List.generate(3, (i) {
//       final img = (i < imgs.length) ? imgs[i] : null;
//       return pw.Container(
//         margin: const pw.EdgeInsets.only(right: 8),
//         width: 100,
//         height: 80,
//         decoration: pw.BoxDecoration(
//           border: pw.Border.all(color: PdfColors.grey600),
//         ),
//         child: img != null
//             ? pw.ClipRRect(child: pw.Image(img, fit: pw.BoxFit.cover))
//             : pw.Center(
//                 child: pw.Text('+',
//                     style: pw.TextStyle(
//                         fontSize: 24, color: PdfColors.grey400))),
//       );
//     }),
//   );
// }

// Helper for photo row with more spacing
pw.Widget buildPhotoRowWithSpacing(List<pw.ImageProvider?> images) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: List.generate(3, (i) {
      final img = (i < images.length) ? images[i] : null;
      return pw.Padding(
        padding: pw.EdgeInsets.only(right: i < 2 ? 32 : 0, top: 8, bottom: 8), // Add vertical padding
        child: pw.Container(
          width: 140,
          height: 100,
          decoration: pw.BoxDecoration(
          // border: pw.Border.all(color: PdfColors.grey600, width: 1),
          ),
          child: img != null
              ? pw.ClipRRect(child: pw.Image(img, fit: pw.BoxFit.cover))
              : pw.Center(
                  child: pw.Text('',
                      style: pw.TextStyle(
                          fontSize: 24, color: PdfColors.grey400))),
        ),
      );
    }),
  );
}

Future<Uint8List> generateTaskReportPDF({
  required BuildContext context,
  required String taskId,
  required String dateTime,
  required String companyName,
  required String phone,
  required String addressLine,
  required String addressCity,
  required String reportedBy,
  required String problemDescription,
  required String reportDescription,
  required String materialsDelivered,
  required String materialsReceived,
  required List<String> beforePhotoUrls,
  required List<String> afterPhotoUrls,
  required String customerName,
  required List<Offset?> signaturePoints,
  required Uint8List signatureImage,
  required int rating,
  String formType = 'LTCR',
  // required String formType,
}) async {
  final pdf = pw.Document();

  // final fontData = await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
  // final nunitoFont = pw.Font.ttf(fontData);
  final poppinsFontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
  final poppinsFont = pw.Font.ttf(poppinsFontData);
  final poppinsBoldFontData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
  final poppinsBoldFont = pw.Font.ttf(poppinsBoldFontData);

  // Select header/footer based on formType
  final String headerAsset = formType == 'LCCR'
      ? 'assets/header_blue.png'
      : 'assets/header_green.png';
  final String footerAsset = formType == 'LCCR'
      ? 'assets/footer_blue.png'
      : 'assets/footer_green.png';
  final logoBytes = await rootBundle.load(headerAsset);
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
  final footerBytes = await rootBundle.load(footerAsset);
  final footerImage = pw.MemoryImage(footerBytes.buffer.asUint8List());

  final starFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final starFont = pw.Font.ttf(starFontData);

  print('[PDF] formType: $formType');

  // final phoneIconBytes = await rootBundle.load('assets/phone-icon.png');
  // final phoneIcon = pw.MemoryImage(phoneIconBytes.buffer.asUint8List());

  // final emailIconBytes = await rootBundle.load('assets/email-icon.png');
  // final emailIcon = pw.MemoryImage(emailIconBytes.buffer.asUint8List());

  // final addressIconBytes = await rootBundle.load('assets/address-icon.png');
  // final addressIcon = pw.MemoryImage(addressIconBytes.buffer.asUint8List());

  // Preload images for photo rows
  final beforePhotoImages = await Future.wait(
    beforePhotoUrls.take(3).map((p) => fileImage(p)),
  );
  final afterPhotoImages = await Future.wait(
    afterPhotoUrls.take(3).map((p) => fileImage(p)),
  );

  // --- PAGE 1: Main content ---
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.only(left: 10, right: 10), // Add left margin to entire page
    build: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header image
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 0, right: 0),
            child: pw.Image(
              logo,
              width: PdfPageFormat.a4.width - 20,
              fit: pw.BoxFit.fill,
              height: 90,
            ),
          ),
          pw.SizedBox(height: 12),
          // Main content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'TASK REPORT',
                    style: pw.TextStyle(font: poppinsBoldFont, fontSize: 12, color: PdfColors.grey800),
                  ),
                ),
                pw.SizedBox(height: 6),
                // Customer/Task Details Table
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                  child: pw.Container(
                    margin: pw.EdgeInsets.zero,
                    child: pw.Table(
                      border: pw.TableBorder(
                        top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        left: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        right: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        // bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.7), // was 1.5 or 1
                        horizontalInside: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        verticalInside: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      ),
                      columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(font: poppinsBoldFont, fontSize: 10, color: PdfColors.grey700)),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Center(
                                child: pw.Text('TASK DETAILS', style: pw.TextStyle(font: poppinsBoldFont, fontSize: 10, color: PdfColors.grey700)),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                 pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 16),
                                  child: pw.Text('M/s ${companyName.toUpperCase()}', style: pw.TextStyle(font: poppinsBoldFont, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 16),
                                  child: pw.Text(addressLine, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 16),
                                  child: pw.Text(addressCity, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                ),
                                pw.SizedBox(height: 2), // Add space between address/city and phone
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 16),
                                  child: pw.Text('Tel. : $phone', style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(children: [
                                  pw.Expanded(
                                    flex: 4,
                                    child: pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 16),
                                      child: pw.Text('Task No.', style: pw.TextStyle(font: poppinsFont, fontSize: 10), textAlign: pw.TextAlign.left),
                                    ),
                                  ),
                                  pw.Text(' : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.Expanded(
                                    flex: 6,
                                    child: pw.Text(taskId, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                  ),
                                ]),
                                pw.Row(children: [
                                  pw.Expanded(
                                    flex: 4,
                                    child: pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 16),
                                      child: pw.Text('Date / Time', style: pw.TextStyle(font: poppinsFont, fontSize: 10), textAlign: pw.TextAlign.left),
                                    ),
                                  ),
                                  pw.Text(' : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.Expanded(
                                    flex: 6,
                                    child: pw.Text(dateTime, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                  ),
                                ]),
                                pw.Row(children: [
                                  pw.Expanded(
                                    flex: 4,
                                    child: pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 16),
                                      child: pw.Text('Technician Name', style: pw.TextStyle(font: poppinsFont, fontSize: 10), textAlign: pw.TextAlign.left),
                                    ),
                                  ),
                                  pw.Text(' : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.Expanded(
                                    flex: 6,
                                    child: pw.Text(reportedBy, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                  ),
                                ]),
                                pw.Row(children: [
                                  pw.Expanded(
                                    flex: 4,
                                    child: pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 16),
                                      child: pw.Text('Rating', style: pw.TextStyle(font: poppinsFont, fontSize: 10), textAlign: pw.TextAlign.left),
                                    ),
                                  ),
                                  pw.Text(' : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.Expanded(
                                    flex: 6,
                                    child: pw.Text('★' * rating, style: pw.TextStyle(font: starFont, fontSize: 10)),
                                  ),
                                ]),
                                // Add vertical space after Rating row
                                pw.SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Technical Notes Section Header (full-width)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        right: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                        // No top border
                        // No bottom border (header)
                      ),
                    ),
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'TECHNICAL NOTES',
                      style: pw.TextStyle(
                        font: poppinsBoldFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
                // Technical Notes Table
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                  child: pw.Table(
                    border: pw.TableBorder(
                      top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      left: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      right: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      bottom: pw.BorderSide.none, // Remove bottom border
                      horizontalInside: pw.BorderSide.none, // Remove horizontal lines inside
                    ),
                    columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(0),
                            child: pw.Center(
                              child: pw.Text('PROBLEM DESCRIPTION', style: pw.TextStyle(font: poppinsFont, fontSize: 10, color: PdfColors.grey800)),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(0),
                            child: pw.Center(
                              child: pw.Text('MATERIALS RECEIVED', style: pw.TextStyle(font: poppinsFont, fontSize: 10, color: PdfColors.grey800)),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Container(
                            constraints: pw.BoxConstraints(minHeight: 60),
                            alignment: pw.Alignment.topLeft,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 16),
                              child: pw.Text(problemDescription, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Container(
                            constraints: pw.BoxConstraints(minHeight: 60),
                            alignment: pw.Alignment.topLeft,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 16),
                              child: pw.Text(materialsReceived, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                // Report/Materials Table
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                  child: pw.Table(
                    border: pw.TableBorder(
                      top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      left: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      right: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                      horizontalInside: pw.BorderSide.none, // Remove horizontal lines inside
                    ),
                    columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(0),
                            child: pw.Center(
                              child: pw.Text('REPORT DESCRIPTION', style: pw.TextStyle(font: poppinsFont, fontSize: 10, color: PdfColors.grey800)),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(0),
                            child: pw.Center(
                              child: pw.Text('MATERIALS DELIVERED', style: pw.TextStyle(font: poppinsFont, fontSize: 10, color: PdfColors.grey800)),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Container(
                            constraints: pw.BoxConstraints(minHeight: 60),
                            alignment: pw.Alignment.topLeft,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 16),
                              child: pw.Text(reportDescription, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Container(
                            constraints: pw.BoxConstraints(minHeight: 60),
                            alignment: pw.Alignment.topLeft,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 16),
                              child: pw.Text(materialsDelivered, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                // Photos
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Center(
                          child: pw.Text('FIELD PHOTO : BEFORE', style: pw.TextStyle(font: poppinsBoldFont, fontSize: 10, color: PdfColors.grey700)),
                        ),
                      ),
                      // Unified horizontal line (above photos)
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                          ),
                        ),
                        height: 0.7,
                        width: double.infinity,
                      ),
                      buildPhotoRowWithSpacing(beforePhotoImages),
                      // Unified horizontal line (between before/after)
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                          ),
                        ),
                        height: 0.7,
                        width: double.infinity,
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Center(
                          child: pw.Text('FIELD PHOTO : AFTER', style: pw.TextStyle(font: poppinsBoldFont, fontSize: 10, color: PdfColors.grey700)),
                        ),
                      ),
                      // Unified horizontal line (above after photos)
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                          ),
                        ),
                        height: 0.7,
                        width: double.infinity,
                      ),
                      buildPhotoRowWithSpacing(afterPhotoImages),
                    ],
                  ),
                ),
                // pw.SizedBox(height: 16),
                // Terms and Signature (center split)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Terms and Condition (50%)
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.only(left: 8, bottom: 5),
                        margin: const pw.EdgeInsets.only(left: 12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Terms and Condition :', style: pw.TextStyle(font: poppinsBoldFont, fontSize: 9, color: PdfColors.grey800)),
                            pw.SizedBox(height: 2),
                            pw.Text('1. Repair duration will be subjected to availability of Spares', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                            pw.Text('2. Delivery of Repaired Materials will be against Payment', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                            pw.Text('3. Diagnosis Charges will be applicable', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                            pw.Text('4. This sheet should be produced at the time of delivery', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                    // Right: Signature section (50%)
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        margin: const pw.EdgeInsets.only(right: 12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4, left: 8, right: 8, bottom: 4),
                              child: pw.Center(
                                child: pw.Text(
                                  'CUSTOMER SIGNATURE',
                                  style: pw.TextStyle(font: poppinsBoldFont, fontSize: 10, color: PdfColors.grey600),
                                ),
                              ),
                            ),
                            // Signature section horizontal line
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                                ),
                              ),
                              height: 0.7,
                              width: double.infinity,
                            ),
                            pw.Container(
                              height: 47, // Slightly taller for more white space
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.end, // Align to bottom
                                children: [
                                  pw.Expanded(
                                    child: pw.Container(
                                      alignment: pw.Alignment.center,
                                      padding: const pw.EdgeInsets.only(bottom: 0), // Remove left margin so underline touches border
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border(
                                          // right: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                                        ),
                                      ),
                                      height: 47, // Match signature block height
                                      child: pw.Center(
                                        child: pw.Column(
                                          mainAxisSize: pw.MainAxisSize.min,
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Padding(
                                              padding: const pw.EdgeInsets.only(left: 8, bottom: 6),
                                              child: pw.Text('SIGNED BY', style: pw.TextStyle(font: poppinsBoldFont, fontSize: 10, color: PdfColors.grey600)),
                                            ),
                                            pw.Container(
                                              decoration: pw.BoxDecoration(
                                                border: pw.Border(
                                                  top: pw.BorderSide(color: PdfColors.grey600, width: 0.7),
                                                ),
                                              ),
                                              height: 0.7,
                                              width: double.infinity,
                                            ),
                                            pw.Padding(
                                              padding: const pw.EdgeInsets.only(left: 8, top: 4),
                                              child: pw.Text(customerName.toUpperCase(), style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Signature section vertical divider
                                  pw.Container(
                                    width: 0.7,
                                    height: double.infinity,
                                    color: PdfColors.grey600,
                                  ),
                                  pw.Expanded(
                                    child: pw.Container(
                                      alignment: pw.Alignment.center,
                                      child: signatureImage.isNotEmpty
                                          ? pw.Image(pw.MemoryImage(signatureImage), height: 40, width: 80, fit: pw.BoxFit.fill)
                                          : pw.SizedBox(height: 40, width: 80),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 0), // Add bottom margin before footer
              ],
            ),
          ),
          // Footer image at the very bottom
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Image(
              footerImage,
              width: PdfPageFormat.a4.width - 20,
              fit: pw.BoxFit.fitWidth,
              height: 40,
            ),
          ),
        ],
      );
    },
  ));

  // --- PAGE 2: FIELD PHOTO : BEFORE (3 vertical sections, each with a centered square image) ---
  final nonNullBeforeImages = beforePhotoImages.where((img) => img != null).toList();
  if (nonNullBeforeImages.isNotEmpty) {
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: List.generate(3, (i) {
            if (i >= nonNullBeforeImages.length) {
              return pw.Expanded(child: pw.Container());
            }
            return pw.Expanded(
              child: pw.Center(
                child: pw.Container(
                  width: 250,
                  height: 250,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
                  ),
                  child: pw.Image(nonNullBeforeImages[i]!, fit: pw.BoxFit.cover),
                ),
              ),
            );
          }),
        );
      },
    ));
  }

  // --- PAGE 3: FIELD PHOTO : AFTER (3 vertical sections, each with a centered square image) ---
  final nonNullAfterImages = afterPhotoImages.where((img) => img != null).toList();
  if (nonNullAfterImages.isNotEmpty) {
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: List.generate(3, (i) {
            if (i >= nonNullAfterImages.length) {
              return pw.Expanded(child: pw.Container());
            }
            return pw.Expanded(
              child: pw.Center(
                child: pw.Container(
                  width: 250,
                  height: 250,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
                  ),
                  child: pw.Image(nonNullAfterImages[i]!, fit: pw.BoxFit.cover),
                ),
              ),
            );
          }),
        );
      },
    ));
  }

  return pdf.save();
}

/// Converts signature points to a PNG image (Uint8List)
Future<Uint8List> convertSignatureToImage(List<Offset?> points, {int width = 300, int height = 80, double strokeWidth = 3.0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  final paint = ui.Paint()
    ..color = const ui.Color(0xFF000000)
    ..strokeWidth = strokeWidth
    ..strokeCap = ui.StrokeCap.round;

  for (int i = 0; i < points.length - 1; i++) {
    if (points[i] != null && points[i + 1] != null) {
      canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

