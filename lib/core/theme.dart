import 'package:flutter/material.dart';

const MaterialColor primaryPurple = MaterialColor(
  0xFF6C5FFC,
  <int, Color>{
    50: Color(0xFFEDEBFF),
    100: Color(0xFFD1CEFF),
    200: Color(0xFFB3AFFF),
    300: Color(0xFF958FFF),
    400: Color(0xFF7C76FF),
    500: Color(0xFF6C5FFC),
    600: Color(0xFF6457E3),
    700: Color(0xFF5A4ECC),
    800: Color(0xFF5046B5),
    900: Color(0xFF3D3591),
  },
);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  primarySwatch: primaryPurple,
  scaffoldBackgroundColor: const Color(0xFFF9F9F9),
  dialogBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: primaryPurple,
  ).copyWith(
    primary: primaryPurple[500],
    secondary: primaryPurple[300],
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black87,
    background: const Color(0xFFF9F9F9),
    surfaceTint: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: TextStyle(color: primaryPurple[500]),
    hintStyle: TextStyle(color: Colors.grey[500]),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: primaryPurple[500]!),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: primaryPurple[200]!),
    ),
    disabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedErrorBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
    ),
    errorBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryPurple[500],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryPurple[500],
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryPurple[500],
      side: BorderSide(color: primaryPurple[500]!),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: primaryPurple[500]),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryPurple[500]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryPurple[200]!),
      ),
    ),
    menuStyle: MenuStyle(
      backgroundColor: MaterialStateProperty.all(Colors.white),
      surfaceTintColor: MaterialStateProperty.all(primaryPurple[50]),
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      color: Colors.black54,
    ),
  ),
);
