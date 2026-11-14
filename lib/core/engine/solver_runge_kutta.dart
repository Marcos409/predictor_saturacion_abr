import 'dart:math' as math;

import '../models/punto_simulacion.dart';
import '../models/resultado_simulacion.dart';
import '../models/sistema.dart';

class SolucionadorRungeKutta {
  final ConfiguracionSistema configuracion;

  const SolucionadorRungeKutta({required this.configuracion});

  ResultadoSimulacion resolver({
    required double Function(double t) entrada,
    required double paso,
    required double tFinal,
    double tInicial = 0,
  }) {
    if (paso <= 0) {
      throw ArgumentError.value(
        paso,
        'paso',
        'El paso debe ser mayor que cero',
      );
    }
    if (tFinal < tInicial) {
      throw ArgumentError.value(
        tFinal,
        'tFinal',
        'El tiempo final debe ser mayor o igual que el inicial',
      );
    }

    final condiciones = configuracion.condicionesIniciales;
    final coeficientes = configuracion.coeficientes;
    final factor = configuracion.tanques.c1;

    var t = tInicial;
    var x = condiciones.x0;
    var y = condiciones.y0;

    final puntos = <PuntoSimulacion>[PuntoSimulacion(t: t, x: x, y: y)];

    while (t < tFinal - 1e-12) {
      final h = math.min(paso, tFinal - t);
      final (k1x, k1y) = _derivadas(t, x, y, entrada, coeficientes, factor);
      final (k2x, k2y) = _derivadas(
        t + h / 2,
        x + h / 2 * k1x,
        y + h / 2 * k1y,
        entrada,
        coeficientes,
        factor,
      );
      final (k3x, k3y) = _derivadas(
        t + h / 2,
        x + h / 2 * k2x,
        y + h / 2 * k2y,
        entrada,
        coeficientes,
        factor,
      );
      final (k4x, k4y) = _derivadas(
        t + h,
        x + h * k3x,
        y + h * k3y,
        entrada,
        coeficientes,
        factor,
      );

      x += h / 6 * (k1x + 2 * k2x + 2 * k3x + k4x);
      y += h / 6 * (k1y + 2 * k2y + 2 * k3y + k4y);
      t += h;

      puntos.add(PuntoSimulacion(t: t, x: x, y: y));
    }

    return ResultadoSimulacion(
      puntos: puntos,
      paso: paso,
      tInicial: tInicial,
      tFinal: tFinal,
    );
  }

  (double, double) _derivadas(
    double t,
    double x,
    double y,
    double Function(double t) entrada,
    CoeficientesSistema coeficientes,
    double factor,
  ) {
    final v1 = factor * entrada(t);
    final dx = v1 + coeficientes.a11 * x + coeficientes.a12 * y;
    final dy = coeficientes.a21 * x + coeficientes.a22 * y;
    return (dx, dy);
  }
}
