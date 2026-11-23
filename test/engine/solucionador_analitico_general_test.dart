import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_entrada_trafico.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/engine/solucionador_analitico_general.dart';
import 'package:predictor_saturacion_abr/core/engine/solver_runge_kutta.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_general.dart';

import 'configuracion_prueba.dart';

void main() {
  final sistema = cargarSistema();
  final escenarios = cargarEscenarios();
  final solucionador = SolucionadorAnaliticoGeneral(configuracion: sistema);

  group('Solución analítica general · caso lineal', () {
    final escenario = escenarios.buscarPorId('lineal')!;
    final solucion = solucionador.resolver(escenario);

    test('devuelve una solución soportada', () {
      expect(solucion.soportada, isTrue);
      expect(solucion.motivo, isNull);
      expect(solucion.terminosX, isNotEmpty);
      expect(solucion.terminosY, isNotEmpty);
    });

    test('respeta las condiciones iniciales', () {
      expect(solucion.evaluarX(0), closeTo(0, 1e-9));
      expect(solucion.evaluarY(0), closeTo(0, 1e-9));
    });

    test('coincide con la referencia del ABR', () {
      const t = 7.0;
      final x = -50 + 20 * t + 50 * math.exp(-0.2 * t);
      final y = -50 + 10 * t + 50 * math.exp(-0.2 * t);
      expect(solucion.evaluarX(t), closeTo(x, 1e-6));
      expect(solucion.evaluarY(t), closeTo(y, 1e-6));
    });

    test('expone los pasos intermedios', () {
      expect(solucion.pasos.edo, contains('y'));
      expect(solucion.pasos.r1!, closeTo(-0.2, 1e-9));
      expect(solucion.pasos.r2!, closeTo(-0.5, 1e-9));
      expect(solucion.pasos.c1Homogenea!, closeTo(50, 1e-6));
      expect(solucion.pasos.c2Homogenea!, closeTo(0, 1e-6));
      expect(solucion.pasos.coeficientesParticulares, isNotEmpty);
    });

    test('la expresión generada es evaluable con el evaluador del Lote 2', () {
      final evaluador = EvaluadorSolucionAnalitica(
        solucion: solucion.aSolucionAnalitica(version: 1, unidadTiempo: 'min'),
      );
      expect(evaluador.evaluarX(7), closeTo(solucion.evaluarX(7), 1e-6));
      expect(evaluador.evaluarY(7), closeTo(solucion.evaluarY(7), 1e-6));
    });
  });

  test('escala linealmente con c1', () {
    final escenario = escenarios.buscarPorId('lineal')!;
    final base = solucionador.resolver(escenario);
    final doble = SolucionadorAnaliticoGeneral(
      configuracion: sistema.copyWith(tanques: sistema.tanques.copyWith(c1: 2)),
    ).resolver(escenario);

    expect(doble.evaluarX(7), closeTo(2 * base.evaluarX(7), 1e-6));
    expect(doble.evaluarY(7), closeTo(2 * base.evaluarY(7), 1e-6));
  });

  group('coincide con el solver numérico', () {
    for (final id in ['lineal', 'constante', 'exponencial', 'ciclico']) {
      test('escenario $id', () {
        final escenario = escenarios.buscarPorId(id)!;
        final analitica = solucionador.resolver(escenario);
        expect(analitica.soportada, isTrue, reason: analitica.motivo);

        final entrada = EvaluadorEntradaTrafico(escenario: escenario);
        final numerica = SolucionadorRungeKutta(
          configuracion: sistema,
        ).resolver(entrada: entrada.evaluar, paso: 0.001, tFinal: 5);

        for (final tiempo in [1.0, 2.5, 5.0]) {
          final punto = numerica.puntos.firstWhere(
            (punto) => (punto.t - tiempo).abs() < 1e-9,
          );
          expect(
            analitica.evaluarX(tiempo),
            closeTo(punto.x, 1e-4),
            reason: 'x en $id($tiempo)',
          );
          expect(
            analitica.evaluarY(tiempo),
            closeTo(punto.y, 1e-4),
            reason: 'y en $id($tiempo)',
          );
        }
      });
    }
  });

  group('casos no soportados', () {
    test('raíces complejas devuelven estado sin lanzar excepción', () {
      final sistemaComplejo = sistema.copyWith(
        tanques: sistema.tanques.copyWith(
          modoCoeficientes: 'directo',
          coeficientesDirectos: const CoeficientesSistema(
            a11: 0,
            a12: 1,
            a21: -1,
            a22: 0,
          ),
        ),
      );
      final escenario = escenarios.buscarPorId('lineal')!;
      final solucion = SolucionadorAnaliticoGeneral(
        configuracion: sistemaComplejo,
      ).resolver(escenario);

      expect(solucion.soportada, isFalse);
      expect(solucion.motivo, isNotNull);
      expect(solucion.terminosX, isEmpty);
      expect(solucion.terminosY, isEmpty);
    });

    test('a21 = 0 devuelve estado sin lanzar excepción', () {
      final sistemaSingular = sistema.copyWith(
        tanques: sistema.tanques.copyWith(
          modoCoeficientes: 'directo',
          coeficientesDirectos: const CoeficientesSistema(
            a11: -1,
            a12: 0,
            a21: 0,
            a22: -2,
          ),
        ),
      );
      final escenario = escenarios.buscarPorId('lineal')!;
      final solucion = SolucionadorAnaliticoGeneral(
        configuracion: sistemaSingular,
      ).resolver(escenario);

      expect(solucion.soportada, isFalse);
      expect(solucion.motivo, contains('a21'));
    });
  });

  group('condiciones iniciales no nulas', () {
    final conIniciales = sistema.copyWith(
      condicionesIniciales: const CondicionesIniciales(x0: 3, y0: 4),
    );
    final coeficientes = conIniciales.coeficientes;

    for (final id in ['lineal', 'constante', 'exponencial', 'ciclico']) {
      test('escenario $id', () {
        final escenario = escenarios.buscarPorId(id)!;
        final solucion = SolucionadorAnaliticoGeneral(
          configuracion: conIniciales,
        ).resolver(escenario);

        expect(solucion.soportada, isTrue, reason: solucion.motivo);
        expect(solucion.evaluarX(0), closeTo(3, 1e-9));
        expect(solucion.evaluarY(0), closeTo(4, 1e-9));

        final derivadaXEsperada =
            coeficientes.a11 * 3 +
            coeficientes.a12 * 4 +
            conIniciales.tanques.c1 * solucion.evaluarV1(0);
        final derivadaYEsperada = coeficientes.a21 * 3 + coeficientes.a22 * 4;

        expect(solucion.evaluarDerivadaX(0), closeTo(derivadaXEsperada, 1e-6));
        expect(solucion.evaluarDerivadaY(0), closeTo(derivadaYEsperada, 1e-6));
      });
    }
  });

  group('V1 del solver coincide con la expresión del escenario', () {
    for (final id in ['lineal', 'constante', 'exponencial', 'ciclico']) {
      test('escenario $id', () {
        final escenario = escenarios.buscarPorId(id)!;
        final solucion = solucionador.resolver(escenario);
        final entrada = EvaluadorEntradaTrafico(escenario: escenario);

        for (final t in [0.0, 1.0, 2.5, 7.0]) {
          expect(
            solucion.evaluarV1(t),
            closeTo(entrada.evaluar(t), 1e-9),
            reason: 'V1 en $id($t)',
          );
        }
      });
    }
  });

  test('resuelve la exponencial cuando r coincide con una raíz', () {
    final base = escenarios.buscarPorId('exponencial')!;
    final raiz = solucionador
        .resolver(escenarios.buscarPorId('lineal')!)
        .pasos
        .r1!;
    final resonante = base.copyWith(
      parametros: [
        for (final parametro in base.parametros)
          parametro.copyWith(
            valor: parametro.clave == 'r' ? raiz : parametro.valor,
          ),
      ],
    );

    final analitica = solucionador.resolver(resonante);
    expect(analitica.soportada, isTrue, reason: analitica.motivo);
    expect(
      analitica.terminosY.any(
        (termino) => termino.tipo == TipoTermino.exponencialLineal,
      ),
      isTrue,
    );

    final entrada = EvaluadorEntradaTrafico(escenario: resonante);
    final numerica = SolucionadorRungeKutta(
      configuracion: sistema,
    ).resolver(entrada: entrada.evaluar, paso: 0.001, tFinal: 5);

    for (final tiempo in [1.0, 2.5, 5.0]) {
      final punto = numerica.puntos.firstWhere(
        (punto) => (punto.t - tiempo).abs() < 1e-9,
      );
      expect(
        analitica.evaluarX(tiempo),
        closeTo(punto.x, 1e-4),
        reason: 'x resonante en $tiempo',
      );
      expect(
        analitica.evaluarY(tiempo),
        closeTo(punto.y, 1e-4),
        reason: 'y resonante en $tiempo',
      );
    }
  });

  test('raíces reales repetidas devuelven estado sin soporte', () {
    final repetido = sistema.copyWith(
      tanques: sistema.tanques.copyWith(
        modoCoeficientes: 'directo',
        coeficientesDirectos: const CoeficientesSistema(
          a11: -1,
          a12: 0,
          a21: 0.1,
          a22: -1,
        ),
      ),
    );
    final solucion = SolucionadorAnaliticoGeneral(
      configuracion: repetido,
    ).resolver(escenarios.buscarPorId('lineal')!);

    expect(solucion.soportada, isFalse);
    expect(solucion.motivo, contains('discriminante'));
  });

  group('parámetros inválidos y casos límite del escenario', () {
    test('exponencial con r = 0 equivale al lineal con m = q', () {
      final base = escenarios.buscarPorId('exponencial')!;
      final cero = base.copyWith(
        parametros: [
          for (final parametro in base.parametros)
            parametro.copyWith(
              valor: parametro.clave == 'r' ? 0 : parametro.valor,
            ),
        ],
      );
      final resultado = solucionador.resolver(cero);
      final p0 = cero.mapaParametros['P0']!;
      final q = cero.mapaParametros['b']!;

      expect(resultado.soportada, isTrue, reason: resultado.motivo);
      expect(resultado.evaluarV1(0), closeTo(p0, 1e-12));
      expect(resultado.evaluarV1(7), closeTo(p0 + q * 7, 1e-12));

      final baseLineal = escenarios.buscarPorId('lineal')!;
      final linealEquivalente = baseLineal.copyWith(
        parametros: [
          for (final parametro in baseLineal.parametros)
            parametro.copyWith(
              valor: parametro.clave == 'P0' ? p0 : q,
            ),
        ],
      );
      final referencia = solucionador.resolver(linealEquivalente);
      expect(resultado.evaluarX(7), closeTo(referencia.evaluarX(7), 1e-6));
      expect(resultado.evaluarY(7), closeTo(referencia.evaluarY(7), 1e-6));

      final entrada = EvaluadorEntradaTrafico(escenario: cero);
      final numerica = SolucionadorRungeKutta(
        configuracion: sistema,
      ).resolver(entrada: entrada.evaluar, paso: 0.001, tFinal: 5);
      for (final tiempo in [1.0, 2.5, 5.0]) {
        final punto = numerica.puntos.firstWhere(
          (punto) => (punto.t - tiempo).abs() < 1e-9,
        );
        expect(resultado.evaluarX(tiempo), closeTo(punto.x, 1e-4));
        expect(resultado.evaluarY(tiempo), closeTo(punto.y, 1e-4));
      }
    });

    test('cíclico con periodo cero', () {
      final base = escenarios.buscarPorId('ciclico')!;
      final invalido = base.copyWith(
        parametros: [
          for (final parametro in base.parametros)
            parametro.copyWith(
              valor: parametro.clave == 'periodo_min' ? 0 : parametro.valor,
            ),
        ],
      );

      expect(() => solucionador.resolver(invalido), throwsFormatException);
    });

    test('falta un parámetro requerido', () {
      final base = escenarios.buscarPorId('lineal')!;
      final invalido = base.copyWith(
        parametros: base.parametros
            .where((parametro) => parametro.clave != 'm')
            .toList(),
      );

      expect(() => solucionador.resolver(invalido), throwsFormatException);
    });
  });
}
