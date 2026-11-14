import 'json_helpers.dart';
import 'parametro_escenario.dart';

class EscenarioTrafico {
  final String id;
  final String nombre;
  final String edo;
  final List<ParametroEscenario> parametros;
  final String expresionV1;
  final double tiempoMaxMin;

  const EscenarioTrafico({
    required this.id,
    required this.nombre,
    required this.edo,
    required this.parametros,
    required this.expresionV1,
    required this.tiempoMaxMin,
  });

  Map<String, double> get mapaParametros => {
    for (final parametro in parametros) parametro.clave: parametro.valor,
  };

  factory EscenarioTrafico.fromJson(Map<String, dynamic> json) {
    final parametros = listaJson(json['parametros'], 'parametros')
        .map((e) => ParametroEscenario.fromJson(mapaJson(e, 'parametro')))
        .toList();
    return EscenarioTrafico(
      id: textoJson(json['id'], 'id'),
      nombre: textoJson(json['nombre'], 'nombre'),
      edo: textoJson(json['edo'], 'edo'),
      parametros: parametros,
      expresionV1: textoJson(json['v1'], 'v1'),
      tiempoMaxMin: numeroJson(json['tiempo_max_min'], 'tiempo_max_min'),
    );
  }

  EscenarioTrafico copyWith({
    List<ParametroEscenario>? parametros,
    double? tiempoMaxMin,
  }) {
    return EscenarioTrafico(
      id: id,
      nombre: nombre,
      edo: edo,
      parametros: parametros ?? this.parametros,
      expresionV1: expresionV1,
      tiempoMaxMin: tiempoMaxMin ?? this.tiempoMaxMin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'edo': edo,
      'parametros': parametros.map((parametro) => parametro.toJson()).toList(),
      'v1': expresionV1,
      'tiempo_max_min': tiempoMaxMin,
    };
  }
}

class ConfiguracionEscenarios {
  final int version;
  final String unidadTiempo;
  final String variable;
  final List<EscenarioTrafico> escenarios;

  const ConfiguracionEscenarios({
    required this.version,
    required this.unidadTiempo,
    required this.variable,
    required this.escenarios,
  });

  factory ConfiguracionEscenarios.fromJson(Map<String, dynamic> json) {
    final escenarios = listaJson(
      json['escenarios'],
      'escenarios',
    ).map((e) => EscenarioTrafico.fromJson(mapaJson(e, 'escenario'))).toList();
    return ConfiguracionEscenarios(
      version: numeroJson(json['version'], 'version').toInt(),
      unidadTiempo: textoJson(json['unidad_tiempo'], 'unidad_tiempo'),
      variable: textoJson(json['variable'], 'variable'),
      escenarios: escenarios,
    );
  }

  EscenarioTrafico? buscarPorId(String id) {
    for (final escenario in escenarios) {
      if (escenario.id == id) return escenario;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'unidad_tiempo': unidadTiempo,
      'variable': variable,
      'escenarios': escenarios.map((escenario) => escenario.toJson()).toList(),
    };
  }
}
