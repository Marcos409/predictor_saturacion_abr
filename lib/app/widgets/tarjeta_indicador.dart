import 'package:flutter/material.dart';

import '../tema.dart';

class TarjetaIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? detalle;
  final IconData icono;
  final Color color;

  const TarjetaIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.detalle,
    this.color = AppColores.primarioOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColores.superficie,
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
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColores.textoSecundario,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 4),
            Text(
              detalle!,
              style: const TextStyle(
                color: AppColores.textoSecundario,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
