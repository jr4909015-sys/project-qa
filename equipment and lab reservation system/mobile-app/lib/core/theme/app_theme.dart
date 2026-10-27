import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF176B4B);
  static const ink = Color(0xFF202723);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
          surface: const Color(0xFFF5F5F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F0),
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFE3E6DF)),
          ),
        ),
      );
}