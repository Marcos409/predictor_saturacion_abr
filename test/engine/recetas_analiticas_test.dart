import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_entrada_trafico.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/engine/solucionador_analitico_general.dart';
import 'package:predictor_saturacion_abr/core/engine/solver_runge_kutta.dart';
import 'package:predictor_saturacion_abr/core/engine/verificador_cruzado.dart';
import 'package:predictor_saturacion_abr/core/models/escenario_trafico.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_verificacion.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_general.dart';

import 'configuracion_prueba.dart';

void main() {
  final sistema = cargarSistema();
  final escenarios = cargarEscenarios();
  final solucionador = SolucionadorAnaliticoGeneral(configuracion: sistema);

  EscenarioTrafico escenarioCon(
    String id,
    Map<String, double> cambios, {
    double? tiempoMaxMin,
  }) {
    final base = escenarios.buscarPorId(id)!;
    return base.copyWith(
      parametros: [
        for (final parametro in base.parametros)
          parametro.copyWith(
            valor: cambios[parametro.clave] ?? parametro.valor,
          ),
      ],
      tiempoMaxMin: tiempoMaxMin ?? base.tiempoMaxMin,
    );
  }

  void verificarConRK4(
    EscenarioTrafico escenario, {
    ConfiguracionSistema? configuracion,
    double tFinal = 5,
    double umbral = 1e-6,
  }) {
    final sistemaUsado = configuracion ?? sistema;
    final analitica = SolucionadorAnaliticoGeneral(
      configuracion: sistemaUsado,
    ).resolver(escenario);
    expect(analitica.soportada, isTrue, reason: analitica.motivo);

    final numerica = SolucionadorRungeKutta(
      configuracion: sistemaUsado,
    ).resolver(
      entrada: EvaluadorEntradaTrafico(escenario: escenario).evaluar,
      paso: 0.001,
      tFinal: tFinal,
    );
    final comparacion = const VerificadorCruzado().verificar(
      puntosNumericos: numerica.puntos,
      analitica: EvaluadorSolucionGeneral(solucion: analitica),
      umbral: umbral,
    );

    expect(comparacion.estado, EstadoVerificacion.coincide, reason: escenario.id);
    expect(comparacion.errorRelativo, lessThan(umbral), reason: escenario.id);
  }

  group('recetas de los escenarios', () {
    test('constante expone K, C1 y C2 del caso base', () {
      final solucion = solucionador.resolver(escenarios.buscarPorId('constante')!);
      final coeficientes = solucion.pasos.coeficientesParticulares;

      expect(coeficientes['K'], closeTo(1000, 1e-6));
      expect(solucion.pasos.c1Homogenea, closeTo(-5000 / 3, 1e-6));
      expect(solucion.pasos.c2Homogenea, closeTo(2000 / 3, 1e-6));
      expect(solucion.evaluarY(0), closeTo(0, 1e-9));
    });

    test('exponencial expone K0, K1, A0, A1, C1 y C2 del caso base', () {
      final solucion = solucionador.resolver(
        escenarios.buscarPorId('exponencial')!,
      );
      final coeficientes = solucion.pasos.coeficientesParticulares;

      expect(solucion.evaluarV1(0), closeTo(10, 1e-9));
      expect(coeficientes['A0'], closeTo(-400, 1e-6));
      expect(coeficientes['A1'], closeTo(3360 / 11, 1e-6));
      expect(coeficientes['B'], closeTo(3360 / 11, 1e-6));
      expect(coeficientes['tasa'], closeTo(0.05, 1e-12));
      expect(solucion.pasos.c1Homogenea, closeTo(320 / 3, 1e-6));
      expect(solucion.pasos.c2Homogenea, closeTo(-400 / 33, 1e-6));
    });

    test('cíclico expone w, M, N, C1 y C2 del caso base', () {
      final escenario = escenarios.buscarPorId('ciclico')!;
      final solucion = solucionador.resolver(escenario);
      final coeficientes = solucion.pasos.coeficientesParticulares;
      final omega = 2 * 3.141592653589793 / 1440;

      expect(coeficientes['M'], closeTo(-259.8603244571026, 1e-6));
      expect(coeficientes['N'], closeTo(9161.131890367518, 1e-4));
      expect(coeficientes['A'], closeTo(coeficientes['M']!, 1e-12));
      expect(coeficientes['B'], closeTo(coeficientes['N']!, 1e-12));
      expect(solucion.pasos.c1Homogenea, closeTo(299.8572785148665, 1e-6));
      expect(solucion.pasos.c2Homogenea, closeTo(-39.996954057763936, 1e-6));
      expect(solucion.evaluarV1(0), closeTo(10, 1e-9));
      expect(solucion.evaluarV1(720), closeTo(-10, 1e-6));
      expect(omega, closeTo(3.141592653589793 / 720, 1e-12));
    });
  });

  group('parámetros modificados', () {
    test('exponencial con r = -0.5 es resonante y coincide con RK4', () {
      final escenario = escenarioCon('exponencial', {'r': -0.5});
      final solucion = solucionador.resolver(escenario);

      expect(solucion.soportada, isTrue, reason: solucion.motivo);
      expect(
        solucion.terminosY.any(
          (termino) => termino.tipo == TipoTermino.exponencialLineal,
        ),
        isTrue,
      );
      verificarConRK4(escenario);
    });

    for (final periodo in [60.0, 720.0]) {
      test('cíclico con periodo $periodo coincide con RK4', () {
        final escenario = escenarioCon(
          'ciclico',
          {'P0': 25, 'dP0': -15, 'periodo_min': periodo},
          tiempoMaxMin: periodo * 4,
        );
        verificarConRK4(escenario, tFinal: periodo * 4);
      });
    }

    test('cambiar P0 y q mantiene la coincidencia en exponencial', () {
      verificarConRK4(escenarioCon('exponencial', {'P0': 35, 'b': -6}));
    });

    test('cambiar P0 mantiene la coincidencia en constante', () {
      verificarConRK4(escenarioCon('constante', {'P0': 750}));
    });
  });

  group('casos no soportados sin excepción', () {
    test('b = 0 devuelve no soportado', () {
      final sistemaB = sistema.copyWith(
        tanques: sistema.tanques.copyWith(
          modoCoeficientes: 'directo',
          coeficientesDirectos: const CoeficientesSistema(
            a11: -0.2,
            a12: 0,
            a21: 0.2,
            a22: 0,
          ),
        ),
      );

      final solucion = SolucionadorAnaliticoGeneral(
        configuracion: sistemaB,
      ).resolver(escenarios.buscarPorId('constante')!);

      expect(solucion.soportada, isFalse);
      expect(solucion.motivo, contains('b = 0'));
      expect(solucion.terminosX, isEmpty);
      expect(solucion.terminosY, isEmpty);
    });
  });
}
