import 'dart:math' as math;

import '../models/punto_simulacion.dart';
import '../models/resultado_verificacion.dart';
import 'evaluador_solucion_analitica.dart';

class VerificadorCruzado {
  const VerificadorCruzado();

  ResultadoVerificacion verificar({
    required List<PuntoSimulacion> puntosNumericos,
    required EvaluadorSolucionAnalitica analitica,
    required double umbral,
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
    var tiempoErrorMaximo = puntosNumericos.first.t;

    for (final punto in puntosNumericos) {
      final errorX = (punto.x - analitica.evaluarX(punto.t)).abs();
      final errorY = (punto.y - analitica.evaluarY(punto.t)).abs();
      final error = math.max(errorX, errorY);

      if (errorX > errorMaximoX) errorMaximoX = errorX;
      if (errorY > errorMaximoY) errorMaximoY = errorY;
      if (error > errorMaximo) {
        errorMaximo = error;
        tiempoErrorMaximo = punto.t;
      }
    }

    return ResultadoVerificacion(
      errorMaximo: errorMaximo,
      errorMaximoX: errorMaximoX,
      errorMaximoY: errorMaximoY,
      tiempoErrorMaximo: tiempoErrorMaximo,
      umbral: umbral,
      cantidadPuntos: puntosNumericos.length,
    );
  }
}
