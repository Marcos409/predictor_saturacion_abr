import 'json_helpers.dart';

class SolucionAnalitica {
  final int version;
  final String unidadTiempo;
  final String variable;
  final String expresionX;
  final String expresionY;

  const SolucionAnalitica({
    required this.version,
    required this.unidadTiempo,
    required this.variable,
    required this.expresionX,
    required this.expresionY,
  });

  factory SolucionAnalitica.fromJson(Map<String, dynamic> json) {
    return SolucionAnalitica(
      version: numeroJson(json['version'], 'version').toInt(),
      unidadTiempo: textoJson(json['unidad_tiempo'], 'unidad_tiempo'),
      variable: textoJson(json['variable'], 'variable'),
      expresionX: textoJson(json['x'], 'x'),
      expresionY: textoJson(json['y'], 'y'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'unidad_tiempo': unidadTiempo,
      'variable': variable,
      'x': expresionX,
      'y': expresionY,
    };
  }
}
