import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Motivo decorativo del panel de marca: dos tanques conectados por tubos y
/// ondas, dibujados de forma sutil en tonos grafico y primarioOscuro.
class MotivoLogin extends StatelessWidget {
  const MotivoLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _PintorMotivoLogin(),
      size: Size.infinite,
    );
  }
}

class _PintorMotivoLogin extends CustomPainter {
  const _PintorMotivoLogin();

  @override
  void paint(Canvas canvas, Size size) {
    final trazoTanque = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = AppColores.grafico.withValues(alpha: 0.65);
    final trazoTubo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColores.grafico.withValues(alpha: 0.5);
    final trazoOnda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColores.primarioOscuro.withValues(alpha: 0.55);

    final anchoTanque = size.width * 0.18;
    final altoTanque = size.height * 0.42;
    final yTanque = size.height * 0.16;
    final radio = Radius.circular(math.min(anchoTanque, altoTanque) * 0.22);

    final tanqueA = Rect.fromLTWH(
      size.width * 0.12,
      yTanque,
      anchoTanque,
      altoTanque,
    );
    final tanqueB = Rect.fromLTWH(
      size.width - size.width * 0.12 - anchoTanque,
      yTanque,
      anchoTanque,
      altoTanque,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(tanqueA, radio), trazoTanque);
    canvas.drawRRect(RRect.fromRectAndRadius(tanqueB, radio), trazoTanque);

    final yTuboSuperior = yTanque + altoTanque * 0.3;
    final yTuboInferior = yTanque + altoTanque * 0.62;
    canvas.drawLine(
      Offset(tanqueA.right, yTuboSuperior),
      Offset(tanqueB.left, yTuboSuperior),
      trazoTubo,
    );
    canvas.drawLine(
      Offset(tanqueA.right, yTuboInferior),
      Offset(tanqueB.left, yTuboInferior),
      trazoTubo,
    );

    final yOnda = size.height * 0.82;
    for (var fila = 0; fila < 3; fila++) {
      final desplazamiento = fila * 10.0;
      final camino = Path()..moveTo(0, yOnda + desplazamiento);
      const paso = 14.0;
      for (var x = 0.0; x <= size.width; x += paso) {
        final y =
            yOnda +
            desplazamiento +
            math.sin((x / size.width) * math.pi * 6) * 6;
        camino.lineTo(x, y);
      }
      canvas.drawPath(
        camino,
        trazoOnda
          ..color = AppColores.primarioOscuro.withValues(
            alpha: 0.5 - fila * 0.12,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorMotivoLogin oldDelegate) => false;
}
