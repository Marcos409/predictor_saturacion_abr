import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';

import 'configuracion_prueba.dart';

void main() {
  group('EvaluadorSolucionAnalitica', () {
    final evaluador = EvaluadorSolucionAnalitica.desdeJson(
      leerSolucionAnaliticaCruda(),
    );

    test('lee las expresiones desde soluciones.json', () {
      expect(evaluador.solucion.expresionX, contains('exp'));
      expect(evaluador.solucion.variable, 't');
    });

    test('cumple las condiciones iniciales', () {
      expect(evaluador.evaluarX(0), closeTo(0, 1e-12));
      expect(evaluador.evaluarY(0), closeTo(0, 1e-12));
    });

    test('x(7) y y(7) coinciden con la solución de referencia', () {
      expect(evaluador.evaluarX(7), closeTo(102.32984819695977, 1e-9));
      expect(evaluador.evaluarY(7), closeTo(32.32984819695977, 1e-9));
    });

    test('muestrea un intervalo completo', () {
      final puntos = evaluador.muestrear(tInicial: 0, tFinal: 2, paso: 0.5);
      expect(puntos.length, 5);
      expect(puntos.first.t, 0);
      expect(puntos.last.t, 2);
    });

    test('incluye el tiempo final aunque no sea múltiplo del paso', () {
      final puntos = evaluador.muestrear(tInicial: 0, tFinal: 1, paso: 0.3);
      expect(puntos.length, 5);
      expect(puntos.last.t, 1);
      expect(puntos.last.x, closeTo(evaluador.evaluarX(1), 1e-12));
    });

    test('construye un punto con ambas variables', () {
      final punto = evaluador.punto(7);
      expect(punto.t, 7);
      expect(punto.x, evaluador.evaluarX(7));
      expect(punto.y, evaluador.evaluarY(7));
    });

    test('rechaza un paso no positivo', () {
      expect(
        () => evaluador.muestrear(tInicial: 0, tFinal: 1, paso: 0),
        throwsArgumentError,
      );
    });

    test('rechaza un tiempo final anterior al inicial', () {
      expect(
        () => evaluador.muestrear(tInicial: 2, tFinal: 1, paso: 0.1),
        throwsArgumentError,
      );
    });
  });
}
