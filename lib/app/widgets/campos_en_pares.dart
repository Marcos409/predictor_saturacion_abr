import 'package:flutter/material.dart';

/// Coloca dos campos lado a lado cuando hay espacio y los apila cuando no.
///
/// Cada campo se limita a [anchoMaximo] píxeles para que los campos numéricos
/// no se estiren en pantallas anchas. Si el ancho disponible no alcanza para
/// los dos, se apilan en vertical.
class CamposEnPares extends StatelessWidget {
  final Widget primero;
  final Widget segundo;
  final double anchoMaximo;
  final double separacion;

  const CamposEnPares({
    super.key,
    required this.primero,
    required this.segundo,
    this.anchoMaximo = 280,
    this.separacion = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        const anchoMinimo = 150.0;
        final disponible = restricciones.maxWidth;
        final ancho = ((disponible - separacion) / 2).clamp(
          anchoMinimo,
          anchoMaximo,
        );
        if (disponible >= ancho * 2 + separacion) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: ancho, child: primero),
              SizedBox(width: separacion),
              SizedBox(width: ancho, child: segundo),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primero,
            SizedBox(height: separacion),
            segundo,
          ],
        );
      },
    );
  }
}
