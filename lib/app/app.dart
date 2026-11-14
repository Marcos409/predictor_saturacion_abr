import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'estado_aplicacion.dart';
import 'estructura_principal.dart';
import 'tema.dart';

class AplicacionSaturacion extends StatelessWidget {
  final EstadoAplicacion estado;

  const AplicacionSaturacion({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EstadoAplicacion>.value(
      value: estado,
      child: MaterialApp(
        title: 'TI-Saturation Predictor',
        debugShowCheckedModeBanner: false,
        theme: construirTemaOscuro(),
        home: const EstructuraPrincipal(),
      ),
    );
  }
}
