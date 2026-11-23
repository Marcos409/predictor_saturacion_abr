import 'dart:convert';

import '../models/punto_simulacion.dart';
import '../models/solucion_analitica.dart';
import '../models/solucion_general.dart';
import 'evaluador_expresiones.dart';

abstract class EvaluadorAnalitico {
  double evaluarX(double t);

  double evaluarY(double t);
}

class EvaluadorSolucionGeneral implements EvaluadorAnalitico {
  final SolucionGeneral solucion;

  const EvaluadorSolucionGeneral({required this.solucion});

  @override
  double evaluarX(double t) => solucion.evaluarX(t);

  @override
  double evaluarY(double t) => solucion.evaluarY(t);
}

class EvaluadorSolucionAnalitica implements EvaluadorAnalitico {
  final SolucionAnalitica solucion;
  final EvaluadorExpresiones _evaluador;

  EvaluadorSolucionAnalitica({
    required this.solucion,
    EvaluadorExpresiones? evaluador,
  }) : _evaluador = evaluador ?? EvaluadorExpresiones();

  factory EvaluadorSolucionAnalitica.desdeJson(
    String contenido, {
    EvaluadorExpresiones? evaluador,
  }) {
    final mapa = jsonDecode(contenido) as Map<String, dynamic>;
    return EvaluadorSolucionAnalitica(
      solucion: SolucionAnalitica.fromJson(mapa),
      evaluador: evaluador,
    );
  }

  @override
  double evaluarX(double t) {
    return _evaluador.evaluar(solucion.expresionX, {solucion.variable: t});
  }

  @override
  double evaluarY(double t) {
    return _evaluador.evaluar(solucion.expresionY, {solucion.variable: t});
  }

  PuntoSimulacion punto(double t) {
    return PuntoSimulacion(t: t, x: evaluarX(t), y: evaluarY(t));
  }

  List<PuntoSimulacion> muestrear({
    required double tInicial,
    required double tFinal,
    required double paso,
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
    final puntos = <PuntoSimulacion>[];
    var t = tInicial;
    while (t < tFinal - 1e-12) {
      puntos.add(punto(t));
      t += paso;
    }
    puntos.add(punto(tFinal));
    return puntos;
  }
}
