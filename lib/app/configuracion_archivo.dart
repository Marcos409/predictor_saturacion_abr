import 'dart:convert';

import '../core/models/escenario_trafico.dart';
import '../core/models/sistema.dart';
import '../core/models/solucion_analitica.dart';

class ConfiguracionArchivo {
  final ConfiguracionSistema sistema;
  final ConfiguracionEscenarios escenarios;
  final SolucionAnalitica solucionAnalitica;

  const ConfiguracionArchivo({
    required this.sistema,
    required this.escenarios,
    required this.solucionAnalitica,
  });

  factory ConfiguracionArchivo.desdeJson(String contenido) {
    if (contenido.trim().isEmpty) {
      throw const FormatException('El archivo está vacío.');
    }

    final dynamic decodificado;
    try {
      decodificado = jsonDecode(contenido);
    } on FormatException catch (error) {
      throw FormatException(
        'El archivo no es un JSON válido: ${error.message}',
      );
    }

    if (decodificado is! Map) {
      throw const FormatException('La raíz del JSON debe ser un objeto.');
    }
    final mapa = Map<String, dynamic>.from(decodificado);

    return ConfiguracionArchivo(
      sistema: _leerSeccion(
        mapa,
        'sistema',
        (seccion) => ConfiguracionSistema.fromJson(seccion),
      ),
      escenarios: _leerSeccion(
        mapa,
        'escenarios',
        (seccion) => ConfiguracionEscenarios.fromJson(seccion),
      ),
      solucionAnalitica: _leerSeccion(
        mapa,
        'soluciones',
        (seccion) => SolucionAnalitica.fromJson(seccion),
      ),
    );
  }

  static T _leerSeccion<T>(
    Map<String, dynamic> mapa,
    String clave,
    T Function(Map<String, dynamic> seccion) leer,
  ) {
    if (!mapa.containsKey(clave)) {
      throw FormatException('Falta la sección "$clave".');
    }
    final valor = mapa[clave];
    if (valor is! Map) {
      throw FormatException('La sección "$clave" debe ser un objeto.');
    }
    try {
      return leer(Map<String, dynamic>.from(valor));
    } on FormatException catch (error) {
      throw FormatException('Sección "$clave": ${error.message}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sistema': sistema.toJson(),
      'escenarios': escenarios.toJson(),
      'soluciones': solucionAnalitica.toJson(),
    };
  }

  String serializar() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
