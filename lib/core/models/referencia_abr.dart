import 'json_helpers.dart';

double? _numeroOpcional(dynamic valor, String campo) {
  return valor == null ? null : numeroJson(valor, campo);
}

String? _textoOpcional(dynamic valor, String campo) {
  return valor == null ? null : textoJson(valor, campo);
}

bool? _booleanoOpcional(dynamic valor, String campo) {
  if (valor == null) return null;
  if (valor is bool) return valor;
  throw FormatException('El campo "$campo" debe ser booleano');
}

class CoeficientesAbr {
  final double a11;
  final double a12;
  final double a21;
  final double a22;

  const CoeficientesAbr({
    required this.a11,
    required this.a12,
    required this.a21,
    required this.a22,
  });

  factory CoeficientesAbr.fromJson(Map<String, dynamic> json) {
    return CoeficientesAbr(
      a11: numeroJson(json['a11'], 'a11'),
      a12: numeroJson(json['a12'], 'a12'),
      a21: numeroJson(json['a21'], 'a21'),
      a22: numeroJson(json['a22'], 'a22'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'a11': a11, 'a12': a12, 'a21': a21, 'a22': a22};
  }
}

class CaudalesAbr {
  final double aAB;
  final double aSalida;
  final double bAA;
  final double bSalida;

  const CaudalesAbr({
    required this.aAB,
    required this.aSalida,
    required this.bAA,
    required this.bSalida,
  });

  factory CaudalesAbr.fromJson(Map<String, dynamic> json) {
    return CaudalesAbr(
      aAB: numeroJson(json['A_a_B'], 'A_a_B'),
      aSalida: numeroJson(json['A_salida'], 'A_salida'),
      bAA: numeroJson(json['B_a_A'], 'B_a_A'),
      bSalida: numeroJson(json['B_salida'], 'B_salida'),
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

class TanquesAbr {
  final String modoCoeficientes;
  final double c1;
  final double volumenA;
  final double volumenB;
  final double limiteA;
  final double limiteB;
  final double tiempoReaccionMin;
  final CaudalesAbr caudales;
  final CoeficientesAbr coeficientesDirectos;

  const TanquesAbr({
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

  factory TanquesAbr.fromJson(Map<String, dynamic> json) {
    final modo = textoJson(json['modo_coeficientes'], 'modo_coeficientes');
    if (modo != 'derivado' && modo != 'directo') {
      throw const FormatException(
        'El campo "modo_coeficientes" debe ser "derivado" o "directo"',
      );
    }
    return TanquesAbr(
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
      caudales: CaudalesAbr.fromJson(mapaJson(json['caudales'], 'caudales')),
      coeficientesDirectos: CoeficientesAbr.fromJson(
        mapaJson(json['coeficientes_directos'], 'coeficientes_directos'),
      ),
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

class Fase1Abr {
  final String edo;
  final double p0;
  final String v1;
  final double? r;
  final double? b;
  final double? dP0;
  final double? periodoMin;

  const Fase1Abr({
    required this.edo,
    required this.p0,
    required this.v1,
    this.r,
    this.b,
    this.dP0,
    this.periodoMin,
  });

  factory Fase1Abr.fromJson(Map<String, dynamic> json) {
    return Fase1Abr(
      edo: textoJson(json['edo'], 'edo'),
      p0: numeroJson(json['P0'], 'P0'),
      v1: textoJson(json['v1'], 'v1'),
      r: _numeroOpcional(json['r'], 'r'),
      b: _numeroOpcional(json['b'], 'b'),
      dP0: _numeroOpcional(json['dP0'], 'dP0'),
      periodoMin: _numeroOpcional(json['periodo_min'], 'periodo_min'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'edo': edo,
      'P0': p0,
      'v1': v1,
      if (r != null) 'r': r,
      if (b != null) 'b': b,
      if (dP0 != null) 'dP0': dP0,
      if (periodoMin != null) 'periodo_min': periodoMin,
    };
  }
}

class Fase2Abr {
  final double x0;
  final double y0;
  final String? x;
  final String? y;
  final String? xp;
  final String? yp;
  final bool? pendienteUsuario;

  const Fase2Abr({
    required this.x0,
    required this.y0,
    this.x,
    this.y,
    this.xp,
    this.yp,
    this.pendienteUsuario,
  });

  factory Fase2Abr.fromJson(Map<String, dynamic> json) {
    return Fase2Abr(
      x0: numeroJson(json['x0'], 'x0'),
      y0: numeroJson(json['y0'], 'y0'),
      x: _textoOpcional(json['x'], 'x'),
      y: _textoOpcional(json['y'], 'y'),
      xp: _textoOpcional(json['xp'], 'xp'),
      yp: _textoOpcional(json['yp'], 'yp'),
      pendienteUsuario: _booleanoOpcional(
        json['pendiente_usuario'],
        'pendiente_usuario',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x0': x0,
      'y0': y0,
      'x': x,
      'y': y,
      'xp': xp,
      'yp': yp,
      if (pendienteUsuario != null) 'pendiente_usuario': pendienteUsuario,
    };
  }
}

class EsperadoAbr {
  final double colapsoWebMin;
  final double colapsoBdMin;
  final double ventanaMin;
  final double toleranciaMin;
  final bool? aproximado;

  const EsperadoAbr({
    required this.colapsoWebMin,
    required this.colapsoBdMin,
    required this.ventanaMin,
    required this.toleranciaMin,
    this.aproximado,
  });

  factory EsperadoAbr.fromJson(Map<String, dynamic> json) {
    return EsperadoAbr(
      colapsoWebMin: numeroJson(json['colapso_web_min'], 'colapso_web_min'),
      colapsoBdMin: numeroJson(json['colapso_bd_min'], 'colapso_bd_min'),
      ventanaMin: numeroJson(json['ventana_min'], 'ventana_min'),
      toleranciaMin: numeroJson(json['tolerancia_min'], 'tolerancia_min'),
      aproximado: _booleanoOpcional(json['aproximado'], 'aproximado'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colapso_web_min': colapsoWebMin,
      'colapso_bd_min': colapsoBdMin,
      'ventana_min': ventanaMin,
      'tolerancia_min': toleranciaMin,
      if (aproximado != null) 'aproximado': aproximado,
    };
  }
}

class CasoAbr {
  final String id;
  final Fase1Abr fase1;
  final Fase2Abr fase2;
  final EsperadoAbr? esperado;

  const CasoAbr({
    required this.id,
    required this.fase1,
    required this.fase2,
    this.esperado,
  });

  factory CasoAbr.fromJson(Map<String, dynamic> json) {
    final esperado = json['esperado'];
    return CasoAbr(
      id: textoJson(json['id'], 'id'),
      fase1: Fase1Abr.fromJson(mapaJson(json['fase1'], 'fase1')),
      fase2: Fase2Abr.fromJson(mapaJson(json['fase2'], 'fase2')),
      esperado: esperado == null
          ? null
          : EsperadoAbr.fromJson(mapaJson(esperado, 'esperado')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fase1': fase1.toJson(),
      'fase2': fase2.toJson(),
      'esperado': esperado?.toJson(),
    };
  }
}

class ReferenciaAbr {
  final int version;
  final String nota;
  final TanquesAbr tanques;
  final List<CasoAbr> casos;

  const ReferenciaAbr({
    required this.version,
    required this.nota,
    required this.tanques,
    required this.casos,
  });

  factory ReferenciaAbr.fromJson(Map<String, dynamic> json) {
    final casos = listaJson(
      json['casos'],
      'casos',
    ).map((caso) => CasoAbr.fromJson(mapaJson(caso, 'caso'))).toList();
    if (casos.isEmpty) {
      throw const FormatException(
        'La referencia ABR debe incluir al menos un caso',
      );
    }
    return ReferenciaAbr(
      version: numeroJson(json['version'], 'version').toInt(),
      nota: textoJson(json['nota'], 'nota'),
      tanques: TanquesAbr.fromJson(mapaJson(json['tanques'], 'tanques')),
      casos: casos,
    );
  }

  CasoAbr? buscarCasoPorId(String id) {
    for (final caso in casos) {
      if (caso.id == id) return caso;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'nota': nota,
      'tanques': tanques.toJson(),
      'casos': casos.map((caso) => caso.toJson()).toList(),
    };
  }
}
