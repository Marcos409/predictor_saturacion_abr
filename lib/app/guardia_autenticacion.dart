import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/pantalla_login.dart';
import 'estructura_principal.dart';
import 'sesion.dart';

/// Guarda de acceso: sin sesión activa solo se muestra el login; con sesión
/// se muestra la aplicación completa. La sesión vive en memoria, así que al
/// recargar la página se vuelve a pedir el acceso.
class GuardiaAutenticacion extends StatelessWidget {
  const GuardiaAutenticacion({super.key});

  @override
  Widget build(BuildContext context) {
    final autenticado = context.watch<Sesion>().autenticado;
    if (!autenticado) return const PantallaLogin();
    return const EstructuraPrincipal();
  }
}
