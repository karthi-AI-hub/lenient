import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

Future<Database> openAppDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'app.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Create the settings table
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Try to create the settings table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    },
  );
}

// --- Supabase password/version logic ---

Future<Map<String, dynamic>?> fetchPasswordFromSupabase() async {
  // Fetch both password_hash and password_version from key/value table using two queries
  final hashRow = await Supabase.instance.client
      .from('settings')
      .select('value')
      .eq('key', 'password_hash')
      .maybeSingle();
  final versionRow = await Supabase.instance.client
      .from('settings')
      .select('value')
      .eq('key', 'password_version')
      .maybeSingle();

  if (hashRow == null || versionRow == null) return null;
  final hash = hashRow['value'] as String?;
  final version = int.tryParse(versionRow['value'] as String? ?? '');
  if (hash == null || version == null) return null;
  return {'password_hash': hash, 'password_version': version};
}

Future<void> storePasswordLocally(String hash, int version) async {
  final db = await openAppDatabase();
  await db.insert('settings', {'key': 'password_hash', 'value': hash}, conflictAlgorithm: ConflictAlgorithm.replace);
  await db.insert('settings', {'key': 'password_version', 'value': version.toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<Map<String, String>?> getLocalPasswordAndVersion() async {
  final db = await openAppDatabase();
  final hashRes = await db.query('settings', where: 'key = ?', whereArgs: ['password_hash']);
  final verRes = await db.query('settings', where: 'key = ?', whereArgs: ['password_version']);
  if (hashRes.isEmpty || verRes.isEmpty) return null;
  return {
    'password_hash': hashRes.first['value'] as String,
    'password_version': verRes.first['value'] as String,
  };
}

Future<bool> validatePasswordWithSupabase(String input) async {
  final supa = await fetchPasswordFromSupabase();
  if (supa == null) return false;
  final inputHash = sha256.convert(utf8.encode(input)).toString();
  return inputHash == supa['password_hash'];
}

Future<int?> getSupabasePasswordVersion() async {
  final supa = await fetchPasswordFromSupabase();
  if (supa == null) return null;
  return supa['password_version'] as int?;
}

Future<int?> getLocalPasswordVersion() async {
  final db = await openAppDatabase();
  final res = await db.query('settings', where: 'key = ?', whereArgs: ['password_version']);
  if (res.isEmpty) return null;
  return int.tryParse(res.first['value'] as String);
}

Future<bool> isPasswordVersionSynced() async {
  final local = await getLocalPasswordVersion();
  final remote = await getSupabasePasswordVersion();
  if (local == null || remote == null) return false;
  return local == remote;
}