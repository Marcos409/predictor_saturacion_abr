import 'dart:math' as math;

import 'resultado_colapso.dart';

class ResultadoVentanaAccion {
  final ResultadoColapso colapsoCapaWeb;
  final ResultadoColapso colapsoBaseDatos;
  final double tiempoReaccion;

  const ResultadoVentanaAccion({
    required this.colapsoCapaWeb,
    required this.colapsoBaseDatos,
    required this.tiempoReaccion,
  });

  double? get ventanaCapaWeb {
    final tiempo = colapsoCapaWeb.tiempo;
    return tiempo == null ? null : tiempo - tiempoReaccion;
  }

  double? get ventanaBaseDatos {
    final tiempo = colapsoBaseDatos.tiempo;
    return tiempo == null ? null : tiempo - tiempoReaccion;
  }

  double? get ventanaAccion {
    final ventanas = [ventanaCapaWeb, ventanaBaseDatos].whereType<double>();
    if (ventanas.isEmpty) return null;
    return ventanas.reduce(math.min);
  }
}
