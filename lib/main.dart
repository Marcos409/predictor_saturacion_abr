import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/estado_aplicacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final estado = await EstadoAplicacion.cargar();
  runApp(AplicacionSaturacion(estado: estado));
}
