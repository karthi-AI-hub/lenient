import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'permission_dialog.dart';

class PermissionManager {
  static Future<bool> ensureAllPermissions(BuildContext context) async {
    while (true) {
      final storage = await Permission.storage.status;
      final manageStorage = await Permission.manageExternalStorage.status;
      final camera = await Permission.camera.status;
      List<Permission> missing = [];
      if (!storage.isGranted && !manageStorage.isGranted) missing.add(Permission.storage);
      if (!manageStorage.isGranted && !storage.isGranted) missing.add(Permission.manageExternalStorage);
      if (!camera.isGranted) missing.add(Permission.camera);
      if (missing.isEmpty) return true;
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PermissionDialog(
          onRetry: () => Navigator.of(context).pop('retry'),
          onExit: () => Navigator.of(context).pop('exit'),
          parentContext: context,
          missingPermissions: missing,
        ),
      );
      if (result == 'retry') continue;
      return false;
    }
  }

  static Future<bool> ensureCameraAndGalleryPermissions(BuildContext context) async {
    final storage = await Permission.storage.status;
    final manageStorage = await Permission.manageExternalStorage.status;
    final camera = await Permission.camera.status;
    List<Permission> missing = [];
    if (!storage.isGranted && !manageStorage.isGranted) missing.add(Permission.storage);
    if (!manageStorage.isGranted && !storage.isGranted) missing.add(Permission.manageExternalStorage);
    if (!camera.isGranted) missing.add(Permission.camera);
    if (missing.isEmpty) return true;
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionDialog(
        onRetry: () => Navigator.of(context).pop('retry'),
        onExit: () => Navigator.of(context).pop('exit'),
        parentContext: context,
        missingPermissions: missing,
      ),
    );
    if (result == 'retry') return await ensureCameraAndGalleryPermissions(context);
    return false;
  }

  static Future<bool> ensureStoragePermission(BuildContext context) async {
    final storage = await Permission.storage.status;
    final manageStorage = await Permission.manageExternalStorage.status;
    List<Permission> missing = [];
    if (!storage.isGranted && !manageStorage.isGranted) missing.add(Permission.storage);
    if (!manageStorage.isGranted && !storage.isGranted) missing.add(Permission.manageExternalStorage);
    if (missing.isEmpty) return true;
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionDialog(
        onRetry: () => Navigator.of(context).pop('retry'),
        onExit: () => Navigator.of(context).pop('exit'),
        parentContext: context,
        missingPermissions: missing,
      ),
    );
    if (result == 'retry') return await ensureStoragePermission(context);
    return false;
  }
} 