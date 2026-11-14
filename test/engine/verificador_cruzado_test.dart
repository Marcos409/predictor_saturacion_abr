import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_entrada_trafico.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/engine/solver_runge_kutta.dart';
import 'package:predictor_saturacion_abr/core/engine/verificador_cruzado.dart';
import 'package:predictor_saturacion_abr/core/models/punto_simulacion.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_analitica.dart';

import 'configuracion_prueba.dart';

void main() {
  group('VerificadorCruzado', () {
    const verificador = VerificadorCruzado();
    final sistema = cargarSistema();
    final escenario = cargarEscenarios().buscarPorId('lineal')!;
    final entrada = EvaluadorEntradaTrafico(escenario: escenario);
    final resultado = SolucionadorRungeKutta(
      configuracion: sistema,
    ).resolver(entrada: entrada.evaluar, paso: 0.01, tFinal: 30);
    final analitica = EvaluadorSolucionAnalitica.desdeJson(
      leerSolucionAnaliticaCruda(),
    );

    test('el caso base no presenta discrepancia', () {
      final verificacion = verificador.verificar(
        puntosNumericos: resultado.puntos,
        analitica: analitica,
        umbral: 0.01,
      );
      expect(verificacion.hayDiscrepancia, isFalse);
      expect(verificacion.errorMaximo, lessThan(0.01));
      expect(verificacion.cantidadPuntos, resultado.puntos.length);
    });

    test(
      'un coeficiente alterado en la solución analítica genera discrepancia',
      () {
        final original = cargarSolucionAnalitica();
        final alterada = SolucionAnalitica(
          version: original.version,
          unidadTiempo: original.unidadTiempo,
          variable: original.variable,
          expresionX: original.expresionX.replaceFirst('20*t', '25*t'),
          expresionY: original.expresionY,
        );
        final analiticaAlterada = EvaluadorSolucionAnalitica(
          solucion: alterada,
        );

        final verificacion = verificador.verificar(
          puntosNumericos: resultado.puntos,
          analitica: analiticaAlterada,
          umbral: 0.01,
        );
        expect(verificacion.hayDiscrepancia, isTrue);
        expect(verificacion.errorMaximo, greaterThan(0.01));
      },
    );

    test('acumula el error máximo por componente y su instante', () {
      const analiticaSimple = SolucionAnalitica(
        version: 1,
        unidadTiempo: 'min',
        variable: 't',
        expresionX: 't',
        expresionY: '2*t',
      );
      final evaluador = EvaluadorSolucionAnalitica(solucion: analiticaSimple);
      const puntos = [
        PuntoSimulacion(t: 0, x: 0, y: 0),
        PuntoSimulacion(t: 1, x: 3, y: 2),
        PuntoSimulacion(t: 2, x: 2, y: 6),
      ];

      final verificacion = verificador.verificar(
        puntosNumericos: puntos,
        analitica: evaluador,
        umbral: 3,
      );

      expect(verificacion.errorMaximoX, closeTo(2, 1e-12));
      expect(verificacion.errorMaximoY, closeTo(2, 1e-12));
      expect(verificacion.errorMaximo, closeTo(2, 1e-12));
      expect(verificacion.tiempoErrorMaximo, 1);
      expect(verificacion.cantidadPuntos, puntos.length);
      expect(verificacion.hayDiscrepancia, isFalse);
    });

    test('marca discrepancia cuando el error supera el umbral', () {
      const analiticaSimple = SolucionAnalitica(
        version: 1,
        unidadTiempo: 'min',
        variable: 't',
        expresionX: '0',
        expresionY: '0',
      );
      final evaluador = EvaluadorSolucionAnalitica(solucion: analiticaSimple);
      const puntos = [PuntoSimulacion(t: 1, x: 2, y: 0)];

      final verificacion = verificador.verificar(
        puntosNumericos: puntos,
        analitica: evaluador,
        umbral: 1,
      );

      expect(verificacion.errorMaximo, 2);
      expect(verificacion.hayDiscrepancia, isTrue);
    });

    test('rechaza un umbral negativo', () {
      expect(
        () => verificador.verificar(
          puntosNumericos: resultado.puntos,
          analitica: analitica,
          umbral: -1,
        ),
        throwsArgumentError,
      );
    });

    test('rechaza una lista de puntos vacía', () {
      expect(
        () => verificador.verificar(
          puntosNumericos: const [],
          analitica: analitica,
          umbral: 0.01,
        ),
        throwsArgumentError,
      );
    });

    test('el umbral es configurable', () {
      final original = cargarSolucionAnalitica();
      final alterada = SolucionAnalitica(
        version: original.version,
        unidadTiempo: original.unidadTiempo,
        variable: original.variable,
        expresionX: original.expresionX.replaceFirst('20*t', '25*t'),
        expresionY: original.expresionY,
      );
      final analiticaAlterada = EvaluadorSolucionAnalitica(solucion: alterada);

      final verificacion = verificador.verificar(
        puntosNumericos: resultado.puntos,
        analitica: analiticaAlterada,
        umbral: 1000,
      );
      expect(verificacion.hayDiscrepancia, isFalse);
      expect(verificacion.umbral, 1000);
    });
  });
}
