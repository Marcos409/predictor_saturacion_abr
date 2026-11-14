import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/config/cargador_referencia_abr.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_expresiones.dart';
import 'package:predictor_saturacion_abr/core/models/referencia_abr.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/features/verificacion_abr/calculadora_verificacion_abr.dart';
import 'package:predictor_saturacion_abr/features/verificacion_abr/resultado_verificacion_abr.dart';

import '../../engine/configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sistema = cargarSistema();
  final escenarios = cargarEscenarios();
  final referencia = CargadorReferenciaAbr.desdeJson(
    File('assets/config/referencia_abr.json').readAsStringSync(),
  );
  final calculadora = CalculadoraVerificacionAbr();

  ResultadoVerificacionAbr calcular({
    required String id,
    ConfiguracionSistema? configuracion,
    ReferenciaAbr? referenciaAbr,
    double? umbral,
    double? tiempoMax,
    bool usarReferencia = true,
  }) {
    final base = escenarios.buscarPorId(id)!;
    return calculadora.calcular(
      escenario: tiempoMax == null
          ? base
          : base.copyWith(tiempoMaxMin: tiempoMax),
      configuracion: configuracion ?? sistema,
      referencia: usarReferencia ? (referenciaAbr ?? referencia) : null,
      umbralComparacion: umbral ?? sistema.verificacion.umbralError,
    );
  }

  test('el caso lineal coincide con la referencia del ABR', () {
    final resultado = calcular(id: 'lineal');

    expect(resultado.solucion.soportada, isTrue);
    expect(resultado.horizonteMin, 30);
    expect(resultado.comparacion, hasLength(2));
    expect(resultado.notaComparacion, isNull);

    for (final fila in resultado.comparacion) {
      expect(fila.referenciaPendiente, isFalse, reason: fila.variable);
      expect(fila.estado, EstadoComparacionAbr.coincide, reason: fila.variable);
      expect(
        fila.errorMaximo,
        lessThanOrEqualTo(sistema.verificacion.umbralError),
        reason: fila.variable,
      );
    }

    final esperado = referencia.buscarCasoPorId('lineal')!.esperado!;
    expect(
      resultado.colapsoWeb.tiempo,
      closeTo(esperado.colapsoWebMin, esperado.toleranciaMin),
    );
    expect(
      resultado.colapsoBd.tiempo,
      closeTo(esperado.colapsoBdMin, esperado.toleranciaMin),
    );
    expect(
      resultado.ventana.ventanaAccion,
      closeTo(esperado.ventanaMin, esperado.toleranciaMin),
    );
  });

  test(
    'detecta diferencias cuando cambia c1 y las acepta con umbral amplio',
    () {
      final alterado = sistema.copyWith(
        tanques: sistema.tanques.copyWith(c1: 2),
      );
      final estricto = calcular(id: 'lineal', configuracion: alterado);
      final amplio = calcular(
        id: 'lineal',
        configuracion: alterado,
        umbral: 1000000,
      );

      expect(
        estricto.comparacion.every(
          (fila) => fila.estado == EstadoComparacionAbr.difiere,
        ),
        isTrue,
      );
      expect(
        estricto.comparacion.every(
          (fila) => fila.errorMaximo! > sistema.verificacion.umbralError,
        ),
        isTrue,
      );
      expect(amplio.comparacion.every((fila) => fila.coincide), isTrue);
    },
  );

  test('sin referencia compara contra RK4 y marca la fila como pendiente', () {
    final resultado = calcular(id: 'lineal', usarReferencia: false);

    expect(resultado.notaComparacion, contains('No se pudo leer'));
    expect(resultado.comparacion, hasLength(2));
    for (final fila in resultado.comparacion) {
      expect(fila.referenciaPendiente, isTrue);
      expect(fila.ecuacionReferencia, 'Referencia pendiente');
      expect(fila.coincide, isTrue);
    }
  });

  test('usa RK4 cuando el escenario no existe en la referencia', () {
    final parcial = ReferenciaAbr(
      version: referencia.version,
      nota: referencia.nota,
      tanques: referencia.tanques,
      casos: [referencia.buscarCasoPorId('constante')!],
    );
    final resultado = calcular(id: 'lineal', referenciaAbr: parcial);

    expect(resultado.notaComparacion, contains('No hay caso de referencia'));
    expect(
      resultado.comparacion.every((fila) => fila.referenciaPendiente),
      isTrue,
    );
    expect(resultado.comparacion.every((fila) => fila.coincide), isTrue);
  });

  test('el caso cíclico sin ecuaciones de referencia usa RK4', () {
    final resultado = calcular(id: 'ciclico', tiempoMax: 120);

    expect(resultado.horizonteMin, 120);
    expect(resultado.notaComparacion, contains('Referencia pendiente'));
    expect(
      resultado.comparacion.every((fila) => fila.referenciaPendiente),
      isTrue,
    );
    expect(resultado.limiteX, 'Acotado (oscila)');
    expect(resultado.limiteY, 'Acotado (oscila)');
  });

  test('rechaza un umbral de comparación negativo', () {
    expect(
      () => calcular(id: 'lineal', umbral: -0.1),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('umbral'),
        ),
      ),
    );
  });

  test(
    'usa el tiempo final configurado si el escenario no define horizonte',
    () {
      final resultado = calcular(id: 'lineal', tiempoMax: 0);

      expect(resultado.horizonteMin, sistema.simulacion.tiempoFinal);
    },
  );

  test('propaga el motivo cuando el motor no soporta el sistema', () {
    final singular = sistema.copyWith(
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

    expect(
      () => calcular(id: 'lineal', configuracion: singular),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('a21'),
        ),
      ),
    );
  });

  test('informa el método de Fase 1 de cada escenario', () {
    const metodos = {
      'lineal': 'Integración directa',
      'constante': 'Integración directa',
      'exponencial': 'Transformada de Laplace',
      'ciclico': 'EDO homogénea de 2.º orden',
    };

    for (final entrada in metodos.entries) {
      final resultado = calcular(
        id: entrada.key,
        tiempoMax: entrada.key == 'ciclico' ? 60 : null,
      );
      expect(resultado.metodoFase1, entrada.value);
      expect(resultado.edoFase1, isNotEmpty);
    }
  });

  test('calcula los límites asintóticos de cada escenario', () {
    expect(calcular(id: 'lineal').limiteX, '+∞');
    expect(calcular(id: 'lineal').limiteY, '+∞');

    final constante = calcular(id: 'constante');
    expect(constante.limiteX, '2000');
    expect(constante.limiteY, '1000');

    final exponencial = calcular(id: 'exponencial');
    expect(exponencial.limiteX, '+∞');
    expect(exponencial.limiteY, '+∞');
  });

  test(
    'las expresiones derivadas y Yp son evaluables y equivalen al motor',
    () {
      final resultado = calcular(id: 'lineal');
      final evaluador = EvaluadorExpresiones();

      for (final t in [0.0, 1.5, 7.0]) {
        expect(
          evaluador.evaluar(resultado.expresionV1, {'t': t}),
          closeTo(resultado.solucion.evaluarV1(t), 1e-9),
        );
        expect(
          evaluador.evaluar(resultado.expresionXPrima, {'t': t}),
          closeTo(resultado.solucion.evaluarDerivadaX(t), 1e-9),
        );
        expect(
          evaluador.evaluar(resultado.expresionYPrima, {'t': t}),
          closeTo(resultado.solucion.evaluarDerivadaY(t), 1e-9),
        );
      }

      expect(
        evaluador.evaluar(resultado.expresionYp, {'t': 7}),
        closeTo(20, 1e-9),
      );
      expect(resultado.expresionYc, contains('Yc(t)'));
      expect(resultado.c1Homogenea, isNotNull);
      expect(resultado.c2Homogenea, isNotNull);
    },
  );
}
