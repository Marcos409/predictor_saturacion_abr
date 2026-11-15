import 'package:flutter/material.dart';

/// Contenedor global de contenido de un módulo.
///
/// Centra el contenido, limita su ancho a 1280 px y aplica el padding
/// horizontal común (24 px; 32 px en pantallas anchas) para evitar que las
/// tarjetas y los campos se estiren a todo el ancho de la ventana.
class ContenedorModulo extends StatelessWidget {
  static const double anchoMaximo = 1280;
  static const double paddingEstandar = 24;
  static const double paddingAncho = 32;
  static const double anchoPantallaAncha = 1200;

  final Widget child;

  const ContenedorModulo({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final padding = restricciones.maxWidth >= anchoPantallaAncha
              ? paddingAncho
              : paddingEstandar;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: anchoMaximo),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 28, padding, 32),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
