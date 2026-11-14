import 'dart:convert';
import 'dart:io';

import 'package:predictor_saturacion_abr/core/models/escenario_trafico.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_analitica.dart';

Map<String, dynamic> leerJson(String nombre) {
  final contenido = File('assets/config/$nombre').readAsStringSync();
  return jsonDecode(contenido) as Map<String, dynamic>;
}

ConfiguracionSistema cargarSistema() {
  return ConfiguracionSistema.fromJson(leerJson('sistema.json'));
}

ConfiguracionEscenarios cargarEscenarios() {
  return ConfiguracionEscenarios.fromJson(leerJson('escenarios.json'));
}

SolucionAnalitica cargarSolucionAnalitica() {
  return SolucionAnalitica.fromJson(leerJson('soluciones.json'));
}

String leerSolucionAnaliticaCruda() {
  return File('assets/config/soluciones.json').readAsStringSync();
}
