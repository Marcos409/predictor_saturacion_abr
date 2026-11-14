import 'package:flutter/material.dart';

class ColoresApp {
  ColoresApp._();

  static const Color fondo = Color(0xFF0B121A);
  static const Color panel = Color(0xFF111C27);
  static const Color acento = Color(0xFF1FB6A6);
  static const Color alerta = Color(0xFFFF8F8F);
  static const Color aviso = Color(0xFFF5B942);
  static const Color ok = Color(0xFF4CC38A);
  static const Color borde = Color(0xFF1E2D3D);
  static const Color bordeControl = Color(0xFF5A738C);
  static const Color textoPrimario = Color(0xFFE7EEF6);
  static const Color textoSecundario = Color(0xFF8DA2B5);
}

ThemeData construirTemaOscuro() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: ColoresApp.fondo,
    colorScheme: const ColorScheme.dark(
      primary: ColoresApp.acento,
      onPrimary: ColoresApp.fondo,
      secondary: ColoresApp.acento,
      onSecondary: ColoresApp.fondo,
      surface: ColoresApp.panel,
      onSurface: ColoresApp.textoPrimario,
      error: ColoresApp.alerta,
      onError: ColoresApp.fondo,
      outline: ColoresApp.bordeControl,
    ),
    dividerColor: ColoresApp.borde,
    iconTheme: const IconThemeData(color: ColoresApp.textoSecundario),
    drawerTheme: const DrawerThemeData(
      backgroundColor: ColoresApp.panel,
      width: 300,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresApp.fondo,
      foregroundColor: ColoresApp.textoPrimario,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: ColoresApp.textoPrimario,
      displayColor: ColoresApp.textoPrimario,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: ColoresApp.bordeControl),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    visualDensity: VisualDensity.standard,
  );
}
