import 'package:flutter/material.dart';

class AppTheme {
  // Paleta personalizada
  static const Color color1 = Color(0xFFB87856); // Marrón principal
  static const Color color2 = Color(0xFFCD977B); // Marrón claro
  static const Color color3 = Color(0xFFE6CDB7); // Beige
  static const Color color4 = Color(0xFFEAE4D5); // Fondo claro
  static const Color color5 = Color(0xFF000000); // Negro
  static const Color color6 = Color(0xFF637983); // Botón fondo
  static const Color color7 = Color(0xFFA2B0BE); // Gris azulado
  static const Color color8 = Color(0xFFEEEFF1); // Gris muy claro

  static const Color color9 = Color(0xFF4A6FA5); // Azul oscuro para acentos

  static ThemeData theme = ThemeData(
    // color1..color8 se usan en todo el proyecto para mantener la paleta.
    primaryColor: color6,
    scaffoldBackgroundColor: color4,
    fontFamily: 'Sansation',
    appBarTheme: const AppBarTheme(
      backgroundColor: color6,
      foregroundColor: color4,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: color4),
      titleTextStyle: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
        letterSpacing: 1.2,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: 'Sansation',
        color: color5,
        fontSize: 18,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Sansation',
        color: color5,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Sansation',
        color: color5,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
      ),
      labelSmall: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
      ),
      titleLarge: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
      ),
      titleMedium: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontFamily: 'OleoScript',
        color: color4,
        fontSize: 26,
        fontWeight: FontWeight.normal,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: color6,
        foregroundColor: color4,
        textStyle: const TextStyle(
          fontFamily: 'Sansation',
          fontWeight: FontWeight.normal,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: color4,
        textStyle: const TextStyle(
          fontFamily: 'Sansation',
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: color4),
    drawerTheme: const DrawerThemeData(
      backgroundColor: color6,
    ),
    cardColor: color3,
    dividerColor: color7,
  );
}