import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/semaforo.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_colapso.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_ventana_accion.dart';

import '../engine/configuracion_prueba.dart';

void main() {
  group('Semáforo', () {
    final configuracion = cargarSistema().semaforo;

    ResultadoVentanaAccion ventanaCon(double? tiempoWeb) {
      return ResultadoVentanaAccion(
        colapsoCapaWeb: ResultadoColapso(
          tanque: 'capa_web',
          limite: 100,
          tiempo: tiempoWeb,
        ),
        colapsoBaseDatos: const ResultadoColapso(
          tanque: 'base_datos',
          limite: 200,
          tiempo: null,
        ),
        tiempoReaccion: 10,
      );
    }

    test('sin colapso cuando no hay ventana calculada', () {
      expect(
        evaluarNivelSemaforo(ventana: null, configuracion: configuracion),
        NivelSemaforo.sinColapso,
      );
      expect(
        evaluarNivelSemaforo(
          ventana: ventanaCon(null),
          configuracion: configuracion,
        ),
        NivelSemaforo.sinColapso,
      );
    });

    test('crítico por debajo del umbral amarillo', () {
      expect(
        evaluarNivelSemaforo(
          ventana: ventanaCon(9.99),
          configuracion: configuracion,
        ),
        NivelSemaforo.critico,
      );
    });

    test('precaución entre los umbrales amarillo y verde', () {
      expect(
        evaluarNivelSemaforo(
          ventana: ventanaCon(12),
          configuracion: configuracion,
        ),
        NivelSemaforo.precaucion,
      );
    });

    test('estable al alcanzar el umbral verde', () {
      expect(
        evaluarNivelSemaforo(
          ventana: ventanaCon(15),
          configuracion: configuracion,
        ),
        NivelSemaforo.estable,
      );
    });

    test('traduce el nivel a una etiqueta en español', () {
      expect(etiquetaNivelSemaforo(NivelSemaforo.critico), 'Crítico');
      expect(etiquetaNivelSemaforo(NivelSemaforo.precaucion), 'Precaución');
      expect(etiquetaNivelSemaforo(NivelSemaforo.estable), 'Estable');
      expect(etiquetaNivelSemaforo(NivelSemaforo.sinColapso), 'Sin colapso');
    });
  });
}
