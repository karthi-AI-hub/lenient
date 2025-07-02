import 'package:flutter/material.dart';

class LenientSnackbar {
  static void showSuccess(BuildContext context, String message, {int milliseconds = 1300}) {
    _show(context, message, backgroundColor: const Color(0xFF7ED957), milliseconds: milliseconds);
  }

  static void showError(BuildContext context, String message, {int milliseconds = 1300}) {
    _show(context, message, backgroundColor: Colors.red, milliseconds: milliseconds);
  }

  static void showWarning(BuildContext context, String message, {int milliseconds = 1300}) {
    _show(context, message, backgroundColor: Colors.orange, milliseconds: milliseconds);
  }

  static void showInfo(BuildContext context, String message, {int milliseconds = 1300}) {
    _show(context, message, backgroundColor: Colors.blue, milliseconds: milliseconds);
  }

  static void _show(BuildContext context, String message, {required Color backgroundColor, int milliseconds = 1500}) {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        duration: Duration(milliseconds: milliseconds),
      ),
    );
  }
} 