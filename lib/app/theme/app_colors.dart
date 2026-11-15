import 'package:flutter/material.dart';

/// Tokens de color de TI-Saturation Predictor.
///
/// Toda la interfaz debe tomar sus colores de aquí; no se admiten colores
/// sueltos en widgets, pantallas ni gráficos.
class AppColores {
  AppColores._();

  static const Color fondo = Color(0xFFFDFAF6);
  static const Color superficie = Color(0xFFFEFEFC);
  static const Color panelSecundario = Color(0xFFFDF2E6);

  static const Color primario = Color(0xFF01999F);
  static const Color primarioOscuro = Color(0xFF017A80);
  static const Color secundario = Color(0xFFFE6628);
  static const Color importante = Color(0xFFDC1559);

  static const Color grafico = Color(0xFF03AAB2);
  static const Color graficoBD = Color(0xFF6C4AB6);

  static const Color textoPrincipal = Color(0xFF1A252F);
  static const Color textoSecundario = Color(0xFF5B6770);
  static const Color borde = Color(0xFFE6DCCF);
  static const Color exito = Color(0xFF1F7A4D);

  static const Color sobrePrimario = Color(0xFFFFFFFF);
  static const Color sobreSecundario = Color(0xFF1A252F);
  static const Color sobreImportante = Color(0xFFFFFFFF);

  /// Variantes accesibles para texto pequeño sobre fondos claros.
  static const Color secundarioTexto = Color(0xFFA0470F);
  static const Color bordeControl = Color(0xFF8A7C6A);

  static const Color transparente = Color(0x00000000);

  static const Color aviso = secundarioTexto;
  static const Color acento = primarioOscuro;
  static const Color panel = superficie;
}

/// Nombres anteriores de la paleta, conservados para no romper los módulos
/// que todavía los usan. Apuntan siempre a los tokens nuevos.
class ColoresApp {
  ColoresApp._();

  static const Color fondo = AppColores.fondo;
  static const Color panel = AppColores.superficie;
  static const Color acento = AppColores.primarioOscuro;
  static const Color alerta = AppColores.importante;
  static const Color aviso = AppColores.secundarioTexto;
  static const Color ok = AppColores.exito;
  static const Color borde = AppColores.borde;
  static const Color bordeControl = AppColores.bordeControl;
  static const Color textoPrimario = AppColores.textoPrincipal;
  static const Color textoSecundario = AppColores.textoSecundario;
}
