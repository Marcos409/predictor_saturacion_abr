import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_entrada_trafico.dart';
import 'package:predictor_saturacion_abr/core/models/escenario_trafico.dart';
import 'package:predictor_saturacion_abr/core/models/parametro_escenario.dart';

import 'configuracion_prueba.dart';

void main() {
  group('EvaluadorEntradaTrafico', () {
    final escenarios = cargarEscenarios();

    test('evalúa la expresión de cada escenario', () {
      const omega = 2 * math.pi / 1440;
      final esperados = <String, double>{
        'lineal': 20,
        'constante': 500,
        'exponencial': -200 + 210 * math.exp(0.1),
        'ciclico':
            10 * math.cos(omega * 2) + (20 / omega) * math.sin(omega * 2),
      };

      for (final entrada in esperados.entries) {
        final escenario = escenarios.buscarPorId(entrada.key)!;
        final evaluador = EvaluadorEntradaTrafico(escenario: escenario);
        expect(
          evaluador.evaluar(2),
          closeTo(entrada.value, 1e-9),
          reason: 'Escenario ${entrada.key}',
        );
      }
    });

    test('usa los parámetros actualizados del escenario', () {
      final original = escenarios.buscarPorId('lineal')!;
      final parametros = original.parametros.map((parametro) {
        if (parametro.clave != 'm') return parametro;
        return parametro.copyWith(valor: 8);
      }).toList();
      final escenario = original.copyWith(parametros: parametros);
      final evaluador = EvaluadorEntradaTrafico(escenario: escenario);

      expect(evaluador.evaluar(0), closeTo(10, 1e-12));
      expect(evaluador.evaluar(2), closeTo(26, 1e-12));
    });

    test('interpreta exp sin distinguir mayúsculas', () {
      const escenario = EscenarioTrafico(
        id: 'prueba',
        nombre: 'Prueba',
        edo: 'v1(t) = P0*EXP(r*t) + b',
        parametros: [
          ParametroEscenario(clave: 'P0', nombre: 'P0', valor: 2),
          ParametroEscenario(clave: 'r', nombre: 'r', valor: 0),
          ParametroEscenario(clave: 'b', nombre: 'b', valor: 3),
        ],
        expresionV1: 'P0*EXP(r*t) + b',
        tiempoMaxMin: 30,
      );
      final evaluador = EvaluadorEntradaTrafico(escenario: escenario);

      expect(evaluador.evaluar(5), closeTo(5, 1e-12));
    });
  });
}
