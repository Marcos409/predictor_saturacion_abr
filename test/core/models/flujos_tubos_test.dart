import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/models/flujos_tubos.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';

import '../../engine/configuracion_prueba.dart';

void main() {
  final sistema = cargarSistema();

  test('modo derivado: el balance neto coincide con las derivadas', () {
    const x = 102.33;
    const y = 32.33;
    const entrada = 45.0;
    final coeficientes = sistema.coeficientes;

    final flujos = FlujosTubos.calcular(
      sistema: sistema,
      x: x,
      y: y,
      entradaExterna: entrada,
    );

    expect(flujos.hayDesglose, isTrue);
    expect(
      flujos.balanceA,
      closeTo(entrada + coeficientes.a11 * x + coeficientes.a12 * y, 1e-9),
    );
    expect(
      flujos.balanceB,
      closeTo(coeficientes.a21 * x + coeficientes.a22 * y, 1e-9),
    );
  });

  test('modo derivado: entrada y salida se desglosan por tubo', () {
    final flujos = FlujosTubos.calcular(
      sistema: sistema,
      x: 100,
      y: 50,
      entradaExterna: 30,
    );

    expect(flujos.aAB, closeTo(20 / 100 * 100, 1e-9));
    expect(flujos.aSalida, closeTo(10 / 100 * 100, 1e-9));
    expect(flujos.bAA, closeTo(20 / 200 * 50, 1e-9));
    expect(flujos.bSalida, closeTo(60 / 200 * 50, 1e-9));
    expect(flujos.entradaTotalA, closeTo(30 + flujos.bAA!, 1e-9));
    expect(flujos.salidaTotalA, closeTo(flujos.aAB! + flujos.aSalida!, 1e-9));
    expect(flujos.entradaTotalB, closeTo(flujos.aAB!, 1e-9));
    expect(flujos.salidaTotalB, closeTo(flujos.bAA! + flujos.bSalida!, 1e-9));
    expect(
      flujos.balanceA,
      closeTo(flujos.entradaTotalA - flujos.salidaTotalA, 1e-12),
    );
    expect(
      flujos.balanceB,
      closeTo(flujos.entradaTotalB - flujos.salidaTotalB, 1e-12),
    );
  });

  test('modo directo: sin desglose y balance por coeficientes', () {
    final directo = sistema.copyWith(
      tanques: sistema.tanques.copyWith(
        modoCoeficientes: 'directo',
        coeficientesDirectos: const CoeficientesSistema(
          a11: -0.3,
          a12: 0.1,
          a21: 0.2,
          a22: -0.4,
        ),
      ),
    );

    final flujos = FlujosTubos.calcular(
      sistema: directo,
      x: 10,
      y: 20,
      entradaExterna: 5,
    );

    expect(flujos.hayDesglose, isFalse);
    expect(flujos.aAB, isNull);
    expect(flujos.aSalida, isNull);
    expect(flujos.balanceA, closeTo(5 - 0.3 * 10 + 0.1 * 20, 1e-9));
    expect(flujos.balanceB, closeTo(0.2 * 10 - 0.4 * 20, 1e-9));
  });
}
