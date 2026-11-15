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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColores.primario,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            titulo,
            style: const TextStyle(
              color: AppColores.sobrePrimario,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descripcion,
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
