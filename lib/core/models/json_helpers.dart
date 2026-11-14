double numeroJson(dynamic valor, String campo) {
  if (valor is num) return valor.toDouble();
  if (valor is String) {
    final parseado = double.tryParse(valor);
    if (parseado != null) return parseado;
  }
  throw FormatException('El campo "$campo" debe ser numérico');
}

Map<String, dynamic> mapaJson(dynamic valor, String campo) {
  if (valor is Map<String, dynamic>) return valor;
  if (valor is Map) return Map<String, dynamic>.from(valor);
  throw FormatException('El campo "$campo" debe ser un objeto');
}

List<dynamic> listaJson(dynamic valor, String campo) {
  if (valor is List) return valor;
  throw FormatException('El campo "$campo" debe ser una lista');
}

String textoJson(dynamic valor, String campo) {
  if (valor is String) return valor;
  throw FormatException('El campo "$campo" debe ser texto');
}
