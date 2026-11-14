import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/referencia_abr.dart';

class CargadorReferenciaAbr {
  static const String rutaAsset = 'assets/config/referencia_abr.json';

  final AssetBundle? _bundle;

  const CargadorReferenciaAbr({AssetBundle? bundle}) : _bundle = bundle;

  Future<ReferenciaAbr> cargar() async {
    final bundle = _bundle ?? rootBundle;
    final contenido = await bundle.loadString(rutaAsset);
    return desdeJson(contenido);
  }

  static ReferenciaAbr desdeJson(String contenido) {
    final mapa = jsonDecode(contenido);
    if (mapa is! Map<String, dynamic>) {
      throw const FormatException('La referencia ABR debe ser un objeto JSON');
    }
    return ReferenciaAbr.fromJson(mapa);
  }
}
