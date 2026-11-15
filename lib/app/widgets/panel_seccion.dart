import 'package:flutter/material.dart';

import '../tema.dart';

class PanelSeccion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;
  final Widget? accion;
  final Color? fondo;

  const PanelSeccion({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.child,
    this.accion,
    this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fondo ?? AppColores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
        boxShadow: [
          BoxShadow(
            color: AppColores.textoPrincipal.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColores.textoPrincipal,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo!,
                        style: const TextStyle(
                          color: AppColores.textoSecundario,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (accion != null) ...[const SizedBox(width: 12), accion!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
