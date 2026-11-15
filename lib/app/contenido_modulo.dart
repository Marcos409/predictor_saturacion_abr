import 'package:flutter/material.dart';

import 'modulos.dart';
import 'tema.dart';
import 'widgets/contenedor_modulo.dart';

class ContenidoModulo extends StatelessWidget {
  final ModuloApp modulo;

  const ContenidoModulo({super.key, required this.modulo});

  @override
  Widget build(BuildContext context) {
    return ContenedorModulo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TI-SATURATION PREDICTOR',
            style: TextStyle(
              color: AppColores.primarioOscuro,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            modulo.titulo,
            style: const TextStyle(
              color: AppColores.textoPrincipal,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            modulo.descripcion,
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _EstadoVacio(modulo: modulo),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final ModuloApp modulo;

  const _EstadoVacio({required this.modulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: AppColores.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColores.borde),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColores.primarioOscuro.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  modulo.icono,
                  color: AppColores.primarioOscuro,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Módulo en preparación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColores.textoPrincipal,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí se mostrará ${modulo.descripcion.toLowerCase()}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColores.textoSecundario,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
