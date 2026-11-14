import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/config/cargador_referencia_abr.dart';
import 'package:predictor_saturacion_abr/core/engine/detector_colapso.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_entrada_trafico.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/engine/solucionador_analitico_general.dart';
import 'package:predictor_saturacion_abr/core/engine/solver_runge_kutta.dart';
import 'package:predictor_saturacion_abr/core/models/escenario_trafico.dart';
import 'package:predictor_saturacion_abr/core/models/punto_simulacion.dart';
import 'package:predictor_saturacion_abr/core/models/referencia_abr.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_general.dart';

import 'configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final referencia = CargadorReferenciaAbr.desdeJson(
    File('assets/config/referencia_abr.json').readAsStringSync(),
  );
  final sistema = cargarSistema();
  final escenarios = cargarEscenarios();
  final solucionador = SolucionadorAnaliticoGeneral(configuracion: sistema);
  const detector = DetectorColapso();

  EscenarioTrafico escenarioDe(String id) => escenarios.buscarPorId(id)!;

  EvaluadorSolucionAnalitica referenciaDe(CasoAbr caso) {
    return EvaluadorSolucionAnalitica(
      solucion: SolucionAnalitica(
        version: referencia.version,
        unidadTiempo: 'min',
        variable: 't',
        expresionX: caso.fase2.x!,
        expresionY: caso.fase2.y!,
      ),
    );
  }

  List<PuntoSimulacion> malla(SolucionGeneral solucion, double tiempoFinal) {
    final puntos = <PuntoSimulacion>[];
    for (var t = 0.0; t <= tiempoFinal + 1e-9; t += 0.01) {
      puntos.add(
        PuntoSimulacion(t: t, x: solucion.evaluarX(t), y: solucion.evaluarY(t)),
      );
    }
    return puntos;
  }

  final casosConSolucion = referencia.casos.where(
    (caso) => caso.fase2.x != null && caso.fase2.y != null,
  );

  for (final caso in casosConSolucion) {
    group('Referencia ABR · ${caso.id}', () {
      final escenario = escenarioDe(caso.id);
      final solucion = solucionador.resolver(escenario);
      final esperado = referenciaDe(caso);
      final tiempoFinal = escenario.tiempoMaxMin;

      test(
        'la analítica del motor coincide con la referencia (error < 1e-6)',
        () {
          expect(solucion.soportada, isTrue, reason: solucion.motivo);
          var errorMaximo = 0.0;
          for (var t = 0.0; t <= tiempoFinal + 1e-9; t += 0.25) {
            final errorX = (solucion.evaluarX(t) - esperado.evaluarX(t)).abs();
            final errorY = (solucion.evaluarY(t) - esperado.evaluarY(t)).abs();
            errorMaximo = math.max(errorMaximo, math.max(errorX, errorY));
          }
          expect(errorMaximo, lessThan(1e-6));
        },
      );

      test('la analítica coincide con RK4 (paso 0.01, error < 1e-3)', () {
        final entrada = EvaluadorEntradaTrafico(escenario: escenario);
        final numerica = SolucionadorRungeKutta(
          configuracion: sistema,
        ).resolver(entrada: entrada.evaluar, paso: 0.01, tFinal: tiempoFinal);
        var errorMaximo = 0.0;
        for (final punto in numerica.puntos) {
          final errorX = (solucion.evaluarX(punto.t) - punto.x).abs();
          final errorY = (solucion.evaluarY(punto.t) - punto.y).abs();
          errorMaximo = math.max(errorMaximo, math.max(errorX, errorY));
        }
        expect(errorMaximo, lessThan(1e-3));
      });

      test('respeta condiciones iniciales y derivadas iniciales', () {
        final coeficientes = sistema.coeficientes;
        final c1 = sistema.tanques.c1;
        final v1Inicial = solucion.evaluarV1(0);
        final x0 = caso.fase2.x0;
        final y0 = caso.fase2.y0;

        expect(solucion.evaluarX(0), closeTo(x0, 1e-9));
        expect(solucion.evaluarY(0), closeTo(y0, 1e-9));
        expect(
          solucion.evaluarDerivadaX(0),
          closeTo(
            c1 * v1Inicial + coeficientes.a11 * x0 + coeficientes.a12 * y0,
            1e-6,
          ),
        );
        expect(
          solucion.evaluarDerivadaY(0),
          closeTo(coeficientes.a21 * x0 + coeficientes.a22 * y0, 1e-6),
        );
      });

      test('colapso Web, colapso BD y ventana de acción', () {
        final e = caso.esperado!;
        final puntos = malla(solucion, tiempoFinal);
        final web = detector.detectar(
          tanque: 'capa_web',
          limite: sistema.capacidades.capaWeb,
          puntos: puntos,
          valor: (punto) => punto.x,
        );
        final bd = detector.detectar(
          tanque: 'base_datos',
          limite: sistema.capacidades.baseDatos,
          puntos: puntos,
          valor: (punto) => punto.y,
        );
        final ventana = detector.calcularVentanaAccion(
          colapsoCapaWeb: web,
          colapsoBaseDatos: bd,
          tiempoReaccion: sistema.tiempoReaccion,
        );

        expect(web.colapsa, isTrue);
        expect(bd.colapsa, isTrue);
        expect(web.tiempo!, closeTo(e.colapsoWebMin, e.toleranciaMin));
        expect(bd.tiempo!, closeTo(e.colapsoBdMin, e.toleranciaMin));
        expect(ventana.ventanaAccion!, closeTo(e.ventanaMin, e.toleranciaMin));
      });
    });
  }

  group('Referencia ABR · cíclico (pendiente)', () {
    final escenario = escenarioDe('ciclico');
    final solucion = solucionador.resolver(escenario);

    test('la analítica coincide con RK4 en 1440 min (error < 1e-3)', () {
      expect(solucion.soportada, isTrue, reason: solucion.motivo);
      final entrada = EvaluadorEntradaTrafico(escenario: escenario);
      final numerica = SolucionadorRungeKutta(configuracion: sistema).resolver(
        entrada: entrada.evaluar,
        paso: 0.01,
        tFinal: escenario.tiempoMaxMin,
      );
      var errorMaximo = 0.0;
      for (final punto in numerica.puntos) {
        if ((punto.t * 10).round() % 100 != 0) continue;
        final errorX = (solucion.evaluarX(punto.t) - punto.x).abs();
        final errorY = (solucion.evaluarY(punto.t) - punto.y).abs();
        errorMaximo = math.max(errorMaximo, math.max(errorX, errorY));
      }
      expect(errorMaximo, lessThan(1e-3));
    });

    test('detecta tráfico negativo dentro del horizonte', () {
      var minimo = double.infinity;
      for (var t = 0.0; t <= escenario.tiempoMaxMin; t += 1) {
        minimo = math.min(minimo, solucion.evaluarV1(t));
      }
      expect(minimo, lessThan(0));
    });
  });

  group('Parámetros de tanques', () {
    final escenario = escenarioDe('lineal');
    final base = solucionador.resolver(escenario);

    test('modo derivado por defecto produce los coeficientes del ABR', () {
      final coeficientes = sistema.coeficientes;
      expect(sistema.tanques.modoCoeficientes, 'derivado');
      expect(coeficientes.a11, closeTo(-0.3, 1e-9));
      expect(coeficientes.a12, closeTo(0.1, 1e-9));
      expect(coeficientes.a21, closeTo(0.2, 1e-9));
      expect(coeficientes.a22, closeTo(-0.4, 1e-9));
    });

    test('B_salida = 80 lleva a22 a -0.5', () {
      final tanques = sistema.tanques.copyWith(
        caudales: sistema.tanques.caudales.copyWith(bSalida: 80),
      );
      expect(calcularCoeficientesSistema(tanques).a22, closeTo(-0.5, 1e-9));
    });

    test('volumen_A = 200 reduce a11 y a21 a la mitad', () {
      final tanques = sistema.tanques.copyWith(volumenA: 200);
      final coeficientes = calcularCoeficientesSistema(tanques);
      expect(coeficientes.a11, closeTo(-0.15, 1e-9));
      expect(coeficientes.a21, closeTo(0.1, 1e-9));
    });

    test('c1 = 2 duplica x(t) e y(t) en el caso lineal', () {
      final doble = SolucionadorAnaliticoGeneral(
        configuracion: sistema.copyWith(
          tanques: sistema.tanques.copyWith(c1: 2),
        ),
      ).resolver(escenario);

      expect(doble.evaluarX(7), closeTo(2 * base.evaluarX(7), 1e-6));
      expect(doble.evaluarY(7), closeTo(2 * base.evaluarY(7), 1e-6));
    });

    test(
      'limite_A distinto de volumen_A cambia el colapso sin cambiar curvas',
      () {
        final conLimite = sistema.copyWith(
          tanques: sistema.tanques.copyWith(limiteA: 150),
        );
        final solucionLimite = SolucionadorAnaliticoGeneral(
          configuracion: conLimite,
        ).resolver(escenario);

        expect(solucionLimite.evaluarX(7), closeTo(base.evaluarX(7), 1e-9));

        final puntosBase = malla(base, escenario.tiempoMaxMin);
        final puntosLimite = malla(solucionLimite, escenario.tiempoMaxMin);
        final webBase = detector.detectar(
          tanque: 'capa_web',
          limite: sistema.capacidades.capaWeb,
          puntos: puntosBase,
          valor: (punto) => punto.x,
        );
        final webLimite = detector.detectar(
          tanque: 'capa_web',
          limite: conLimite.capacidades.capaWeb,
          puntos: puntosLimite,
          valor: (punto) => punto.x,
        );

        expect(webLimite.tiempo!, greaterThan(webBase.tiempo!));
      },
    );

    test(
      'modo directo con los mismos coeficientes da los mismos resultados',
      () {
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
        final solucionDirecta = SolucionadorAnaliticoGeneral(
          configuracion: directo,
        ).resolver(escenario);

        expect(solucionDirecta.evaluarX(7), closeTo(base.evaluarX(7), 1e-9));
        expect(solucionDirecta.evaluarY(7), closeTo(base.evaluarY(7), 1e-9));
      },
    );
  });
}
