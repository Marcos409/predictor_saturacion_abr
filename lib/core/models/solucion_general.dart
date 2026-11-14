import 'dart:math' as math;

import 'solucion_analitica.dart';

enum TipoTermino {
  constante,
  lineal,
  cuadratico,
  exponencial,
  exponencialLineal,
  seno,
  coseno,
}

class TerminoSolucion {
  final double coeficiente;
  final TipoTermino tipo;
  final double parametro;

  const TerminoSolucion({
    required this.coeficiente,
    required this.tipo,
    this.parametro = 0,
  });

  bool get esNulo => coeficiente.abs() < 1e-12;

  double evaluar(double t) {
    switch (tipo) {
      case TipoTermino.constante:
        return coeficiente;
      case TipoTermino.lineal:
        return coeficiente * t;
      case TipoTermino.cuadratico:
        return coeficiente * t * t;
      case TipoTermino.exponencial:
        return coeficiente * math.exp(parametro * t);
      case TipoTermino.exponencialLineal:
        return coeficiente * t * math.exp(parametro * t);
      case TipoTermino.seno:
        return coeficiente * math.sin(parametro * t);
      case TipoTermino.coseno:
        return coeficiente * math.cos(parametro * t);
    }
  }

  double evaluarDerivada(double t) {
    switch (tipo) {
      case TipoTermino.constante:
        return 0;
      case TipoTermino.lineal:
        return coeficiente;
      case TipoTermino.cuadratico:
        return 2 * coeficiente * t;
      case TipoTermino.exponencial:
        return coeficiente * parametro * math.exp(parametro * t);
      case TipoTermino.exponencialLineal:
        return coeficiente * math.exp(parametro * t) * (1 + parametro * t);
      case TipoTermino.seno:
        return coeficiente * parametro * math.cos(parametro * t);
      case TipoTermino.coseno:
        return -coeficiente * parametro * math.sin(parametro * t);
    }
  }

  List<TerminoSolucion> derivar() {
    switch (tipo) {
      case TipoTermino.constante:
        return const [];
      case TipoTermino.lineal:
        return [
          TerminoSolucion(
            coeficiente: coeficiente,
            tipo: TipoTermino.constante,
          ),
        ];
      case TipoTermino.cuadratico:
        return [
          TerminoSolucion(
            coeficiente: 2 * coeficiente,
            tipo: TipoTermino.lineal,
          ),
        ];
      case TipoTermino.exponencial:
        return [
          TerminoSolucion(
            coeficiente: coeficiente * parametro,
            tipo: TipoTermino.exponencial,
            parametro: parametro,
          ),
        ];
      case TipoTermino.exponencialLineal:
        return [
          TerminoSolucion(
            coeficiente: coeficiente,
            tipo: TipoTermino.exponencial,
            parametro: parametro,
          ),
          TerminoSolucion(
            coeficiente: coeficiente * parametro,
            tipo: TipoTermino.exponencialLineal,
            parametro: parametro,
          ),
        ];
      case TipoTermino.seno:
        return [
          TerminoSolucion(
            coeficiente: coeficiente * parametro,
            tipo: TipoTermino.coseno,
            parametro: parametro,
          ),
        ];
      case TipoTermino.coseno:
        return [
          TerminoSolucion(
            coeficiente: -coeficiente * parametro,
            tipo: TipoTermino.seno,
            parametro: parametro,
          ),
        ];
    }
  }

  TerminoSolucion escalar(double factor) {
    return TerminoSolucion(
      coeficiente: coeficiente * factor,
      tipo: tipo,
      parametro: parametro,
    );
  }

  String expresion(String variable) {
    final valor = _numero(coeficiente.abs());
    switch (tipo) {
      case TipoTermino.constante:
        return valor;
      case TipoTermino.lineal:
        return '$valor*$variable';
      case TipoTermino.cuadratico:
        return '$valor*$variable*$variable';
      case TipoTermino.exponencial:
        return '$valor*exp(${_numero(parametro)}*$variable)';
      case TipoTermino.exponencialLineal:
        return '$valor*$variable*exp(${_numero(parametro)}*$variable)';
      case TipoTermino.seno:
        return '$valor*sin(${_numero(parametro)}*$variable)';
      case TipoTermino.coseno:
        return '$valor*cos(${_numero(parametro)}*$variable)';
    }
  }

  static String _numero(double valor) {
    final texto = valor.toString();
    return texto.contains('e') ? valor.toStringAsFixed(12) : texto;
  }
}

List<TerminoSolucion> combinarTerminos(List<TerminoSolucion> terminos) {
  final resultado = <TerminoSolucion>[];
  for (final termino in terminos) {
    final indice = resultado.indexWhere(
      (existente) =>
          existente.tipo == termino.tipo &&
          (existente.parametro - termino.parametro).abs() < 1e-9,
    );
    if (indice < 0) {
      resultado.add(termino);
    } else {
      final existente = resultado[indice];
      resultado[indice] = TerminoSolucion(
        coeficiente: existente.coeficiente + termino.coeficiente,
        tipo: existente.tipo,
        parametro: existente.parametro,
      );
    }
  }
  return [
    for (final termino in resultado)
      if (!termino.esNulo) termino,
  ];
}

double evaluarTerminos(List<TerminoSolucion> terminos, double t) {
  var total = 0.0;
  for (final termino in terminos) {
    total += termino.evaluar(t);
  }
  return total;
}

String formatearExpresion(List<TerminoSolucion> terminos, String variable) {
  final visibles = combinarTerminos(terminos);
  if (visibles.isEmpty) return '0';
  final buffer = StringBuffer();
  for (var i = 0; i < visibles.length; i++) {
    final termino = visibles[i];
    if (i == 0) {
      if (termino.coeficiente < 0) buffer.write('-');
    } else {
      buffer.write(termino.coeficiente < 0 ? ' - ' : ' + ');
    }
    buffer.write(termino.expresion(variable));
  }
  return buffer.toString();
}

enum EstadoSolucionGeneral { ok, noSoportado }

class PasosSolucionAnalitica {
  final String edo;
  final double a;
  final double b;
  final double c;
  final double? r1;
  final double? r2;
  final Map<String, double> coeficientesParticulares;
  final double? c1Homogenea;
  final double? c2Homogenea;

  const PasosSolucionAnalitica({
    required this.edo,
    required this.a,
    required this.b,
    required this.c,
    this.r1,
    this.r2,
    this.coeficientesParticulares = const {},
    this.c1Homogenea,
    this.c2Homogenea,
  });
}

class SolucionGeneral {
  final EstadoSolucionGeneral estado;
  final String? motivo;
  final String variable;
  final List<TerminoSolucion> terminosV1;
  final List<TerminoSolucion> terminosX;
  final List<TerminoSolucion> terminosY;
  final PasosSolucionAnalitica pasos;

  const SolucionGeneral({
    required this.estado,
    required this.pasos,
    required this.terminosV1,
    required this.terminosX,
    required this.terminosY,
    this.motivo,
    this.variable = 't',
  });

  factory SolucionGeneral.noSoportado({
    required String motivo,
    required PasosSolucionAnalitica pasos,
    required List<TerminoSolucion> terminosV1,
    String variable = 't',
  }) {
    return SolucionGeneral(
      estado: EstadoSolucionGeneral.noSoportado,
      motivo: motivo,
      variable: variable,
      terminosV1: terminosV1,
      terminosX: const [],
      terminosY: const [],
      pasos: pasos,
    );
  }

  bool get soportada => estado == EstadoSolucionGeneral.ok;

  double evaluarV1(double t) => evaluarTerminos(terminosV1, t);

  double evaluarX(double t) => evaluarTerminos(terminosX, t);

  double evaluarY(double t) => evaluarTerminos(terminosY, t);

  double evaluarDerivadaV1(double t) => _evaluarDerivadas(terminosV1, t);

  double evaluarDerivadaX(double t) => _evaluarDerivadas(terminosX, t);

  double evaluarDerivadaY(double t) => _evaluarDerivadas(terminosY, t);

  static double _evaluarDerivadas(List<TerminoSolucion> terminos, double t) {
    var total = 0.0;
    for (final termino in terminos) {
      total += termino.evaluarDerivada(t);
    }
    return total;
  }

  String get expresionV1 => formatearExpresion(terminosV1, variable);

  String get expresionX => formatearExpresion(terminosX, variable);

  String get expresionY => formatearExpresion(terminosY, variable);

  SolucionAnalitica aSolucionAnalitica({
    required int version,
    required String unidadTiempo,
  }) {
    return SolucionAnalitica(
      version: version,
      unidadTiempo: unidadTiempo,
      variable: variable,
      expresionX: expresionX,
      expresionY: expresionY,
    );
  }
}
