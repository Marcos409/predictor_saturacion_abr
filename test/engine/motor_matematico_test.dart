import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/detector_colapso.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_entrada_trafico.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/engine/solver_runge_kutta.dart';

import 'configuracion_prueba.dart';

void main() {
  group('Caso base del motor matemático', () {
    final sistema = cargarSistema();
    final escenarios = cargarEscenarios();
    final escenario = escenarios.buscarPorId('lineal')!;
    final entrada = EvaluadorEntradaTrafico(escenario: escenario);
    final solucionador = SolucionadorRungeKutta(configuracion: sistema);
    final resultado = solucionador.resolver(
      entrada: entrada.evaluar,
      paso: 0.01,
      tFinal: 30,
    );
    const detector = DetectorColapso();

    test('parte de las condiciones iniciales del sistema', () {
      expect(resultado.inicial.x, sistema.condicionesIniciales.x0);
      expect(resultado.inicial.y, sistema.condicionesIniciales.y0);
      expect(resultado.ultimo.t, closeTo(30, 1e-9));
    });

    test('x(7) ≈ 102.3', () {
      final punto = resultado.puntos.firstWhere(
        (punto) => (punto.t - 7).abs() < 1e-6,
      );
      expect(punto.x, closeTo(102.3, 0.1));
    });

    test('la solución numérica coincide con la analítica', () {
      final analitica = EvaluadorSolucionAnalitica.desdeJson(
        leerSolucionAnaliticaCruda(),
      );
      final punto = resultado.puntos.firstWhere(
        (punto) => (punto.t - 7).abs() < 1e-6,
      );
      expect(punto.x, closeTo(analitica.evaluarX(7), 1e-4));
      expect(punto.y, closeTo(analitica.evaluarY(7), 1e-4));
    });

    test('colapso de la Capa Web ≈ 6.9 min', () {
      final colapso = detector.detectar(
        tanque: 'capa_web',
        limite: sistema.capacidades.capaWeb,
        puntos: resultado.puntos,
        valor: (punto) => punto.x,
      );
      expect(colapso.colapsa, isTrue);
      expect(colapso.tiempo!, closeTo(6.9, 0.1));
    });

    test('colapso de la Base de Datos ≈ 24.97 min', () {
      final colapso = detector.detectar(
        tanque: 'base_datos',
        limite: sistema.capacidades.baseDatos,
        puntos: resultado.puntos,
        valor: (punto) => punto.y,
      );
      expect(colapso.colapsa, isTrue);
      expect(colapso.tiempo!, closeTo(24.97, 0.1));
    });

    test('Ventana de Acción ≈ -3.1 min', () {
      final web = detector.detectar(
        tanque: 'capa_web',
        limite: sistema.capacidades.capaWeb,
        puntos: resultado.puntos,
        valor: (punto) => punto.x,
      );
      final bd = detector.detectar(
        tanque: 'base_datos',
        limite: sistema.capacidades.baseDatos,
        puntos: resultado.puntos,
        valor: (punto) => punto.y,
      );
      final ventana = detector.calcularVentanaAccion(
        colapsoCapaWeb: web,
        colapsoBaseDatos: bd,
        tiempoReaccion: sistema.tiempoReaccion,
      );
      expect(ventana.ventanaCapaWeb!, closeTo(-3.1, 0.1));
      expect(ventana.ventanaAccion!, closeTo(-3.1, 0.1));
    });
  });
}
