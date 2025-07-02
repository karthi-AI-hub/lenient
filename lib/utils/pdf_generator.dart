// Full complete PDF generation with all sections for Task Report
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
  required List<File> beforePhotos,
  required List<File> afterPhotos,
  required String customerName,
  required List<Offset?> signaturePoints,
  required Uint8List signatureImage,
  required int rating,
}) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
  final nunitoFont = pw.Font.ttf(fontData);
  final poppinsFontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
  final poppinsFont = pw.Font.ttf(poppinsFontData);

  final logoBytes = await rootBundle.load('assets/logo.png');
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final starFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final starFont = pw.Font.ttf(starFontData);

  final phoneIconBytes = await rootBundle.load('assets/phone-icon.png');
  final phoneIcon = pw.MemoryImage(phoneIconBytes.buffer.asUint8List());

  final emailIconBytes = await rootBundle.load('assets/email-icon.png');
  final emailIcon = pw.MemoryImage(emailIconBytes.buffer.asUint8List());

  final addressIconBytes = await rootBundle.load('assets/address-icon.png');
  final addressIcon = pw.MemoryImage(addressIconBytes.buffer.asUint8List());

  pw.ImageProvider? fileImage(File? f) =>
      (f != null) ? pw.MemoryImage(f.readAsBytesSync()) : null;



  pw.Widget buildPhotoRow(List<File> photos) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: List.generate(3, (i) {
        final img = (i < photos.length) ? fileImage(photos[i]) : null;
        return pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          width: 100,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: img != null
              ? pw.ClipRRect(child: pw.Image(img, fit: pw.BoxFit.cover))
              : pw.Center(
                  child: pw.Text('+',
                      style: pw.TextStyle(
                          fontSize: 24, color: PdfColors.grey400))),
        );
      }),
    );
  }

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header with logo and green bar
          pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logo, width: 120, height: 48),
                pw.Spacer(),
              ],
            ),
          ),
          pw.Container(
            color: PdfColor.fromHex('#7ED957'),
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 24),
            child: pw.Text(
              'COMPUTER | LAPTOP | PRINTER | NETWORKING | TALLY | BUSY | ONSITE SERVICE',
              style: pw.TextStyle(font: poppinsFont, fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          // Title
          pw.Center(
            child: pw.Text('TASK REPORT', style: pw.TextStyle(font: poppinsFont, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          // Customer/Task Details Table
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('TASK DETAILS', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Mr / Ms / Ms. ${companyName.toUpperCase()}', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(addressLine, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                        pw.Text(addressCity, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                        pw.Text('Tel. : $phone', style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(children: [
                          pw.Text('Task No. : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text(taskId, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                        ]),
                        pw.Row(children: [
                          pw.Text('Date / Time : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text(dateTime, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                        ]),
                        pw.Row(children: [
                          pw.Text('Technician Name : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text(reportedBy, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                        ]),
                        pw.Row(children: [
                          pw.Text('Rating : ', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('★' * rating, style: pw.TextStyle(font: starFont, fontSize: 10)),
                        ]),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
          // Technical Notes Table
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('PROBLEM DESCRIPTION', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('MATERIALS RECEIVED', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(problemDescription, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(materialsReceived, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                  ),
                ]),
              ],
            ),
          ),
          // Report/Materials Table
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('REPORT DESCRIPTION', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('MATERIALS DELIVERED', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(reportDescription, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(materialsDelivered, style: pw.TextStyle(font: poppinsFont, fontSize: 10)),
                  ),
                ]),
              ],
            ),
          ),
          // Photos
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: pw.Text('FIELD PHOTO : BEFORE', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: buildPhotoRow(beforePhotos),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: pw.Text('FIELD PHOTO : AFTER', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: buildPhotoRow(afterPhotos),
          ),
          // Terms and Signature
          pw.Spacer(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(left: 12, bottom: 8, top: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Terms and Condition :', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('1. Repair duration will be subjected to availability of Spares', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                      pw.Text('2. Delivery of Repaired Materials will be against Payment', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                      pw.Text('3. Diagnosis Charges will be applicable', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                      pw.Text('4. This sheet should be produced at the time of delivery', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 12, bottom: 8, top: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER SIGNATURE', style: pw.TextStyle(font: poppinsFont, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 100,
                            height: 40,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300),
                            ),
                            child: signatureImage.isNotEmpty
                                ? pw.Image(pw.MemoryImage(signatureImage))
                                : pw.SizedBox(),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('SIGNED BY', style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                              pw.Text(customerName, style: pw.TextStyle(font: poppinsFont, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Footer
          pw.Container(
            color: PdfColor.fromHex('#7ED957'),
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  pw.Image(phoneIcon, width: 14, height: 14),
                  pw.SizedBox(width: 4),
                  pw.Text('04288 242022\n99566 22022', style: pw.TextStyle(font: poppinsFont, fontSize: 9, color: PdfColors.white)),
                ]),
                pw.Row(children: [
                  pw.Image(emailIcon, width: 14, height: 14),
                  pw.SizedBox(width: 4),
                  pw.Text('lenienttechnologies@gmail.com', style: pw.TextStyle(font: poppinsFont, fontSize: 9, color: PdfColors.white)),
                ]),
                pw.Row(children: [
                  pw.Image(addressIcon, width: 14, height: 14),
                  pw.SizedBox(width: 4),
                  pw.Text('57, Sri Guru Towers, Pallipalayam, Erode - 638006', style: pw.TextStyle(font: poppinsFont, fontSize: 9, color: PdfColors.white)),
                ]),
              ],
            ),
          ),
        ],
      );
    },
  ));

  return pdf.save();
}

Future<Uint8List> generateTaskReportPDFBytes({
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
  required List<File> beforePhotos,
  required List<File> afterPhotos,
  required String customerName,
  required List<Offset?> signaturePoints,
  required Uint8List signatureImage,
  required int rating,
}) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
  final nunitoFont = pw.Font.ttf(fontData);

  final templateBytes = await rootBundle.load('assets/template_green.jpg');
  final template = pw.MemoryImage(templateBytes.buffer.asUint8List());

  final starFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final starFont = pw.Font.ttf(starFontData);

  final phoneIconBytes = await rootBundle.load('assets/phone-icon.png');
  final phoneIcon = pw.MemoryImage(phoneIconBytes.buffer.asUint8List());

  final emailIconBytes = await rootBundle.load('assets/email-icon.png');
  final emailIcon = pw.MemoryImage(emailIconBytes.buffer.asUint8List());

  final addressIconBytes = await rootBundle.load('assets/address-icon.png');
  final addressIcon = pw.MemoryImage(addressIconBytes.buffer.asUint8List());

  pw.ImageProvider? fileImage(File? f) =>
      (f != null) ? pw.MemoryImage(f.readAsBytesSync()) : null;


  pw.Widget buildPhotoRow(List<File> photos) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: List.generate(3, (i) {
        final img = (i < photos.length) ? fileImage(photos[i]) : null;
        return pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          width: 100,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: img != null
              ? pw.ClipRRect(child: pw.Image(img, fit: pw.BoxFit.cover))
              : pw.Center(
                  child: pw.Text('+',
                      style: pw.TextStyle(
                          fontSize: 24, color: PdfColors.grey400))),
        );
      }),
    );
  }

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (context) {
      return pw.Stack(children: [
        pw.Positioned.fill(child: pw.Image(template, fit: pw.BoxFit.cover)),
        pw.Positioned(
          top: 130,
          left: 30,
          right: 30,
          bottom: 40,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TASK REPORT',
                  style: pw.TextStyle(
                      font: nunitoFont,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16)),
              pw.SizedBox(height: 10),
              _buildDetailsTable(customerName, addressLine, addressCity,
                  phone, taskId, dateTime, reportedBy, rating, nunitoFont, starFont),
              pw.SizedBox(height: 10),
              _sectionBlock('TECHNICAL NOTES - PROBLEM DESCRIPTION', problemDescription, nunitoFont),
              _sectionBlock('MATERIALS RECEIVED', materialsReceived, nunitoFont),
              _sectionBlock('REPORT DESCRIPTION', reportDescription, nunitoFont),
              _sectionBlock('MATERIALS DELIVERED', materialsDelivered, nunitoFont),
              pw.SizedBox(height: 10),
              pw.Text('FIELD PHOTO : BEFORE', style: _photoHeader(nunitoFont)),
              pw.SizedBox(height: 6),
              buildPhotoRow(beforePhotos),
              pw.SizedBox(height: 10),
              pw.Text('FIELD PHOTO : AFTER', style: _photoHeader(nunitoFont)),
              pw.SizedBox(height: 6),
              buildPhotoRow(afterPhotos),
              pw.SizedBox(height: 12),
              _termsBlock(nunitoFont),
              pw.SizedBox(height: 12),
              _signatureSection(customerName, reportedBy, signatureImage, nunitoFont),
            ],
          ),
        )
      ]);
    },
  ));

  return pdf.save();
}

pw.Widget _buildDetailsTable(String name, String address1, String address2, String phone,
    String taskId, String dateTime, String tech, int rating, pw.Font font, pw.Font starFont) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cellHeader('CUSTOMER DETAILS', font),
          _cellHeader('TASK DETAILS', font),
        ],
      ),
      pw.TableRow(children: [
        _td(pw.Text('Mr/Mrs/Ms $name\n$address1, $address2', style: _tdStyle(font))),
        _td(_twoLine('Task No.', taskId, font)),
      ]),
      pw.TableRow(children: [
        _td(pw.Text('Tel.: $phone', style: _tdStyle(font))),
        _td(_twoLine('Date / Time', dateTime, font)),
      ]),
      pw.TableRow(children: [
        pw.SizedBox(),
        _td(_twoLine('Technician Name', tech, font)),
      ]),
      pw.TableRow(children: [
        pw.SizedBox(),
        _td(_twoLine('Rating', '★' * rating, starFont)),
      ])
    ],
  );
}

pw.Widget _sectionBlock(String title, String body, pw.Font font) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: PdfColors.grey300,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: font, fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300)),
          padding: const pw.EdgeInsets.all(6),
          child:
              pw.Text(body, style: pw.TextStyle(font: font, fontSize: 10)),
        ),
        pw.SizedBox(height: 6),
      ],
    );

pw.Widget _termsBlock(pw.Font font) => pw.Container(
      decoration:
          pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _term('1. Repair duration will be subject to availability of spares', font),
        _term('2. Delivery of repaired materials will be against payment', font),
        _term('3. Diagnostic charges will be applicable', font),
        _term('4. This sheet should be produced at the time of delivery', font),
      ]),
    );

pw.Widget _signatureSection(
    String name, String tech, Uint8List signImg, pw.Font font) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('CUSTOMER SIGNATURE', style: _signatureLabel(font)),
        pw.SizedBox(height: 40, width: 150,
            child: pw.Image(pw.MemoryImage(signImg))),
        pw.Text(name, style: pw.TextStyle(font: font, fontSize: 10)),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('SIGNED BY', style: _signatureLabel(font)),
        pw.SizedBox(height: 40, width: 150),
        pw.Text(tech, style: pw.TextStyle(font: font, fontSize: 10)),
      ]),
    ],
  );
}

pw.TextStyle _tdStyle(pw.Font font) =>
    pw.TextStyle(font: font, fontSize: 10);
pw.Widget _td(pw.Widget child) =>
    pw.Padding(padding: const pw.EdgeInsets.all(6), child: child);
pw.Widget _twoLine(String label, String value, pw.Font font, {bool isBold = false}) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style:
                pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600, fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
pw.Widget _cellHeader(String text, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
pw.TextStyle _photoHeader(pw.Font font) =>
    pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold);
pw.TextStyle _signatureLabel(pw.Font font) =>
    pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);
pw.Widget _term(String text, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9)),
    );

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
