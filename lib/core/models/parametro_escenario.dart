import 'json_helpers.dart';

class ParametroEscenario {
  final String clave;
  final String nombre;
  final double valor;

  const ParametroEscenario({
    required this.clave,
    required this.nombre,
    required this.valor,
  });

  factory ParametroEscenario.fromJson(Map<String, dynamic> json) {
    return ParametroEscenario(
      clave: textoJson(json['clave'], 'clave'),
      nombre: textoJson(json['nombre'], 'nombre'),
      valor: numeroJson(json['valor'], 'valor'),
    );
  }

  ParametroEscenario copyWith({double? valor}) {
    return ParametroEscenario(
      clave: clave,
      nombre: nombre,
      valor: valor ?? this.valor,
    );
  }

  Map<String, dynamic> toJson() {
    return {'clave': clave, 'nombre': nombre, 'valor': valor};
  }
}
