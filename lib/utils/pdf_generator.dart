import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:ui' show Offset;
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

/// Top‑level helper
Future<void> generateTaskReportPDF({
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
  required Uint8List signatureImage, // <‑‑ created with convertSignatureToImage()
  required int rating,


}) async {
  final pdf = pw.Document(deflate: zlib.encode);

  // Helper converts dart:io File -> MemoryImage
  pw.ImageProvider? fileImage(File? f) =>
      (f != null) ? pw.MemoryImage(f.readAsBytesSync()) : null;

  // Load Nunito-Regular font from assets for Unicode support
  final fontData = await rootBundle.load('assets/fonts/Nunito-Regular.ttf');
  final nunitoFont = pw.Font.ttf(fontData);

  // Build BEFORE/AFTER photo widgets (max 3 each)
  pw.Widget buildPhotoRow(List<File> photos) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: List.generate(3, (i) {
        final img = (i < photos.length) ? fileImage(photos[i]) : null;
        return pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: img != null
              ? pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(img, fit: pw.BoxFit.cover))
              : pw.Center(
                  child: pw.Text('+',
                      style: pw.TextStyle(
                          fontSize: 24, color: PdfColors.grey400))),
        );
      }),
    );
  }

  // Main page
  final templateBytes = await rootBundle.load('assets/template.jpg');
  final template = pw.MemoryImage(templateBytes.buffer.asUint8List());
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            pw.Positioned.fill(child: pw.Image(template, fit: pw.BoxFit.cover)),
            pw.Positioned(
              left: 0,
              right: 0,
              top: 100,
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('TASK REPORT',
                        style: pw.TextStyle(
                            font: nunitoFont,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 12),
                    // ---------- CUSTOMER & TASK TABLE ----------
                    pw.Table(
                      border: const pw.TableBorder(),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('CUSTOMER DETAILS',
                                    style: _tableHeader(nunitoFont))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('TASK DETAILS', style: _tableHeader(nunitoFont))),
                          ],
                        ),
                        pw.TableRow(children: [
                          _td(pw.Text(companyName, style: pw.TextStyle(font: nunitoFont))),
                          _td(_twoLine('Task No.', taskId, nunitoFont)),
                        ]),
                        pw.TableRow(children: [
                          _td(pw.Text('$addressLine, $addressCity', style: pw.TextStyle(font: nunitoFont))),
                          _td(_twoLine('Date / Time', dateTime, nunitoFont)),
                        ]),
                        pw.TableRow(children: [
                          _td(pw.Text('Tel.: $phone', style: pw.TextStyle(font: nunitoFont))),
                          _td(_twoLine('Technician Name', reportedBy, nunitoFont)),
                        ]),
                        pw.TableRow(children: [
                          _td(pw.SizedBox()), // empty cell
                          _td(_twoLine('Rating', '⭐' * rating, nunitoFont)),
                        ]),
                      ],
                    ),
                    pw.SizedBox(height: 14),
                    // ---------- PROBLEM / MATERIALS / REPORT ----------
                    _sectionHeader('PROBLEM DESCRIPTION', nunitoFont),
                    _sectionBody(problemDescription, nunitoFont),
                    _sectionHeader('MATERIALS RECEIVED', nunitoFont),
                    _sectionBody(materialsReceived, nunitoFont),
                    _sectionHeader('REPORT DESCRIPTION', nunitoFont),
                    _sectionBody(reportDescription, nunitoFont),
                    _sectionHeader('MATERIALS DELIVERED', nunitoFont),
                    _sectionBody(materialsDelivered, nunitoFont),
                    pw.SizedBox(height: 12),
                    // ---------- BEFORE / AFTER PHOTOS ----------
                    pw.Row(children: [
                      pw.Text('FIELD PHOTO : BEFORE', style: _photoHeader(nunitoFont)),
                      pw.SizedBox(width: 10),
                      buildPhotoRow(beforePhotos),
                    ]),
                    pw.SizedBox(height: 6),
                    pw.Row(children: [
                      pw.Text('FIELD PHOTO : AFTER', style: _photoHeader(nunitoFont)),
                      pw.SizedBox(width: 22),
                      buildPhotoRow(afterPhotos),
                    ]),
                    pw.SizedBox(height: 14),
                    // ---------- TERMS ----------
                    pw.Container(
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300)),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _term('1. Repair duration will be subject to availability of spares', nunitoFont),
                          _term('2. Delivery of repaired materials will be against payment', nunitoFont),
                          _term('3. Diagnostic charges will be applicable', nunitoFont),
                          _term('4. This sheet should be produced at the time of delivery', nunitoFont),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    // ---------- SIGNATURES ----------
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('CUSTOMER SIGNATURE',
                                  style: _signatureLabel(nunitoFont)),
                              pw.SizedBox(height: 40, width: 150, child: pw.Image(pw.MemoryImage(signatureImage))),
                              pw.Text(customerName,
                                  style: pw.TextStyle(font: nunitoFont, fontSize: 12)),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('SIGNED BY', style: _signatureLabel(nunitoFont)),
                              pw.SizedBox(height: 40, width: 150),
                              pw.Text(reportedBy, style: pw.TextStyle(font: nunitoFont, fontSize: 12)),
                            ]),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // Preview / share / save
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'TaskReport_$taskId.pdf',
  );
}

/* -------------------- SMALL HELPERS -------------------- */

pw.TextStyle _tableHeader(pw.Font font) =>
    pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 10);

pw.Widget _td(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: child,
    );

pw.Widget _twoLine(String label, String value, pw.Font font) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style:
                pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );

pw.Widget _sectionHeader(String text, pw.Font font) => pw.Container(
      color: const PdfColor.fromInt(0xFFEFEFEF),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font,
              fontSize: 11, fontWeight: pw.FontWeight.bold)),
    );

pw.Widget _sectionBody(String text, pw.Font font) => pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              left: pw.BorderSide(color: PdfColors.grey300),
              right: pw.BorderSide(color: PdfColors.grey300),
              bottom: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );

pw.TextStyle _photoHeader(pw.Font font) =>
    pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);

pw.TextStyle _signatureLabel(pw.Font font) =>
    pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);

pw.Widget _term(String text, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8)),
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
