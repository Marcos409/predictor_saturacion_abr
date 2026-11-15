import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'estado_aplicacion.dart';
import 'guardia_autenticacion.dart';
import 'sesion.dart';
import 'tema.dart';
import 'usuarios.dart';

class AplicacionSaturacion extends StatelessWidget {
  final EstadoAplicacion estado;
  final RepositorioUsuarios usuarios;
  final Sesion sesion;

  const AplicacionSaturacion({
    super.key,
    required this.estado,
    required this.usuarios,
    required this.sesion,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EstadoAplicacion>.value(value: estado),
        ChangeNotifierProvider<Sesion>.value(value: sesion),
        Provider<RepositorioUsuarios>.value(value: usuarios),
      ],
      child: MaterialApp(
        title: 'TI-Saturation Predictor',
        debugShowCheckedModeBanner: false,
        theme: construirTemaClaro(),
        home: const GuardiaAutenticacion(),
      ),
    );
  }
}
