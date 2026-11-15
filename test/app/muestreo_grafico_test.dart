import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/widgets/muestreo_grafico.dart';
import 'package:predictor_saturacion_abr/core/models/punto_entrada.dart';

void main() {
  test('reduce la serie larga al máximo fijo conservando los extremos', () {
    final puntos = [
      for (var i = 0; i < 28803; i++) PuntoEntrada(t: i * 0.05, valor: i * 2.0),
    ];

    final muestreados = muestrearParaGrafico(puntos);

    expect(muestreados.length, maxPuntosGrafico);
    expect(muestreados.first.t, puntos.first.t);
    expect(muestreados.last.t, puntos.last.t);
    expect(muestreados.first.valor, puntos.first.valor);
    expect(muestreados.last.valor, puntos.last.valor);
    for (var i = 1; i < muestreados.length; i++) {
      expect(muestreados[i].t, greaterThan(muestreados[i - 1].t));
    }
  });

  test('devuelve la misma lista cuando ya es corta', () {
    final puntos = [
      for (var i = 0; i < 10; i++) PuntoEntrada(t: i.toDouble(), valor: 1),
    ];

    expect(identical(muestrearParaGrafico(puntos), puntos), isTrue);
  });
}
