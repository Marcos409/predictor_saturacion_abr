import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

export 'theme/app_colors.dart';

ThemeData construirTemaClaro() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColores.fondo,
    colorScheme: const ColorScheme.light(
      primary: AppColores.primario,
      onPrimary: AppColores.sobrePrimario,
      secondary: AppColores.secundario,
      onSecondary: AppColores.sobreSecundario,
      error: AppColores.importante,
      onError: AppColores.sobreImportante,
      surface: AppColores.superficie,
      onSurface: AppColores.textoPrincipal,
      outline: AppColores.bordeControl,
    ),
    dividerColor: AppColores.borde,
    dividerTheme: const DividerThemeData(color: AppColores.borde, thickness: 1),
    iconTheme: const IconThemeData(color: AppColores.textoSecundario),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColores.primario,
      width: 240,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColores.primario,
      foregroundColor: AppColores.sobrePrimario,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColores.sobrePrimario,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColores.textoPrincipal,
      displayColor: AppColores.textoPrincipal,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: AppColores.primario,
        foregroundColor: AppColores.sobrePrimario,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: AppColores.secundario,
        foregroundColor: AppColores.sobreSecundario,
        side: const BorderSide(color: AppColores.secundario),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: AppColores.primarioOscuro,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColores.superficie,
      labelStyle: const TextStyle(color: AppColores.textoSecundario),
      helperStyle: const TextStyle(
        color: AppColores.textoSecundario,
        fontSize: 12,
      ),
      suffixStyle: const TextStyle(color: AppColores.textoSecundario),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColores.bordeControl),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColores.bordeControl),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColores.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColores.primario, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColores.primario,
      linearTrackColor: AppColores.borde,
    ),
    visualDensity: VisualDensity.standard,
  );
}

ThemeData construirTemaOscuro() => construirTemaClaro();
