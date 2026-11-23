import 'dart:math' as math;

import 'escenario_trafico.dart';
import 'json_helpers.dart';
import 'sistema.dart';

Map<String, double>? _mapaNumerosOpcional(dynamic valor, String campo) {
  if (valor == null) return null;
  if (valor is! Map) {
    throw FormatException('El campo "$campo" debe ser un objeto');
  }
  return {
    for (final entrada in valor.entries)
      '${entrada.key}': numeroJson(entrada.value, '$campo.${entrada.key}'),
  };
}

String? _textoOpcional(dynamic valor, String campo) {
  return valor == null ? null : textoJson(valor, campo);
}

bool _cerca(double a, double b) {
  return (a - b).abs() <= 1e-9 * math.max(1.0, math.max(a.abs(), b.abs()));
}

class SolucionAnalitica {
  final int version;
  final String unidadTiempo;
  final String variable;
  final String expresionX;
  final String expresionY;
  final String? idEscenario;
  final Map<String, double>? parametros;

  const SolucionAnalitica({
    required this.version,
    required this.unidadTiempo,
    required this.variable,
    required this.expresionX,
    required this.expresionY,
    this.idEscenario,
    this.parametros,
  });

  factory SolucionAnalitica.fromJson(Map<String, dynamic> json) {
    return SolucionAnalitica(
      version: numeroJson(json['version'], 'version').toInt(),
      unidadTiempo: textoJson(json['unidad_tiempo'], 'unidad_tiempo'),
      variable: textoJson(json['variable'], 'variable'),
      expresionX: textoJson(json['x'], 'x'),
      expresionY: textoJson(json['y'], 'y'),
      idEscenario: _textoOpcional(
        json['escenario_id'] ?? json['id_escenario'],
        'escenario_id',
      ),
      parametros: _mapaNumerosOpcional(json['parametros'], 'parametros'),
    );
  }

  static Map<String, double> parametrosAplicables({
    required EscenarioTrafico escenario,
    required ConfiguracionSistema configuracion,
  }) {
    final tanques = configuracion.tanques;
    final coeficientes = configuracion.coeficientes;
    final iniciales = configuracion.condicionesIniciales;
    final horizonte = escenario.tiempoMaxMin > 0
        ? escenario.tiempoMaxMin
        : configuracion.simulacion.tiempoFinal;
    return {
      ...escenario.mapaParametros,
      'tiempo_max_min': horizonte,
      'c1': tanques.c1,
      'volumen_A': tanques.volumenA,
      'volumen_B': tanques.volumenB,
      'A_a_B': tanques.caudales.aAB,
      'A_salida': tanques.caudales.aSalida,
      'B_a_A': tanques.caudales.bAA,
      'B_salida': tanques.caudales.bSalida,
      'a11': coeficientes.a11,
      'a12': coeficientes.a12,
      'a21': coeficientes.a21,
      'a22': coeficientes.a22,
      'x0': iniciales.x0,
      'y0': iniciales.y0,
    };
  }

  bool aplicaA({
    required EscenarioTrafico escenario,
    required ConfiguracionSistema configuracion,
  }) {
    final id = idEscenario;
    final parametrosDeclarados = parametros;
    if (id == null || id != escenario.id || parametrosDeclarados == null) {
      return false;
    }
    final esperados = parametrosAplicables(
      escenario: escenario,
      configuracion: configuracion,
    );
    for (final parametro in escenario.parametros) {
      final valor = parametrosDeclarados[parametro.clave];
      if (valor == null || !_cerca(valor, parametro.valor)) return false;
    }
    for (final entrada in parametrosDeclarados.entries) {
      final esperado = esperados[entrada.key];
      if (esperado == null || !_cerca(entrada.value, esperado)) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'unidad_tiempo': unidadTiempo,
      'variable': variable,
      'x': expresionX,
      'y': expresionY,
      if (idEscenario != null) 'escenario_id': idEscenario,
      if (parametros != null) 'parametros': parametros,
    };
  }
}
