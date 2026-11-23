import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/config/cargador_referencia_abr.dart';
import 'package:predictor_saturacion_abr/core/models/referencia_abr.dart';
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

  ResultadoVerificacionAbr calcular(String id, {ReferenciaAbr? referenciaAbr}) {
    return calculadora.calcular(
      escenario: escenarios.buscarPorId(id)!,
      configuracion: sistema,
      referencia: referenciaAbr ?? referencia,
      umbralComparacion: sistema.verificacion.umbralError,
    );
  }

  void esperarControl(
    ResultadoVerificacionAbr resultado, {
    required double web,
    required double bd,
    required double ventana,
    double tolerancia = 0.1,
  }) {
    expect(
      resultado.colapsoWeb.tiempo,
      closeTo(web, tolerancia),
      reason: 'colapso web',
    );
    expect(
      resultado.colapsoBd.tiempo,
      closeTo(bd, tolerancia),
      reason: 'colapso base de datos',
    );
    expect(
      resultado.ventana.ventanaAccion,
      closeTo(ventana, tolerancia),
      reason: 'ventana',
    );
  }

  test('reconfirma los valores de control base del caso lineal', () {
    final resultado = calcular('lineal');

    expect(resultado.notaComparacion, isNull);
    expect(
      resultado.comparacion.every((fila) => fila.coincide),
      isTrue,
    );
    esperarControl(resultado, web: 6.86, bd: 24.97, ventana: -3.1);
  });

  for (final id in ['constante', 'exponencial']) {
    test('$id se compara con su ecuación de referencia', () {
      final resultado = calcular(id);
      final caso = referencia.buscarCasoPorId(id)!;

      expect(resultado.notaComparacion, isNull, reason: id);
      expect(resultado.comparacion, hasLength(2), reason: id);
      for (final fila in resultado.comparacion) {
        expect(fila.referenciaPendiente, isFalse, reason: fila.variable);
        expect(fila.coincide, isTrue, reason: fila.variable);
        expect(
          fila.ecuacionReferencia,
          anyOf(equals(caso.fase2.x), equals(caso.fase2.y)),
          reason: fila.variable,
        );
      }

      final esperado = caso.esperado!;
      esperarControl(
        resultado,
        web: esperado.colapsoWebMin,
        bd: esperado.colapsoBdMin,
        ventana: esperado.ventanaMin,
        tolerancia: esperado.toleranciaMin,
      );
    });
  }

  test('la referencia parcial solo se aplica a constante y exponencial', () {
    final parcial = ReferenciaAbr(
      version: referencia.version,
      nota: referencia.nota,
      tanques: referencia.tanques,
      casos: [
        referencia.buscarCasoPorId('constante')!,
        referencia.buscarCasoPorId('exponencial')!,
      ],
    );

    final constante = calcular('constante', referenciaAbr: parcial);
    final exponencial = calcular('exponencial', referenciaAbr: parcial);
    final ciclico = calcular('ciclico', referenciaAbr: parcial);
    final lineal = calcular('lineal', referenciaAbr: parcial);

    expect(constante.notaComparacion, isNull);
    expect(exponencial.notaComparacion, isNull);
    expect(ciclico.notaComparacion, contains('No hay caso de referencia'));
    expect(lineal.notaComparacion, contains('No hay caso de referencia'));
  });

  test('el caso cíclico marca tráfico negativo en el horizonte', () {
    final resultado = calcular('ciclico');

    expect(resultado.traficoNegativoEnHorizonte, isTrue);
    expect(resultado.traficoMinimoEnHorizonte, lessThan(-1000));
    expect(
      resultado.comparacion.every((fila) => fila.referenciaPendiente),
      isTrue,
    );
    expect(resultado.limiteX, 'Acotado (oscila)');
    expect(resultado.limiteY, 'Acotado (oscila)');
  });

  test('los casos positivos no marcan tráfico negativo', () {
    for (final id in ['lineal', 'constante', 'exponencial']) {
      final resultado = calcular(id);
      expect(
        resultado.traficoNegativoEnHorizonte,
        isFalse,
        reason: 'tráfico negativo en $id',
      );
    }
  });
}
