import 'dart:math' as math;

import 'evaluador_solucion_analitica.dart';
import '../models/punto_simulacion.dart';
import '../models/resultado_verificacion.dart';

class VerificadorCruzado {
  static const double umbralRelativoPorDefecto = 1e-6;

  const VerificadorCruzado();

  ResultadoVerificacion verificar({
    required List<PuntoSimulacion> puntosNumericos,
    required EvaluadorAnalitico analitica,
    double umbral = umbralRelativoPorDefecto,
  }) {
    if (umbral < 0) {
      throw ArgumentError.value(
        umbral,
        'umbral',
        'El umbral debe ser mayor o igual que cero',
      );
    }
    if (puntosNumericos.isEmpty) {
      throw ArgumentError.value(
        puntosNumericos,
        'puntosNumericos',
        'Debe haber al menos un punto para comparar',
      );
    }

    var errorMaximo = 0.0;
    var errorMaximoX = 0.0;
    var errorMaximoY = 0.0;
    var valorMaximo = 0.0;
    var tiempoErrorMaximo = puntosNumericos.first.t;

    for (final punto in puntosNumericos) {
      final xAnalitico = analitica.evaluarX(punto.t);
      final yAnalitico = analitica.evaluarY(punto.t);
      final errorX = (punto.x - xAnalitico).abs();
      final errorY = (punto.y - yAnalitico).abs();
      final error = math.max(errorX, errorY);

      if (errorX > errorMaximoX) errorMaximoX = errorX;
      if (errorY > errorMaximoY) errorMaximoY = errorY;
      valorMaximo = math.max(
        valorMaximo,
        math.max(
          math.max(punto.x.abs(), punto.y.abs()),
          math.max(xAnalitico.abs(), yAnalitico.abs()),
        ),
      );
      if (error > errorMaximo) {
        errorMaximo = error;
        tiempoErrorMaximo = punto.t;
      }
    }

    final errorRelativo = valorMaximo > 0
        ? errorMaximo / valorMaximo
        : (errorMaximo > 0 ? double.infinity : 0.0);

    return ResultadoVerificacion(
      errorMaximo: errorMaximo,
      errorMaximoX: errorMaximoX,
      errorMaximoY: errorMaximoY,
      errorRelativo: errorRelativo,
      valorMaximo: valorMaximo,
      tiempoErrorMaximo: tiempoErrorMaximo,
      umbral: umbral,
      cantidadPuntos: puntosNumericos.length,
    );
  }
}
