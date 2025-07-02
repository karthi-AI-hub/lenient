// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FormEntryAdapter extends TypeAdapter<FormEntry> {
  @override
  final int typeId = 1;

  @override
  FormEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormEntry(
      id: fields[0] as String,
      taskId: fields[1] as String,
      dateTime: fields[2] as String,
      companyName: fields[3] as String,
      phone: fields[4] as String,
      addressLine: fields[5] as String,
      addressCity: fields[6] as String,
      reportedBy: fields[7] as String,
      problemDescription: fields[8] as String,
      reportDescription: fields[9] as String,
      materialsDelivered: fields[10] as String,
      materialsReceived: fields[11] as String,
      beforePhotoPaths: (fields[12] as List).cast<String>(),
      afterPhotoPaths: (fields[13] as List).cast<String>(),
      customerName: fields[14] as String,
      signatureImage: fields[15] as Uint8List?,
      rating: fields[16] as int,
      status: fields[17] as FormStatus,
      pdfPath: fields[18] as String?,
      formType: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FormEntry obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.companyName)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.addressLine)
      ..writeByte(6)
      ..write(obj.addressCity)
      ..writeByte(7)
      ..write(obj.reportedBy)
      ..writeByte(8)
      ..write(obj.problemDescription)
      ..writeByte(9)
      ..write(obj.reportDescription)
      ..writeByte(10)
      ..write(obj.materialsDelivered)
      ..writeByte(11)
      ..write(obj.materialsReceived)
      ..writeByte(12)
      ..write(obj.beforePhotoPaths)
      ..writeByte(13)
      ..write(obj.afterPhotoPaths)
      ..writeByte(14)
      ..write(obj.customerName)
      ..writeByte(15)
      ..write(obj.signatureImage)
      ..writeByte(16)
      ..write(obj.rating)
      ..writeByte(17)
      ..write(obj.status)
      ..writeByte(18)
      ..write(obj.pdfPath)
      ..writeByte(19)
      ..write(obj.formType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FormStatusAdapter extends TypeAdapter<FormStatus> {
  @override
  final int typeId = 0;

  @override
  FormStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FormStatus.saved;
      case 1:
        return FormStatus.finalized;
      default:
        return FormStatus.saved;
    }
  }

  @override
  void write(BinaryWriter writer, FormStatus obj) {
    switch (obj) {
      case FormStatus.saved:
        writer.writeByte(0);
        break;
      case FormStatus.finalized:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
