import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/estado_aplicacion.dart';
import 'app/sesion.dart';
import 'app/usuarios.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final estado = await EstadoAplicacion.cargar();
  final usuarios = await RepositorioUsuarios.cargar();
  runApp(
    AplicacionSaturacion(estado: estado, usuarios: usuarios, sesion: Sesion()),
  );
}
