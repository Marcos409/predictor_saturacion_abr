import 'package:flutter/material.dart';

import '../tema.dart';

class MensajeError extends StatelessWidget {
  final String mensaje;

  const MensajeError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.alerta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresApp.alerta.withValues(alpha: 0.7)),
      ),
      child: Text(
        mensaje,
        style: const TextStyle(color: ColoresApp.alerta, fontSize: 12),
      ),
    );
  }
}
