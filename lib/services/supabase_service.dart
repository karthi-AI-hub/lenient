import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/form_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  static Future<FormModel> uploadForm({
    required FormModel form,
    Uint8List? signatureBytes,
    List<File> before = const [],
    List<File> after = const [],
    bool isEdit = false,
    List<String> oldBeforeUrls = const [],
    List<String> oldAfterUrls = const [],
    String? oldSignatureUrl,
    void Function(double progress)? onProgress,
  }) async {
    if (isEdit) {
      // debugPrint('Editing form: deleting replaced images and signature');
      for (final url in oldBeforeUrls) {
        // debugPrint('Deleting replaced before image: $url');
        await _deleteImage(url);
      }
      for (final url in oldAfterUrls) {
        // debugPrint('Deleting replaced after image: $url');
        await _deleteImage(url);
      }
      if (oldSignatureUrl != null && form.signatureUrl != oldSignatureUrl) {
        // debugPrint('Deleting replaced signature: $oldSignatureUrl');
        await _deleteImage(oldSignatureUrl);
      }
    }
    int totalUploads = before.length + after.length + (signatureBytes != null ? 1 : 0);
    int completed = 0;
    void reportProgress() {
      if (onProgress != null && totalUploads > 0) {
        onProgress(completed / totalUploads);
      }
    }
    // Prepare upload futures
    Future<String?>? signatureFuture;
    if (signatureBytes != null) {
      signatureFuture = _uploadImage(
        signatureBytes,
        'signatures/${form.taskId}.png',
        contentType: 'image/png',
      ).then((url) {
        completed++;
        reportProgress();
        return url;
      });
    }
    List<Future<String>> beforeFutures = [];
    final uuid = Uuid();
    for (final f in before) {
      final fileName = 'before-${uuid.v4()}.jpg';
      beforeFutures.add(_compressImage(f).then((bytes) =>
        _uploadImage(bytes, 'photos-before/${form.taskId}/$fileName')
      ).then((url) {
        completed++;
        reportProgress();
        return url;
      }));
    }
    List<Future<String>> afterFutures = [];
    for (final f in after) {
      final fileName = 'after-${uuid.v4()}.jpg';
      afterFutures.add(_compressImage(f).then((bytes) =>
        _uploadImage(bytes, 'photos-after/${form.taskId}/$fileName')
      ).then((url) {
        completed++;
        reportProgress();
        return url;
      }));
    }
    reportProgress(); // initial 0.0
    // Await all uploads in parallel
    final results = await Future.wait([
      if (signatureFuture != null) signatureFuture,
      ...beforeFutures,
      ...afterFutures,
    ]);
    // Assign results
    int resultIdx = 0;
    String? signatureUrl = form.signatureUrl;
    if (signatureFuture != null) {
      signatureUrl = results[resultIdx] as String?;
      resultIdx++;
    }
    final beforeUrls = results.skip(resultIdx).take(beforeFutures.length).cast<String>().toList();
    resultIdx += beforeFutures.length;
    final afterUrls = results.skip(resultIdx).take(afterFutures.length).cast<String>().toList();
    // debugPrint('Final beforeUrls: $beforeUrls');
    // debugPrint('Final afterUrls: $afterUrls');
    final newForm = form.copyWith(
      signatureUrl: signatureUrl,
      beforePhotoUrls: [
        ...form.beforePhotoUrls ?? <String>[],
        ...beforeUrls
      ].take(3).toList().cast<String>(),
      afterPhotoUrls: [
        ...form.afterPhotoUrls ?? <String>[],
        ...afterUrls
      ].take(3).toList().cast<String>(),
      updatedAt: DateTime.now(),
    );
    // debugPrint('Saving form to database: ${newForm.toMap()}');
    if (isEdit) {
      await _client.from('forms').update(newForm.toMap()).eq('id', form.id);
    } else {
      await _client.from('forms').insert(newForm.toMap());
    }
    // debugPrint('Form saved. Returning newForm.');
    return newForm;
  }

  static Stream<List<FormModel>> streamForms() {
    return _client
        .from('forms')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) => data.map((e) => FormModel.fromMap(e)).toList());
  }

  static Future<void> _deleteFolderAndContents(String bucket, String folder) async {
    try {
      final response = await _client.storage.from(bucket).list(path: folder);
      final files = response
        .where((item) => item.name.isNotEmpty)
        .map((item) => '$folder/${item.name}')
        .toList();
      if (files.isNotEmpty) {
        await _client.storage.from(bucket).remove(files);
      }
      // Try to remove the folder itself (may be a no-op)
      await _client.storage.from(bucket).remove([folder]);
      // debugPrint('Deleted folder and contents: $bucket/$folder');
    } catch (e) {
      debugPrint('Failed to delete folder $bucket/$folder: $e');
    }
  }

  static Future<void> deleteForm(String id, List<String> imageUrls, String? signatureUrl, {String? taskId}) async {
    // Delete all individual images (legacy, for safety)
    for (final url in imageUrls) {
      await _deleteImage(url);
    }
    // Delete signature file
    if (signatureUrl != null) {
      await _deleteImage(signatureUrl);
    }
    // Delete entire before/after folders if taskId is provided
    if (taskId != null && taskId.isNotEmpty) {
      try {
        await _client.storage.from('photos-before').remove(['$taskId/']);
        // debugPrint('Deleted folder: photos-before/$taskId/');
      } catch (e) {
        debugPrint('Failed to delete before folder: $e');
      }
      try {
        await _client.storage.from('photos-after').remove(['$taskId/']);
        // debugPrint('Deleted folder: photos-after/$taskId/');
      } catch (e) {
        debugPrint('Failed to delete after folder: $e');
      }
      try {
        await _client.storage.from('signatures').remove(['$taskId.png']);
      } catch (e) {
        debugPrint('Failed to delete signature file: $e');
      }
    }
    // Delete the form row
    await _client.from('forms').delete().eq('id', id);
  }

  static Future<FormModel?> getForm(String id) async {
    final res = await _client.from('forms').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return FormModel.fromMap(res);
  }

  static Future<FormModel?> getFormByTaskId(String taskId) async {
    final res = await _client.from('forms').select().eq('task_id', taskId).maybeSingle();
    if (res == null) return null;
    return FormModel.fromMap(res);
  }

  static Future<String> _uploadImage(Uint8List bytes, String path, {String contentType = 'image/jpeg'}) async {
    // Determine bucket and filePath
    String bucket;
    String filePath;
    if (path.startsWith('signatures/')) {
      bucket = 'signatures';
      filePath = path.substring('signatures/'.length);
    } else if (path.startsWith('photos-before/')) {
      bucket = 'photos-before';
      filePath = path.substring('photos-before/'.length);
    } else if (path.startsWith('photos-after/')) {
      bucket = 'photos-after';
      filePath = path.substring('photos-after/'.length);
    } else {
      throw Exception('Unknown bucket for path: $path');
    }
    // debugPrint('Uploading to bucket: $bucket, filePath: $filePath, contentType: $contentType');
    final storage = _client.storage.from(bucket);
    await storage.uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: contentType, upsert: true));
    // debugPrint('Upload complete for $filePath');
    return storage.getPublicUrl(filePath);
  }

  static Future<void> _deleteImage(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Example: /storage/v1/object/public/bucket/path/to/file.jpg
      final publicIdx = segments.indexOf('public');
      if (publicIdx == -1 || publicIdx + 1 >= segments.length) {
        debugPrint('Could not parse bucket from url: $url');
        return;
      }
      final bucket = segments[publicIdx + 1];
      final filePath = segments.sublist(publicIdx + 2).join('/');
      // debugPrint('Deleting from bucket: $bucket, file: $filePath');
      await _client.storage.from(bucket).remove([filePath]);
      debugPrint('Delete complete for $filePath');
    } catch (e) {
      debugPrint('Failed to delete image for url $url: $e');
    }
  }

  static Future<Uint8List> _compressImage(File file) async {
    return compute(_compressImageSync, file.path);
  }

  static Uint8List _compressImageSync(String filePath) {
    final image = img.decodeImage(File(filePath).readAsBytesSync());
    final resized = img.copyResize(image!, width: 720);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 60));
  }

  static Future<String> uploadSignatureImage(Uint8List imageBytes, String taskId) async {
    final storage = _client.storage.from('signatures');
    final filePath = '$taskId.png';
    await storage.uploadBinary(filePath, imageBytes, fileOptions: FileOptions(contentType: 'image/png', upsert: true));
    return storage.getPublicUrl(filePath);
  }
} 