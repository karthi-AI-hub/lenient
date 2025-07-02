import 'package:hive/hive.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

part 'form_entry.g.dart';

@HiveType(typeId: 0)
enum FormStatus {
  @HiveField(0)
  saved,
  @HiveField(1)
  finalized,
}

@HiveType(typeId: 1)
class FormEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String taskId;
  @HiveField(2)
  String dateTime;
  @HiveField(3)
  String companyName;
  @HiveField(4)
  String phone;
  @HiveField(5)
  String addressLine;
  @HiveField(6)
  String addressCity;
  @HiveField(7)
  String reportedBy;
  @HiveField(8)
  String problemDescription;
  @HiveField(9)
  String reportDescription;
  @HiveField(10)
  String materialsDelivered;
  @HiveField(11)
  String materialsReceived;
  @HiveField(12)
  List<String> beforePhotoPaths;
  @HiveField(13)
  List<String> afterPhotoPaths;
  @HiveField(14)
  String customerName;
  @HiveField(15)
  Uint8List? signatureImage;
  @HiveField(16)
  int rating;
  @HiveField(17)
  FormStatus status;
  @HiveField(18)
  String? pdfPath; // Only for finalized forms
  @HiveField(19)
  int formType; // 1, 2, or 3

  FormEntry({
    required this.id,
    required this.taskId,
    required this.dateTime,
    required this.companyName,
    required this.phone,
    required this.addressLine,
    required this.addressCity,
    required this.reportedBy,
    required this.problemDescription,
    required this.reportDescription,
    required this.materialsDelivered,
    required this.materialsReceived,
    required this.beforePhotoPaths,
    required this.afterPhotoPaths,
    required this.customerName,
    required this.signatureImage,
    required this.rating,
    required this.status,
    this.pdfPath,
    required this.formType,
  });

  @override
  String toString() {
    return 'FormEntry(id: $id, taskId: $taskId, dateTime: $dateTime, companyName: $companyName, phone: $phone, addressLine: $addressLine, addressCity: $addressCity, reportedBy: $reportedBy, problemDescription: $problemDescription, reportDescription: $reportDescription, materialsDelivered: $materialsDelivered, materialsReceived: $materialsReceived, beforePhotoPaths: $beforePhotoPaths, afterPhotoPaths: $afterPhotoPaths, customerName: $customerName, signatureImage: ${signatureImage != null}, rating: $rating, status: $status, pdfPath: $pdfPath, formType: $formType)';
  }
} 