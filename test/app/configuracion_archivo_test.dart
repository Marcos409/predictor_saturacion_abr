import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/configuracion_archivo.dart';

import '../engine/configuracion_prueba.dart';

void main() {
  late ConfiguracionArchivo base;

  setUp(() {
    base = ConfiguracionArchivo(
      sistema: cargarSistema(),
      escenarios: cargarEscenarios(),
      solucionAnalitica: cargarSolucionAnalitica(),
    );
  });

  test('serializa y recupera la configuración completa', () {
    final recuperada = ConfiguracionArchivo.desdeJson(base.serializar());

    expect(recuperada.sistema.umbralAlerta, base.sistema.umbralAlerta);
    expect(
      recuperada.sistema.autoScaling.incrementoCapacidad,
      base.sistema.autoScaling.incrementoCapacidad,
    );
    expect(
      recuperada.escenarios.escenarios.length,
      base.escenarios.escenarios.length,
    );
    expect(
      recuperada.escenarios.escenarios.first.expresionV1,
      base.escenarios.escenarios.first.expresionV1,
    );
    expect(
      recuperada.solucionAnalitica.expresionX,
      base.solucionAnalitica.expresionX,
    );
  });

  test('rechaza un JSON sin una sección obligatoria', () {
    final mapa = base.toJson()..remove('escenarios');

    expect(
      () => ConfiguracionArchivo.desdeJson(jsonEncode(mapa)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('escenarios'),
        ),
      ),
    );
  });

  test('rechaza una sección con un campo faltante', () {
    final mapa = base.toJson();
    final sistema = mapa['sistema'] as Map<String, dynamic>;
    final tanques = sistema['tanques'] as Map<String, dynamic>;
    tanques.remove('tiempo_reaccion_min');

    expect(
      () => ConfiguracionArchivo.desdeJson(jsonEncode(mapa)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('tiempo_reaccion_min'),
        ),
      ),
    );
  });

  test('rechaza un archivo con sintaxis inválida', () {
    expect(
      () => ConfiguracionArchivo.desdeJson('{ sin cerrar'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('JSON válido'),
        ),
      ),
    );
  });
}
