import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/engine/verificador_cruzado.dart';
import 'package:predictor_saturacion_abr/core/models/punto_simulacion.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_verificacion.dart';

class _AnaliticaFija implements EvaluadorAnalitico {
  final double x;
  final double y;

  const _AnaliticaFija({required this.x, required this.y});

  @override
  double evaluarX(double t) => x;

  @override
  double evaluarY(double t) => y;
}

void main() {
  const verificador = VerificadorCruzado();
  const analitica = _AnaliticaFija(x: 1e9, y: 1e9);
  final puntos = [
    const PuntoSimulacion(t: 0, x: 1e9, y: 1e9),
    const PuntoSimulacion(t: 1, x: 1e9 + 1, y: 1e9),
  ];

  test('el error absoluto grande no marca discrepancia si el relativo es bajo', () {
    final resultado = verificador.verificar(
      puntosNumericos: puntos,
      analitica: analitica,
    );

    expect(resultado.errorMaximo, 1);
    expect(resultado.errorRelativo, lessThan(1e-6));
    expect(resultado.estado, EstadoVerificacion.coincide);
    expect(resultado.hayDiscrepancia, isFalse);
  });

  test('el umbral relativo es configurable', () {
    final resultado = verificador.verificar(
      puntosNumericos: puntos,
      analitica: analitica,
      umbral: 1e-12,
    );

    expect(resultado.umbral, 1e-12);
    expect(resultado.errorRelativo, greaterThan(1e-12));
    expect(resultado.estado, EstadoVerificacion.discrepancia);
    expect(resultado.hayDiscrepancia, isTrue);
  });

  test('un error pequeño en escala pequeña también marca discrepancia', () {
    final resultado = verificador.verificar(
      puntosNumericos: const [PuntoSimulacion(t: 0, x: 0.001, y: 0)],
      analitica: const _AnaliticaFija(x: 0, y: 0),
    );

    expect(resultado.errorMaximo, closeTo(0.001, 1e-12));
    expect(resultado.errorRelativo, closeTo(1, 1e-12));
    expect(resultado.hayDiscrepancia, isTrue);
  });
}
