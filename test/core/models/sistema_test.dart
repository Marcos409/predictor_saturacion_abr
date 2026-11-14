import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';

import '../../engine/configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sistema = cargarSistema();
  final tanques = sistema.tanques;

  group('TanquesSistema.validar', () {
    test('acepta la configuración base del ABR', () {
      expect(tanques.validar(), isNull);
    });

    test('acepta caudales, concentración y reacción en cero', () {
      final validos = tanques.copyWith(
        caudales: const CaudalesSistema(aAB: 0, aSalida: 0, bAA: 0, bSalida: 0),
        c1: 0,
        tiempoReaccionMin: 0,
      );

      expect(validos.validar(), isNull);
    });

    test('rechaza cualquier caudal negativo', () {
      final invalidos = [
        tanques.copyWith(caudales: tanques.caudales.copyWith(aAB: -1)),
        tanques.copyWith(caudales: tanques.caudales.copyWith(aSalida: -1)),
        tanques.copyWith(caudales: tanques.caudales.copyWith(bAA: -1)),
        tanques.copyWith(caudales: tanques.caudales.copyWith(bSalida: -1)),
      ];

      for (final invalido in invalidos) {
        expect(invalido.validar(), contains('caudales'));
      }
    });

    test('rechaza volúmenes de tanque no positivos', () {
      expect(tanques.copyWith(volumenA: 0).validar(), contains('volúmenes'));
      expect(tanques.copyWith(volumenB: -1).validar(), contains('volúmenes'));
    });

    test('rechaza una concentración de entrada negativa', () {
      expect(tanques.copyWith(c1: -0.1).validar(), contains('concentración'));
    });

    test('rechaza límites críticos no positivos', () {
      expect(tanques.copyWith(limiteA: 0).validar(), contains('límites'));
      expect(tanques.copyWith(limiteB: -10).validar(), contains('límites'));
    });

    test('rechaza un tiempo de reacción negativo', () {
      expect(
        tanques.copyWith(tiempoReaccionMin: -1).validar(),
        contains('reacción'),
      );
    });
  });

  group('TanquesSistema.fromJson', () {
    test('reconstruye la configuración serializada', () {
      final copia = TanquesSistema.fromJson(tanques.toJson());

      expect(copia.modoCoeficientes, tanques.modoCoeficientes);
      expect(copia.c1, tanques.c1);
      expect(copia.volumenA, tanques.volumenA);
      expect(copia.volumenB, tanques.volumenB);
      expect(copia.limiteA, tanques.limiteA);
      expect(copia.limiteB, tanques.limiteB);
      expect(copia.tiempoReaccionMin, tanques.tiempoReaccionMin);
      expect(copia.caudales.aAB, tanques.caudales.aAB);
      expect(copia.caudales.bSalida, tanques.caudales.bSalida);
      expect(copia.coeficientesDirectos.a21, tanques.coeficientesDirectos.a21);
    });

    test('rechaza un modo de coeficientes desconocido', () {
      expect(
        () => TanquesSistema.fromJson({
          ...tanques.toJson(),
          'modo_coeficientes': 'mixto',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'mensaje',
            contains('modo_coeficientes'),
          ),
        ),
      );
    });

    test('rechaza volúmenes inválidos', () {
      expect(
        () => TanquesSistema.fromJson({...tanques.toJson(), 'volumen_A': 0}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'mensaje',
            contains('volúmenes'),
          ),
        ),
      );
    });
  });

  group('calcularCoeficientesSistema', () {
    test('deriva los coeficientes desde caudales y volúmenes', () {
      final coeficientes = calcularCoeficientesSistema(tanques);

      expect(coeficientes.a11, closeTo(-0.3, 1e-12));
      expect(coeficientes.a12, closeTo(0.1, 1e-12));
      expect(coeficientes.a21, closeTo(0.2, 1e-12));
      expect(coeficientes.a22, closeTo(-0.4, 1e-12));
    });

    test('usa los coeficientes directos sin derivarlos', () {
      const directos = CoeficientesSistema(a11: -9, a12: 8, a21: 7, a22: -6);
      final configuracion = tanques.copyWith(
        modoCoeficientes: 'directo',
        coeficientesDirectos: directos,
      );

      final coeficientes = calcularCoeficientesSistema(configuracion);
      expect(coeficientes.a11, -9);
      expect(coeficientes.a12, 8);
      expect(coeficientes.a21, 7);
      expect(coeficientes.a22, -6);
    });

    test('derivarCoeficientes ignora el modo directo', () {
      final configuracion = tanques.copyWith(
        modoCoeficientes: 'directo',
        coeficientesDirectos: const CoeficientesSistema(
          a11: -9,
          a12: 8,
          a21: 7,
          a22: -6,
        ),
      );

      final derivados = configuracion.derivarCoeficientes();
      expect(derivados.a11, closeTo(-0.3, 1e-12));
      expect(derivados.a12, closeTo(0.1, 1e-12));
      expect(derivados.a21, closeTo(0.2, 1e-12));
      expect(derivados.a22, closeTo(-0.4, 1e-12));
    });
  });

  group('ConfiguracionSistema', () {
    test('expone capacidades y coeficientes coherentes con los tanques', () {
      expect(sistema.capacidades.capaWeb, tanques.limiteA);
      expect(sistema.capacidades.baseDatos, tanques.limiteB);
      expect(sistema.tiempoReaccion, tanques.tiempoReaccionMin);
      expect(sistema.coeficientes.a11, closeTo(-0.3, 1e-12));
      expect(sistema.coeficientes.a22, closeTo(-0.4, 1e-12));
    });

    test(
      'copyWith(tiempoReaccion) actualiza el tiempo sin tocar los tanques',
      () {
        final actualizado = sistema.copyWith(tiempoReaccion: 99);

        expect(actualizado.tiempoReaccion, 99);
        expect(actualizado.tanques.tiempoReaccionMin, 99);
        expect(actualizado.tanques.c1, tanques.c1);
        expect(actualizado.tanques.caudales.aAB, tanques.caudales.aAB);
      },
    );

    test('toJson y fromJson conservan la configuración', () {
      final copia = ConfiguracionSistema.fromJson(sistema.toJson());

      expect(copia.version, sistema.version);
      expect(copia.unidadTiempo, 'min');
      expect(copia.tanques.modoCoeficientes, tanques.modoCoeficientes);
      expect(copia.condicionesIniciales.x0, sistema.condicionesIniciales.x0);
      expect(copia.verificacion.umbralError, sistema.verificacion.umbralError);
      expect(copia.semaforo.ventanaVerde, sistema.semaforo.ventanaVerde);
    });
  });
}
