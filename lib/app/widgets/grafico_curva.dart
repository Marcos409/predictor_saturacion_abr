import 'package:flutter/material.dart';

import '../../core/models/punto_entrada.dart';
import '../formato.dart';
import '../tema.dart';

class GraficoCurva extends StatelessWidget {
  final List<PuntoEntrada> puntos;
  final Color color;
  final double altura;
  final bool mostrarEtiquetas;

  const GraficoCurva({
    super.key,
    required this.puntos,
    this.color = ColoresApp.acento,
    this.altura = 220,
    this.mostrarEtiquetas = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: altura,
      child: CustomPaint(
        painter: _PintorCurva(
          puntos: puntos,
          color: color,
          mostrarEtiquetas: mostrarEtiquetas,
        ),
      ),
    );
  }
}

class _PintorCurva extends CustomPainter {
  final List<PuntoEntrada> puntos;
  final Color color;
  final bool mostrarEtiquetas;

  const _PintorCurva({
    required this.puntos,
    required this.color,
    required this.mostrarEtiquetas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.isEmpty || size.width <= 0 || size.height <= 0) return;

    final margenIzquierdo = mostrarEtiquetas ? 4.0 : 2.0;
    final margenDerecho = mostrarEtiquetas ? 4.0 : 2.0;
    final margenSuperior = mostrarEtiquetas ? 20.0 : 4.0;
    final margenInferior = mostrarEtiquetas ? 20.0 : 4.0;

    final ancho = size.width - margenIzquierdo - margenDerecho;
    final alto = size.height - margenSuperior - margenInferior;
    if (ancho <= 0 || alto <= 0) return;

    final tInicial = puntos.first.t;
    final tFinal = puntos.last.t;
    final rangoT = tFinal - tInicial;

    var valorMinimo = puntos.first.valor;
    var valorMaximo = puntos.first.valor;
    for (final punto in puntos) {
      if (punto.valor < valorMinimo) valorMinimo = punto.valor;
      if (punto.valor > valorMaximo) valorMaximo = punto.valor;
    }
    final rangoValor = valorMaximo - valorMinimo;

    double x(double t) {
      if (rangoT.abs() < 1e-12) return margenIzquierdo + ancho / 2;
      return margenIzquierdo + (t - tInicial) / rangoT * ancho;
    }

    double y(double valor) {
      if (rangoValor.abs() < 1e-12) return margenSuperior + alto / 2;
      return margenSuperior + (valorMaximo - valor) / rangoValor * alto;
    }

    if (mostrarEtiquetas) {
      final pinturaGuia = Paint()
        ..color = ColoresApp.borde
        ..strokeWidth = 1;
      for (var i = 0; i <= 4; i++) {
        final posicion = margenSuperior + alto * i / 4;
        canvas.drawLine(
          Offset(margenIzquierdo, posicion),
          Offset(size.width - margenDerecho, posicion),
          pinturaGuia,
        );
      }
    }

    final trazado = Path();
    for (var i = 0; i < puntos.length; i++) {
      final punto = puntos[i];
      final posicion = Offset(x(punto.t), y(punto.valor));
      if (i == 0) {
        trazado.moveTo(posicion.dx, posicion.dy);
      } else {
        trazado.lineTo(posicion.dx, posicion.dy);
      }
    }

    final relleno = Path.from(trazado)
      ..lineTo(x(puntos.last.t), margenSuperior + alto)
      ..lineTo(x(puntos.first.t), margenSuperior + alto)
      ..close();
    canvas.drawPath(
      relleno,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromLTWH(margenIzquierdo, margenSuperior, ancho, alto),
            ),
    );

    canvas.drawPath(
      trazado,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    if (mostrarEtiquetas) {
      _dibujarTexto(
        canvas,
        formatearNumero(valorMaximo, decimales: 1),
        Offset(margenIzquierdo, 2),
        ColoresApp.textoSecundario,
        10,
      );
      _dibujarTexto(
        canvas,
        '${formatearNumero(tInicial, decimales: 0)} min',
        Offset(margenIzquierdo, size.height - 14),
        ColoresApp.textoSecundario,
        10,
      );
      final etiquetaFinal = '${formatearNumero(tFinal, decimales: 0)} min';
      final pintorFinal = _crearPintor(
        etiquetaFinal,
        ColoresApp.textoSecundario,
        10,
      );
      pintorFinal.paint(
        canvas,
        Offset(
          size.width - margenDerecho - pintorFinal.width,
          size.height - 14,
        ),
      );
    }
  }

  TextPainter _crearPintor(String texto, Color colorTexto, double tamano) {
    return TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(color: colorTexto, fontSize: tamano),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _dibujarTexto(
    Canvas canvas,
    String texto,
    Offset posicion,
    Color colorTexto,
    double tamano,
  ) {
    _crearPintor(texto, colorTexto, tamano).paint(canvas, posicion);
  }

  @override
  bool shouldRepaint(covariant _PintorCurva oldDelegate) {
    return !identical(oldDelegate.puntos, puntos) ||
        oldDelegate.color != color ||
        oldDelegate.mostrarEtiquetas != mostrarEtiquetas;
  }
}
