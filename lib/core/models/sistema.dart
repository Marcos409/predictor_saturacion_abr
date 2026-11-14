import 'json_helpers.dart';

class CoeficientesSistema {
  final double a11;
  final double a12;
  final double a21;
  final double a22;

  const CoeficientesSistema({
    required this.a11,
    required this.a12,
    required this.a21,
    required this.a22,
  });

  factory CoeficientesSistema.fromJson(Map<String, dynamic> json) {
    return CoeficientesSistema(
      a11: numeroJson(json['a11'], 'a11'),
      a12: numeroJson(json['a12'], 'a12'),
      a21: numeroJson(json['a21'], 'a21'),
      a22: numeroJson(json['a22'], 'a22'),
    );
  }

  CoeficientesSistema copyWith({
    double? a11,
    double? a12,
    double? a21,
    double? a22,
  }) {
    return CoeficientesSistema(
      a11: a11 ?? this.a11,
      a12: a12 ?? this.a12,
      a21: a21 ?? this.a21,
      a22: a22 ?? this.a22,
    );
  }

  Map<String, dynamic> toJson() {
    return {'a11': a11, 'a12': a12, 'a21': a21, 'a22': a22};
  }
}

class CaudalesSistema {
  final double aAB;
  final double aSalida;
  final double bAA;
  final double bSalida;

  const CaudalesSistema({
    required this.aAB,
    required this.aSalida,
    required this.bAA,
    required this.bSalida,
  });

  factory CaudalesSistema.fromJson(Map<String, dynamic> json) {
    return CaudalesSistema(
      aAB: numeroJson(json['A_a_B'], 'A_a_B'),
      aSalida: numeroJson(json['A_salida'], 'A_salida'),
      bAA: numeroJson(json['B_a_A'], 'B_a_A'),
      bSalida: numeroJson(json['B_salida'], 'B_salida'),
    );
  }

  CaudalesSistema copyWith({
    double? aAB,
    double? aSalida,
    double? bAA,
    double? bSalida,
  }) {
    return CaudalesSistema(
      aAB: aAB ?? this.aAB,
      aSalida: aSalida ?? this.aSalida,
      bAA: bAA ?? this.bAA,
      bSalida: bSalida ?? this.bSalida,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'A_a_B': aAB,
      'A_salida': aSalida,
      'B_a_A': bAA,
      'B_salida': bSalida,
    };
  }
}

class TanquesSistema {
  final String modoCoeficientes;
  final double c1;
  final double volumenA;
  final double volumenB;
  final double limiteA;
  final double limiteB;
  final double tiempoReaccionMin;
  final CaudalesSistema caudales;
  final CoeficientesSistema coeficientesDirectos;

  const TanquesSistema({
    required this.modoCoeficientes,
    required this.c1,
    required this.volumenA,
    required this.volumenB,
    required this.limiteA,
    required this.limiteB,
    required this.tiempoReaccionMin,
    required this.caudales,
    required this.coeficientesDirectos,
  });

  factory TanquesSistema.fromJson(Map<String, dynamic> json) {
    final modo = textoJson(json['modo_coeficientes'], 'modo_coeficientes');
    if (modo != 'derivado' && modo != 'directo') {
      throw const FormatException(
        'El campo "modo_coeficientes" debe ser "derivado" o "directo"',
      );
    }
    final tanques = TanquesSistema(
      modoCoeficientes: modo,
      c1: numeroJson(json['c1'], 'c1'),
      volumenA: numeroJson(json['volumen_A'], 'volumen_A'),
      volumenB: numeroJson(json['volumen_B'], 'volumen_B'),
      limiteA: numeroJson(json['limite_A'], 'limite_A'),
      limiteB: numeroJson(json['limite_B'], 'limite_B'),
      tiempoReaccionMin: numeroJson(
        json['tiempo_reaccion_min'],
        'tiempo_reaccion_min',
      ),
      caudales: CaudalesSistema.fromJson(
        mapaJson(json['caudales'], 'caudales'),
      ),
      coeficientesDirectos: CoeficientesSistema.fromJson(
        mapaJson(json['coeficientes_directos'], 'coeficientes_directos'),
      ),
    );
    final error = tanques.validar();
    if (error != null) throw FormatException(error);
    return tanques;
  }

  String? validar() {
    if (caudales.aAB < 0 ||
        caudales.aSalida < 0 ||
        caudales.bAA < 0 ||
        caudales.bSalida < 0) {
      return 'Los caudales de los tubos no pueden ser negativos.';
    }
    if (volumenA <= 0 || volumenB <= 0) {
      return 'Los volúmenes de los tanques deben ser mayores que cero.';
    }
    if (c1 < 0) {
      return 'La concentración de entrada c1 no puede ser negativa.';
    }
    if (limiteA <= 0 || limiteB <= 0) {
      return 'Los límites críticos deben ser mayores que cero.';
    }
    if (tiempoReaccionMin < 0) {
      return 'El tiempo de reacción no puede ser negativo.';
    }
    return null;
  }

  CoeficientesSistema derivarCoeficientes() {
    return calcularCoeficientesSistema(copyWith(modoCoeficientes: 'derivado'));
  }

  TanquesSistema copyWith({
    String? modoCoeficientes,
    double? c1,
    double? volumenA,
    double? volumenB,
    double? limiteA,
    double? limiteB,
    double? tiempoReaccionMin,
    CaudalesSistema? caudales,
    CoeficientesSistema? coeficientesDirectos,
  }) {
    return TanquesSistema(
      modoCoeficientes: modoCoeficientes ?? this.modoCoeficientes,
      c1: c1 ?? this.c1,
      volumenA: volumenA ?? this.volumenA,
      volumenB: volumenB ?? this.volumenB,
      limiteA: limiteA ?? this.limiteA,
      limiteB: limiteB ?? this.limiteB,
      tiempoReaccionMin: tiempoReaccionMin ?? this.tiempoReaccionMin,
      caudales: caudales ?? this.caudales,
      coeficientesDirectos: coeficientesDirectos ?? this.coeficientesDirectos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modo_coeficientes': modoCoeficientes,
      'c1': c1,
      'volumen_A': volumenA,
      'volumen_B': volumenB,
      'limite_A': limiteA,
      'limite_B': limiteB,
      'tiempo_reaccion_min': tiempoReaccionMin,
      'caudales': caudales.toJson(),
      'coeficientes_directos': coeficientesDirectos.toJson(),
    };
  }
}

CoeficientesSistema calcularCoeficientesSistema(TanquesSistema tanques) {
  if (tanques.modoCoeficientes == 'directo') {
    return tanques.coeficientesDirectos;
  }
  final caudales = tanques.caudales;
  return CoeficientesSistema(
    a11: -(caudales.aAB + caudales.aSalida) / tanques.volumenA,
    a12: caudales.bAA / tanques.volumenB,
    a21: caudales.aAB / tanques.volumenA,
    a22: -(caudales.bAA + caudales.bSalida) / tanques.volumenB,
  );
}

class CapacidadesTanques {
  final double capaWeb;
  final double baseDatos;

  const CapacidadesTanques({required this.capaWeb, required this.baseDatos});

  factory CapacidadesTanques.fromJson(Map<String, dynamic> json) {
    return CapacidadesTanques(
      capaWeb: numeroJson(json['capa_web'], 'capa_web'),
      baseDatos: numeroJson(json['base_datos'], 'base_datos'),
    );
  }

  CapacidadesTanques copyWith({double? capaWeb, double? baseDatos}) {
    return CapacidadesTanques(
      capaWeb: capaWeb ?? this.capaWeb,
      baseDatos: baseDatos ?? this.baseDatos,
    );
  }

  Map<String, dynamic> toJson() {
    return {'capa_web': capaWeb, 'base_datos': baseDatos};
  }
}

class CondicionesIniciales {
  final double x0;
  final double y0;

  const CondicionesIniciales({required this.x0, required this.y0});

  factory CondicionesIniciales.fromJson(Map<String, dynamic> json) {
    return CondicionesIniciales(
      x0: numeroJson(json['x0'], 'x0'),
      y0: numeroJson(json['y0'], 'y0'),
    );
  }

  CondicionesIniciales copyWith({double? x0, double? y0}) {
    return CondicionesIniciales(x0: x0 ?? this.x0, y0: y0 ?? this.y0);
  }

  Map<String, dynamic> toJson() {
    return {'x0': x0, 'y0': y0};
  }
}

class ConfiguracionSimulacion {
  final double paso;
  final double tiempoFinal;

  const ConfiguracionSimulacion({
    required this.paso,
    required this.tiempoFinal,
  });

  factory ConfiguracionSimulacion.fromJson(Map<String, dynamic> json) {
    return ConfiguracionSimulacion(
      paso: numeroJson(json['paso'], 'paso'),
      tiempoFinal: numeroJson(json['tiempo_final'], 'tiempo_final'),
    );
  }

  ConfiguracionSimulacion copyWith({double? paso, double? tiempoFinal}) {
    return ConfiguracionSimulacion(
      paso: paso ?? this.paso,
      tiempoFinal: tiempoFinal ?? this.tiempoFinal,
    );
  }

  Map<String, dynamic> toJson() {
    return {'paso': paso, 'tiempo_final': tiempoFinal};
  }
}

class ConfiguracionAutoScaling {
  final double incrementoCapacidad;
  final double retraso;
  final int maximoEscalados;

  const ConfiguracionAutoScaling({
    required this.incrementoCapacidad,
    required this.retraso,
    required this.maximoEscalados,
  });

  factory ConfiguracionAutoScaling.fromJson(Map<String, dynamic> json) {
    return ConfiguracionAutoScaling(
      incrementoCapacidad: numeroJson(
        json['incremento_capacidad'],
        'incremento_capacidad',
      ),
      retraso: numeroJson(json['retraso'], 'retraso'),
      maximoEscalados: numeroJson(
        json['maximo_escalados'],
        'maximo_escalados',
      ).toInt(),
    );
  }

  ConfiguracionAutoScaling copyWith({
    double? incrementoCapacidad,
    double? retraso,
    int? maximoEscalados,
  }) {
    return ConfiguracionAutoScaling(
      incrementoCapacidad: incrementoCapacidad ?? this.incrementoCapacidad,
      retraso: retraso ?? this.retraso,
      maximoEscalados: maximoEscalados ?? this.maximoEscalados,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incremento_capacidad': incrementoCapacidad,
      'retraso': retraso,
      'maximo_escalados': maximoEscalados,
    };
  }
}

class ConfiguracionVerificacion {
  final double umbralError;

  const ConfiguracionVerificacion({required this.umbralError});

  factory ConfiguracionVerificacion.fromJson(Map<String, dynamic> json) {
    return ConfiguracionVerificacion(
      umbralError: numeroJson(json['umbral_error'], 'umbral_error'),
    );
  }

  ConfiguracionVerificacion copyWith({double? umbralError}) {
    return ConfiguracionVerificacion(
      umbralError: umbralError ?? this.umbralError,
    );
  }

  Map<String, dynamic> toJson() {
    return {'umbral_error': umbralError};
  }
}

class ConfiguracionSemaforo {
  final double ventanaAmarilla;
  final double ventanaVerde;

  const ConfiguracionSemaforo({
    required this.ventanaAmarilla,
    required this.ventanaVerde,
  });

  factory ConfiguracionSemaforo.fromJson(Map<String, dynamic> json) {
    return ConfiguracionSemaforo(
      ventanaAmarilla: numeroJson(json['ventana_amarilla'], 'ventana_amarilla'),
      ventanaVerde: numeroJson(json['ventana_verde'], 'ventana_verde'),
    );
  }

  ConfiguracionSemaforo copyWith({
    double? ventanaAmarilla,
    double? ventanaVerde,
  }) {
    return ConfiguracionSemaforo(
      ventanaAmarilla: ventanaAmarilla ?? this.ventanaAmarilla,
      ventanaVerde: ventanaVerde ?? this.ventanaVerde,
    );
  }

  Map<String, dynamic> toJson() {
    return {'ventana_amarilla': ventanaAmarilla, 'ventana_verde': ventanaVerde};
  }
}

class ConfiguracionSistema {
  final int version;
  final String unidadTiempo;
  final TanquesSistema tanques;
  final CondicionesIniciales condicionesIniciales;
  final double umbralAlerta;
  final ConfiguracionSimulacion simulacion;
  final ConfiguracionAutoScaling autoScaling;
  final ConfiguracionVerificacion verificacion;
  final ConfiguracionSemaforo semaforo;

  const ConfiguracionSistema({
    required this.version,
    required this.unidadTiempo,
    required this.tanques,
    required this.condicionesIniciales,
    required this.umbralAlerta,
    required this.simulacion,
    required this.autoScaling,
    required this.verificacion,
    required this.semaforo,
  });

  factory ConfiguracionSistema.fromJson(Map<String, dynamic> json) {
    return ConfiguracionSistema(
      version: numeroJson(json['version'], 'version').toInt(),
      unidadTiempo: textoJson(json['unidad_tiempo'], 'unidad_tiempo'),
      tanques: TanquesSistema.fromJson(mapaJson(json['tanques'], 'tanques')),
      condicionesIniciales: CondicionesIniciales.fromJson(
        mapaJson(json['condiciones_iniciales'], 'condiciones_iniciales'),
      ),
      umbralAlerta: numeroJson(json['umbral_alerta'], 'umbral_alerta'),
      simulacion: ConfiguracionSimulacion.fromJson(
        mapaJson(json['simulacion'], 'simulacion'),
      ),
      autoScaling: ConfiguracionAutoScaling.fromJson(
        mapaJson(json['auto_scaling'], 'auto_scaling'),
      ),
      verificacion: ConfiguracionVerificacion.fromJson(
        mapaJson(json['verificacion'], 'verificacion'),
      ),
      semaforo: ConfiguracionSemaforo.fromJson(
        mapaJson(json['semaforo'], 'semaforo'),
      ),
    );
  }

  CoeficientesSistema get coeficientes => calcularCoeficientesSistema(tanques);

  CapacidadesTanques get capacidades =>
      CapacidadesTanques(capaWeb: tanques.limiteA, baseDatos: tanques.limiteB);

  double get tiempoReaccion => tanques.tiempoReaccionMin;

  ConfiguracionSistema copyWith({
    int? version,
    TanquesSistema? tanques,
    CondicionesIniciales? condicionesIniciales,
    double? tiempoReaccion,
    double? umbralAlerta,
    ConfiguracionSimulacion? simulacion,
    ConfiguracionAutoScaling? autoScaling,
    ConfiguracionVerificacion? verificacion,
    ConfiguracionSemaforo? semaforo,
  }) {
    final tanquesActualizados = tanques ?? this.tanques;
    return ConfiguracionSistema(
      version: version ?? this.version,
      unidadTiempo: unidadTiempo,
      tanques: tiempoReaccion == null
          ? tanquesActualizados
          : tanquesActualizados.copyWith(tiempoReaccionMin: tiempoReaccion),
      condicionesIniciales: condicionesIniciales ?? this.condicionesIniciales,
      umbralAlerta: umbralAlerta ?? this.umbralAlerta,
      simulacion: simulacion ?? this.simulacion,
      autoScaling: autoScaling ?? this.autoScaling,
      verificacion: verificacion ?? this.verificacion,
      semaforo: semaforo ?? this.semaforo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'unidad_tiempo': unidadTiempo,
      'tanques': tanques.toJson(),
      'condiciones_iniciales': condicionesIniciales.toJson(),
      'umbral_alerta': umbralAlerta,
      'simulacion': simulacion.toJson(),
      'auto_scaling': autoScaling.toJson(),
      'verificacion': verificacion.toJson(),
      'semaforo': semaforo.toJson(),
    };
  }
}
