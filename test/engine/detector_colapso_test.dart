import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/detector_colapso.dart';
import 'package:predictor_saturacion_abr/core/models/punto_simulacion.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_colapso.dart';

void main() {
  group('DetectorColapso', () {
    const detector = DetectorColapso();
    const puntos = [
      PuntoSimulacion(t: 0, x: 0, y: 0),
      PuntoSimulacion(t: 1, x: 10, y: 5),
      PuntoSimulacion(t: 2, x: 30, y: 40),
    ];

    test('interpola el cruce entre dos pasos', () {
      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: 20,
        puntos: puntos,
        valor: (punto) => punto.x,
      );
      expect(colapso.colapsa, isTrue);
      expect(colapso.tiempo, closeTo(1.5, 1e-12));
    });

    test('informa ausencia de colapso si no cruza el límite', () {
      final colapso = detector.detectar(
        tanque: 'base_datos',
        limite: 100,
        puntos: puntos,
        valor: (punto) => punto.y,
      );
      expect(colapso.colapsa, isFalse);
      expect(colapso.tiempo, isNull);
    });

    test('detecta colapso si el valor inicial ya supera el límite', () {
      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: 0,
        puntos: puntos,
        valor: (punto) => punto.x,
      );
      expect(colapso.tiempo, 0);
    });

    test('conserva el tanque y el límite consultados', () {
      final colapso = detector.detectar(
        tanque: 'base_datos',
        limite: 20,
        puntos: puntos,
        valor: (punto) => punto.y,
      );

      expect(colapso.tanque, 'base_datos');
      expect(colapso.limite, 20);
      expect(colapso.colapsa, isTrue);
    });

    test('informa ausencia de colapso con una lista vacía', () {
      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: 100,
        puntos: const [],
        valor: (punto) => punto.x,
      );

      expect(colapso.colapsa, isFalse);
      expect(colapso.tiempo, isNull);
    });

    test('calcula la ventana de acción como el mínimo de los tanques', () {
      const colapsoWeb = ResultadoColapso(
        tanque: 'capa_web',
        limite: 100,
        tiempo: 8,
      );
      const colapsoBaseDatos = ResultadoColapso(
        tanque: 'base_datos',
        limite: 200,
        tiempo: 20,
      );

      final ventana = detector.calcularVentanaAccion(
        colapsoCapaWeb: colapsoWeb,
        colapsoBaseDatos: colapsoBaseDatos,
        tiempoReaccion: 10,
      );

      expect(ventana.ventanaCapaWeb, -2);
      expect(ventana.ventanaBaseDatos, 10);
      expect(ventana.ventanaAccion, -2);
    });

    test('ignora los tanques sin colapso al calcular la ventana', () {
      const colapsoWeb = ResultadoColapso(
        tanque: 'capa_web',
        limite: 100,
        tiempo: 12,
      );
      const colapsoBaseDatos = ResultadoColapso(
        tanque: 'base_datos',
        limite: 200,
        tiempo: null,
      );

      final ventana = detector.calcularVentanaAccion(
        colapsoCapaWeb: colapsoWeb,
        colapsoBaseDatos: colapsoBaseDatos,
        tiempoReaccion: 10,
      );

      expect(ventana.ventanaCapaWeb, 2);
      expect(ventana.ventanaBaseDatos, isNull);
      expect(ventana.ventanaAccion, 2);
    });

    test('devuelve una ventana nula si ningún tanque colapsa', () {
      const sinColapso = ResultadoColapso(
        tanque: 'capa_web',
        limite: 100,
        tiempo: null,
      );

      final ventana = detector.calcularVentanaAccion(
        colapsoCapaWeb: sinColapso,
        colapsoBaseDatos: sinColapso,
        tiempoReaccion: 10,
      );

      expect(ventana.ventanaAccion, isNull);
    });

    test('devuelve el instante exacto cuando el valor toca el límite', () {
      const puntosCruce = [
        PuntoSimulacion(t: 0, x: 0, y: 0),
        PuntoSimulacion(t: 1, x: 50, y: 0),
        PuntoSimulacion(t: 2, x: 100, y: 0),
      ];

      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: 100,
        puntos: puntosCruce,
        valor: (punto) => punto.x,
      );

      expect(colapso.tiempo, closeTo(2, 1e-12));
    });

    test('usa el primer tiempo de la serie como colapso inicial', () {
      const puntos = [
        PuntoSimulacion(t: 2.5, x: 10, y: 0),
        PuntoSimulacion(t: 3.5, x: 20, y: 0),
      ];

      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: 5,
        puntos: puntos,
        valor: (punto) => punto.x,
      );

      expect(colapso.tiempo, 2.5);
    });

    test('se queda con el primer cruce de una serie no monótona', () {
      const puntos = [
        PuntoSimulacion(t: 0, x: 0, y: 0),
        PuntoSimulacion(t: 1, x: 60, y: 0),
        PuntoSimulacion(t: 2, x: 120, y: 0),
        PuntoSimulacion(t: 3, x: 80, y: 0),
        PuntoSimulacion(t: 4, x: 150, y: 0),
      ];

      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: 100,
        puntos: puntos,
        valor: (punto) => punto.x,
      );

      expect(colapso.tiempo, closeTo(5 / 3, 1e-12));
    });

    test('calcula la ventana usando solo la base de datos', () {
      const sinWeb = ResultadoColapso(
        tanque: 'capa_web',
        limite: 100,
        tiempo: null,
      );
      const conBd = ResultadoColapso(
        tanque: 'base_datos',
        limite: 200,
        tiempo: 12,
      );

      final ventana = detector.calcularVentanaAccion(
        colapsoCapaWeb: sinWeb,
        colapsoBaseDatos: conBd,
        tiempoReaccion: 10,
      );

      expect(ventana.ventanaCapaWeb, isNull);
      expect(ventana.ventanaBaseDatos, 2);
      expect(ventana.ventanaAccion, 2);
    });

    test('resta el tiempo de reacción cuando ambos tanques colapsan', () {
      const colapsoWeb = ResultadoColapso(
        tanque: 'capa_web',
        limite: 100,
        tiempo: 10,
      );
      const colapsoBaseDatos = ResultadoColapso(
        tanque: 'base_datos',
        limite: 200,
        tiempo: 10,
      );

      final ventana = detector.calcularVentanaAccion(
        colapsoCapaWeb: colapsoWeb,
        colapsoBaseDatos: colapsoBaseDatos,
        tiempoReaccion: 10,
      );

      expect(ventana.ventanaAccion, 0);
    });
  });
}
