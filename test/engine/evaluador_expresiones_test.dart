import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_expresiones.dart';

void main() {
  group('EvaluadorExpresiones', () {
    final evaluador = EvaluadorExpresiones();

    test('evalúa operaciones y la variable t', () {
      expect(evaluador.evaluar('10 + 5*t', {'t': 2}), closeTo(20, 1e-12));
    });

    test('evalúa parámetros con nombre', () {
      final valor = evaluador.evaluar('P0 + m*t', {'P0': 10, 'm': 5, 't': 4});
      expect(valor, closeTo(30, 1e-12));
    });

    test('evalúa exp, sin y cos', () {
      expect(
        evaluador.evaluar('50*exp(-0.2*t)', {'t': 7}),
        closeTo(50 * 0.2465969639416065, 1e-9),
      );
      expect(evaluador.evaluar('sin(pi/2)', {}), closeTo(1, 1e-12));
      expect(evaluador.evaluar('cos(0)', {}), closeTo(1, 1e-12));
    });

    test('normaliza exp con mayúsculas y espacios', () {
      final valor = evaluador.evaluar('EXP (0) + exp(0)', {});
      expect(valor, closeTo(2, 1e-12));
    });

    test('evalúa la constante pi', () {
      expect(evaluador.evaluar('pi', {}), closeTo(3.141592653589793, 1e-12));
    });

    test('reutiliza expresiones ya analizadas', () {
      final primera = evaluador.evaluar('2*t', {'t': 3});
      final segunda = evaluador.evaluar('2*t', {'t': 3});
      expect(primera, segunda);
    });

    test('compila una función de entrada reutilizable', () {
      final funcion = evaluador.compilarEntrada('P0 + m*t', {'P0': 10, 'm': 5});

      expect(funcion(0), closeTo(10, 1e-12));
      expect(funcion(2), closeTo(20, 1e-12));
      expect(funcion(4), closeTo(30, 1e-12));
    });

    test('compila usando otra variable de tiempo', () {
      final funcion = evaluador.compilarEntrada('a + b*x', {
        'a': 1,
        'b': 2,
      }, variableTiempo: 'x');

      expect(funcion(3), closeTo(7, 1e-12));
    });

    test('lanza un error ante una expresión inválida', () {
      expect(() => evaluador.evaluar('P0 +', {'P0': 1}), throwsA(anything));
    });
  });
}
