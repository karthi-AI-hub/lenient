
import 'package:uuid/uuid.dart';

class FormModel {
  final String id;
  final String taskId;
  final String formType;
  final String companyName;
  final String? customeName;
  final String? phone;
  final String? addressLine;
  final String? addressCity;
  final String? reportedBy;
  final String? problemDescription;
  final String? reportDescription;
  final String? materialsDelivered;
  final String? materialsReceived;
  final int? rating;
  final String? signatureUrl;
  final List<String>? beforePhotoUrls;
  final List<String>? afterPhotoUrls;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FormModel({
    required this.id,
    required this.taskId,
    required this.formType,
    required this.companyName,
    this.customeName,
    this.phone,
    this.addressLine,
    this.addressCity,
    this.reportedBy,
    this.problemDescription,
    this.reportDescription,
    this.materialsDelivered,
    this.materialsReceived,
    this.rating,
    this.signatureUrl,
    this.beforePhotoUrls,
    this.afterPhotoUrls,
    this.status = "Ongoing",
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormModel.fromMap(Map<String, dynamic> map) {
    return FormModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      formType: map['form_type'] as String,
      companyName: map['company_name'] as String,
      customeName: map['customer_name'] as String?,
      phone: map['phone'] as String?,
      addressLine: map['address_line'] as String?,
      addressCity: map['address_city'] as String?,
      reportedBy: map['reported_by'] as String?,
      problemDescription: map['problem_description'] as String?,
      reportDescription: map['report_description'] as String?,
      materialsDelivered: map['materials_delivered'] as String?,
      materialsReceived: map['materials_received'] as String?,
      rating: map['rating'] as int?,
      signatureUrl: map['signature_url'] as String?,
      beforePhotoUrls: (map['before_photo_urls'] as List<dynamic>?)?.cast<String>(),
      afterPhotoUrls: (map['after_photo_urls'] as List<dynamic>?)?.cast<String>(),
      status: map['status'] as String? ?? "Ongoing",
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'form_type': formType,
      'company_name': companyName,
      'customer_name': customeName,
      'phone': phone,
      'address_line': addressLine,
      'address_city': addressCity,
      'reported_by': reportedBy,
      'problem_description': problemDescription,
      'report_description': reportDescription,
      'materials_delivered': materialsDelivered,
      'materials_received': materialsReceived,
      'rating': rating,
      'signature_url': signatureUrl,
      'before_photo_urls': beforePhotoUrls,
      'after_photo_urls': afterPhotoUrls,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FormModel copyWith({
    String? id,
    String? taskId,
    String? formType,
    String? companyName,
    String? customeName,
    String? phone,
    String? addressLine,
    String? addressCity,
    String? reportedBy,
    String? problemDescription,
    String? reportDescription,
    String? materialsDelivered,
    String? materialsReceived,
    int? rating,
    String? signatureUrl,
    List<String>? beforePhotoUrls,
    List<String>? afterPhotoUrls,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      formType: formType ?? this.formType,
      companyName: companyName ?? this.companyName,
      customeName: customeName ?? this.customeName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      addressCity: addressCity ?? this.addressCity,
      reportedBy: reportedBy ?? this.reportedBy,
      problemDescription: problemDescription ?? this.problemDescription,
      reportDescription: reportDescription ?? this.reportDescription,
      materialsDelivered: materialsDelivered ?? this.materialsDelivered,
      materialsReceived: materialsReceived ?? this.materialsReceived,
      rating: rating ?? this.rating,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      beforePhotoUrls: beforePhotoUrls ?? this.beforePhotoUrls,
      afterPhotoUrls: afterPhotoUrls ?? this.afterPhotoUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static FormModel empty() {
    final now = DateTime.now().toUtc();
    return FormModel(
      id: const Uuid().v4(),
      taskId: '',
      formType: '',
      companyName: '',
      status: 'Ongoing',
      createdAt: now,
      updatedAt: now,
    );
  }
} 