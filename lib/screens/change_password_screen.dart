import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  Future<void> _changePassword() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = await openDatabase('app.db');
      final newHash = sha256.convert(utf8.encode(_newPassword.text)).toString();

      // Update local DB
      await db.update('settings', {'value': newHash}, where: 'key = ?', whereArgs: ['password_hash']);
      final result = await db.query('settings', where: 'key = ?', whereArgs: ['password_version']);
      int currentVersion = int.parse(result.first['value'] as String);
      int newVersion = currentVersion + 1;
      await db.update('settings', {'value': newVersion.toString()}, where: 'key = ?', whereArgs: ['password_version']);

      // --- Update Supabase ---
      final supabase = Supabase.instance.client;
      // Update password_hash
      await supabase
          .from('settings')
          .update({'value': newHash})
          .eq('key', 'password_hash');
      // Update password_version
      await supabase
          .from('settings')
          .update({'value': newVersion.toString()})
          .eq('key', 'password_version');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed"),
          backgroundColor: Color(0xFF22B14C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _newPassword.clear();
      _confirmPassword.clear();
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = "Failed to change password. Please try again.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Update App Password",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF22B14C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _newPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                    ),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                    validator: (val) =>
                        val != null && val.length < 4 ? "Too short" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                    ),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                    validator: (val) =>
                        val != _newPassword.text ? "Passwords do not match" : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22B14C),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _changePassword();
                              }
                            },
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text("Update Password"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
