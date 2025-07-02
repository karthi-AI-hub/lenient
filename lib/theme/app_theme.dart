import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Nunito', 'Roboto'],
      scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F9FB),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF222222)),
        bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Color(0xFF222222)),
        labelLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222222)),
      ),
    );
  }
} 