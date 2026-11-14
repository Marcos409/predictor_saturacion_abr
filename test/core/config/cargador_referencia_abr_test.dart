import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/config/cargador_referencia_abr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String contenido;

  setUpAll(() {
    contenido = File('assets/config/referencia_abr.json').readAsStringSync();
  });

  test('carga la versión y la nota de la referencia', () {
    final referencia = CargadorReferenciaAbr.desdeJson(contenido);

    expect(referencia.version, 2);
    expect(referencia.nota, contains('editados a mano'));
  });

  test('carga la sección de tanques con caudales y coeficientes', () {
    final tanques = CargadorReferenciaAbr.desdeJson(contenido).tanques;

    expect(tanques.modoCoeficientes, 'derivado');
    expect(tanques.c1, 1);
    expect(tanques.volumenA, 100);
    expect(tanques.volumenB, 200);
    expect(tanques.limiteA, 100);
    expect(tanques.limiteB, 200);
    expect(tanques.tiempoReaccionMin, 10);
    expect(tanques.caudales.aAB, 20);
    expect(tanques.caudales.aSalida, 10);
    expect(tanques.caudales.bAA, 20);
    expect(tanques.caudales.bSalida, 60);
    expect(tanques.coeficientesDirectos.a11, -0.3);
    expect(tanques.coeficientesDirectos.a12, 0.1);
    expect(tanques.coeficientesDirectos.a21, 0.2);
    expect(tanques.coeficientesDirectos.a22, -0.4);
  });

  test('carga los cuatro casos en orden', () {
    final referencia = CargadorReferenciaAbr.desdeJson(contenido);

    expect(referencia.casos.map((caso) => caso.id), [
      'lineal',
      'constante',
      'exponencial',
      'ciclico',
    ]);
    expect(referencia.buscarCasoPorId('constante'), isNotNull);
    expect(referencia.buscarCasoPorId('inexistente'), isNull);
  });

  test('carga las expresiones y los valores esperados del caso lineal', () {
    final caso = CargadorReferenciaAbr.desdeJson(
      contenido,
    ).buscarCasoPorId('lineal')!;

    expect(caso.fase1.edo, 'dP/dt = 5');
    expect(caso.fase1.p0, 10);
    expect(caso.fase1.v1, '10 + 5*t');
    expect(caso.fase2.x, contains('50*exp(-0.2*t)'));
    expect(caso.fase2.yp, '10 - 10*exp(-0.2*t)');
    expect(caso.esperado!.colapsoWebMin, 6.9);
    expect(caso.esperado!.colapsoBdMin, 24.97);
    expect(caso.esperado!.ventanaMin, -3.1);
    expect(caso.esperado!.toleranciaMin, 0.1);
    expect(caso.esperado!.aproximado, isNull);
  });

  test('carga los parámetros del caso exponencial', () {
    final caso = CargadorReferenciaAbr.desdeJson(
      contenido,
    ).buscarCasoPorId('exponencial')!;

    expect(caso.fase1.r, 0.05);
    expect(caso.fase1.b, 10);
    expect(caso.esperado!.colapsoWebMin, 4.36);
    expect(caso.esperado!.colapsoBdMin, 13.25);
    expect(caso.esperado!.ventanaMin, -5.64);
    expect(caso.esperado!.toleranciaMin, 0.4);
    expect(caso.esperado!.aproximado, isTrue);
  });

  test('carga el caso cíclico pendiente sin solución analítica', () {
    final caso = CargadorReferenciaAbr.desdeJson(
      contenido,
    ).buscarCasoPorId('ciclico')!;

    expect(caso.fase1.dP0, 20);
    expect(caso.fase1.periodoMin, 1440);
    expect(caso.fase1.v1, contains('PI/720'));
    expect(caso.fase2.x, isNull);
    expect(caso.fase2.y, isNull);
    expect(caso.fase2.pendienteUsuario, isTrue);
    expect(caso.esperado, isNull);
  });

  test('carga el archivo registrado como asset de la aplicación', () async {
    final referencia = await const CargadorReferenciaAbr().cargar();

    expect(referencia.version, 2);
    expect(referencia.casos.length, 4);
  });

  test('rechaza una referencia sin casos', () {
    expect(
      () => CargadorReferenciaAbr.desdeJson(
        '{"version": 2, "nota": "x", "tanques": {}, "casos": []}',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
