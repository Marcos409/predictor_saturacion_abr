import 'package:flutter/material.dart';

import '../tema.dart';

class EncabezadoPantalla extends StatelessWidget {
  final String titulo;
  final String descripcion;

  const EncabezadoPantalla({
    super.key,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TI-SATURATION PREDICTOR',
          style: TextStyle(
            color: ColoresApp.acento,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          titulo,
          style: const TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          descripcion,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
