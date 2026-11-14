import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/solver_runge_kutta.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';

import 'configuracion_prueba.dart';

void main() {
  group('SolucionadorRungeKutta', () {
    final sistema = cargarSistema();
    final solucionador = SolucionadorRungeKutta(configuracion: sistema);

    test('recorre el horizonte y ajusta el último paso', () {
      final resultado = solucionador.resolver(
        entrada: (_) => 0,
        paso: 0.3,
        tFinal: 1,
      );

      expect(resultado.puntos.length, 5);
      expect(resultado.inicial.t, 0);
      expect(resultado.ultimo.t, closeTo(1, 1e-12));
      expect(resultado.paso, 0.3);
      expect(resultado.tInicial, 0);
      expect(resultado.tFinal, 1);
    });

    test('permite iniciar en un tiempo distinto de cero', () {
      final resultado = solucionador.resolver(
        entrada: (_) => 1,
        paso: 0.25,
        tInicial: 2,
        tFinal: 3,
      );

      expect(resultado.inicial.t, 2);
      expect(resultado.ultimo.t, closeTo(3, 1e-12));
    });

    test('usa las condiciones iniciales de la configuración', () {
      final configuracion = sistema.copyWith(
        condicionesIniciales: const CondicionesIniciales(x0: 3, y0: 4),
      );
      final resultado = SolucionadorRungeKutta(
        configuracion: configuracion,
      ).resolver(entrada: (_) => 0, paso: 0.5, tFinal: 1);

      expect(resultado.inicial.x, 3);
      expect(resultado.inicial.y, 4);
    });

    test('rechaza un paso no positivo', () {
      expect(
        () => solucionador.resolver(entrada: (_) => 0, paso: 0, tFinal: 1),
        throwsArgumentError,
      );
      expect(
        () => solucionador.resolver(entrada: (_) => 0, paso: -0.1, tFinal: 1),
        throwsArgumentError,
      );
    });

    test('rechaza un tiempo final anterior al inicial', () {
      expect(
        () => solucionador.resolver(
          entrada: (_) => 0,
          paso: 0.1,
          tInicial: 2,
          tFinal: 1,
        ),
        throwsArgumentError,
      );
    });

    test('mantiene el punto inicial cuando el horizonte es cero', () {
      final resultado = solucionador.resolver(
        entrada: (_) => 0,
        paso: 0.1,
        tFinal: 0,
      );

      expect(resultado.puntos.length, 1);
      expect(resultado.inicial.t, 0);
    });
  });
}
