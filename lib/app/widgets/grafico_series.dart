import 'package:flutter/material.dart';

import '../../core/models/punto_entrada.dart';
import '../formato.dart';
import '../tema.dart';
import 'muestreo_grafico.dart';

class SerieGrafico {
  final String nombre;
  final List<PuntoEntrada> puntos;
  final Color color;

  const SerieGrafico({
    required this.nombre,
    required this.puntos,
    required this.color,
  });
}

class LineaLimite {
  final double valor;
  final String etiqueta;
  final Color color;

  const LineaLimite({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });
}

class MarcadorVertical {
  final double tiempo;
  final String etiqueta;
  final Color color;

  const MarcadorVertical({
    required this.tiempo,
    required this.etiqueta,
    required this.color,
  });
}

class GraficoSeries extends StatelessWidget {
  final List<SerieGrafico> series;
  final List<LineaLimite> limites;
  final List<MarcadorVertical> marcadores;
  final double altura;
  final bool mostrarEtiquetas;

  const GraficoSeries({
    super.key,
    required this.series,
    this.limites = const [],
    this.marcadores = const [],
    this.altura = 280,
    this.mostrarEtiquetas = true,
  });

  @override
  Widget build(BuildContext context) {
    final seriesVisibles = [
      for (final serie in series)
        SerieGrafico(
          nombre: serie.nombre,
          puntos: muestrearParaGrafico(serie.puntos),
          color: serie.color,
        ),
    ];
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: altura,
        child: CustomPaint(
          painter: _PintorSeries(
            series: seriesVisibles,
            limites: limites,
            marcadores: marcadores,
            mostrarEtiquetas: mostrarEtiquetas,
          ),
        ),
      ),
    );
  }
}

class _PintorSeries extends CustomPainter {
  final List<SerieGrafico> series;
  final List<LineaLimite> limites;
  final List<MarcadorVertical> marcadores;
  final bool mostrarEtiquetas;

  const _PintorSeries({
    required this.series,
    required this.limites,
    required this.marcadores,
    required this.mostrarEtiquetas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final todos = <PuntoEntrada>[for (final serie in series) ...serie.puntos];
    if (todos.isEmpty || size.width <= 0 || size.height <= 0) return;

    final margenIzquierdo = mostrarEtiquetas ? 46.0 : 4.0;
    final margenDerecho = mostrarEtiquetas ? 58.0 : 4.0;
    final margenSuperior = mostrarEtiquetas ? 16.0 : 4.0;
    final margenInferior = mostrarEtiquetas ? 24.0 : 4.0;

    final ancho = size.width - margenIzquierdo - margenDerecho;
    final alto = size.height - margenSuperior - margenInferior;
    if (ancho <= 0 || alto <= 0) return;

    var tInicial = todos.first.t;
    var tFinal = todos.first.t;
    var valorMinimo = todos.first.valor;
    var valorMaximo = todos.first.valor;
    for (final punto in todos) {
      if (punto.t < tInicial) tInicial = punto.t;
      if (punto.t > tFinal) tFinal = punto.t;
      if (punto.valor < valorMinimo) valorMinimo = punto.valor;
      if (punto.valor > valorMaximo) valorMaximo = punto.valor;
    }
    for (final limite in limites) {
      if (limite.valor < valorMinimo) valorMinimo = limite.valor;
      if (limite.valor > valorMaximo) valorMaximo = limite.valor;
    }
    final rangoT = tFinal - tInicial;
    var rangoValor = valorMaximo - valorMinimo;
    if (rangoValor.abs() < 1e-12) rangoValor = 1;
    if (rangoT.abs() < 1e-12) {
      tInicial -= 0.5;
      tFinal += 0.5;
    }

    double x(double t) =>
        margenIzquierdo + (t - tInicial) / (tFinal - tInicial) * ancho;
    double y(double valor) =>
        margenSuperior + (valorMaximo - valor) / rangoValor * alto;

    final pinturaGuia = Paint()
      ..color = AppColores.borde
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final posicion = margenSuperior + alto * i / 4;
      canvas.drawLine(
        Offset(margenIzquierdo, posicion),
        Offset(margenIzquierdo + ancho, posicion),
        pinturaGuia,
      );
      if (mostrarEtiquetas) {
        final valor = valorMaximo - rangoValor * i / 4;
        _dibujarTexto(
          canvas,
          formatearNumero(valor, decimales: 0),
          Offset(2, posicion - 6),
          AppColores.textoSecundario,
          9,
        );
      }
    }
    for (var i = 0; i <= 4; i++) {
      final posicion = margenIzquierdo + ancho * i / 4;
      canvas.drawLine(
        Offset(posicion, margenSuperior),
        Offset(posicion, margenSuperior + alto),
        pinturaGuia,
      );
    }

    if (mostrarEtiquetas) {
      _dibujarTexto(
        canvas,
        '${formatearNumero(tInicial, decimales: 0)} min',
        Offset(margenIzquierdo, size.height - 16),
        AppColores.textoSecundario,
        9,
      );
      final etiquetaFinal = '${formatearNumero(tFinal, decimales: 0)} min';
      final pintorFinal = _crearPintor(
        etiquetaFinal,
        AppColores.textoSecundario,
        9,
      );
      pintorFinal.paint(
        canvas,
        Offset(margenIzquierdo + ancho - pintorFinal.width, size.height - 16),
      );
    }

    for (final limite in limites) {
      final posicion = y(limite.valor);
      _dibujarLineaDiscontinua(
        canvas,
        Offset(margenIzquierdo, posicion),
        Offset(margenIzquierdo + ancho, posicion),
        Paint()
          ..color = limite.color.withValues(alpha: 0.85)
          ..strokeWidth = 3,
      );
      if (mostrarEtiquetas) {
        _dibujarTexto(
          canvas,
          limite.etiqueta,
          Offset(margenIzquierdo + ancho + 4, posicion - 6),
          limite.color,
          9,
        );
      }
    }

    for (final serie in series) {
      if (serie.puntos.isEmpty) continue;
      final trazado = Path();
      for (var i = 0; i < serie.puntos.length; i++) {
        final punto = serie.puntos[i];
        final posicion = Offset(x(punto.t), y(punto.valor));
        if (i == 0) {
          trazado.moveTo(posicion.dx, posicion.dy);
        } else {
          trazado.lineTo(posicion.dx, posicion.dy);
        }
      }
      canvas.drawPath(
        trazado,
        Paint()
          ..color = serie.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      if (mostrarEtiquetas) {
        final ultimo = serie.puntos.last;
        final pintorEtiqueta = _crearPintor(
          serie.nombre,
          AppColores.textoSecundario,
          9,
        );
        final dx = (x(ultimo.t) + 4)
            .clamp(
              margenIzquierdo,
              size.width - margenDerecho - pintorEtiqueta.width,
            )
            .toDouble();
        final dy = (y(ultimo.valor) - 14)
            .clamp(margenSuperior, margenSuperior + alto - 12)
            .toDouble();
        pintorEtiqueta.paint(canvas, Offset(dx, dy));
      }
    }

    for (final marcador in marcadores) {
      final posicion = x(marcador.tiempo);
      _dibujarLineaDiscontinua(
        canvas,
        Offset(posicion, margenSuperior),
        Offset(posicion, margenSuperior + alto),
        Paint()
          ..color = marcador.color.withValues(alpha: 0.9)
          ..strokeWidth = 3,
      );
      if (mostrarEtiquetas) {
        _dibujarTexto(
          canvas,
          marcador.etiqueta,
          Offset(posicion + 4, margenSuperior + 2),
          AppColores.textoSecundario,
          9,
        );
      }
    }
  }

  void _dibujarLineaDiscontinua(
    Canvas canvas,
    Offset inicio,
    Offset fin,
    Paint pintura,
  ) {
    const longitud = 5.0;
    const espacio = 4.0;
    final total = (fin - inicio).distance;
    if (total <= 0) return;
    final direccion = (fin - inicio) / total;
    var recorrido = 0.0;
    while (recorrido < total) {
      final finTramo = (recorrido + longitud).clamp(0.0, total);
      canvas.drawLine(
        inicio + direccion * recorrido,
        inicio + direccion * finTramo,
        pintura,
      );
      recorrido += longitud + espacio;
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
  bool shouldRepaint(covariant _PintorSeries oldDelegate) {
    return !identical(oldDelegate.series, series) ||
        !identical(oldDelegate.limites, limites) ||
        !identical(oldDelegate.marcadores, marcadores) ||
        oldDelegate.mostrarEtiquetas != mostrarEtiquetas;
  }
}
