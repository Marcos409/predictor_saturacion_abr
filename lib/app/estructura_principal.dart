import 'package:flutter/material.dart';

import '../features/alertas_autoscaling/pantalla_alertas_autoscaling.dart';
import '../features/configuracion/pantalla_configuracion.dart';
import '../features/dashboard/pantalla_dashboard.dart';
import '../features/escenarios/pantalla_escenarios.dart';
import '../features/fase1_trafico/pantalla_fase1_trafico.dart';
import '../features/fase2_servidores/pantalla_fase2_servidores.dart';
import '../features/matematica/pantalla_matematica.dart';
import '../features/resultados/pantalla_resultados.dart';
import '../features/simulacion_vivo/pantalla_simulacion_vivo.dart';
import '../features/verificacion_abr/pantalla_verificacion_abr.dart';
import 'barra_lateral.dart';
import 'contenido_modulo.dart';
import 'modulos.dart';
import 'tema.dart';

class EstructuraPrincipal extends StatefulWidget {
  const EstructuraPrincipal({super.key});

  @override
  State<EstructuraPrincipal> createState() => _EstructuraPrincipalState();
}

class _EstructuraPrincipalState extends State<EstructuraPrincipal> {
  static const double _anchoMinimoEscritorio = 900;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _indiceSeleccionado = 0;

  void _seleccionarModulo(int indice) {
    setState(() => _indiceSeleccionado = indice);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Widget _construirVista(ModuloApp modulo) {
    return switch (modulo.id) {
      'dashboard' => const PantallaDashboard(),
      'escenarios' => const PantallaEscenarios(),
      'fase1_trafico' => const PantallaFase1Trafico(),
      'fase2_servidores' => const PantallaFase2Servidores(),
      'simulacion_vivo' => const PantallaSimulacionVivo(),
      'alertas_autoscaling' => const PantallaAlertasAutoScaling(),
      'resultados' => const PantallaResultados(),
      'matematica' => const PantallaMatematica(),
      'verificacion_abr' => const PantallaVerificacionAbr(),
      'configuracion' => const PantallaConfiguracion(),
      _ => ContenidoModulo(modulo: modulo),
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final esEscritorio = restricciones.maxWidth >= _anchoMinimoEscritorio;
        final modulo = modulosApp[_indiceSeleccionado];

        if (esEscritorio) {
          return Scaffold(
            body: Row(
              children: [
                BarraLateral(
                  indiceSeleccionado: _indiceSeleccionado,
                  alSeleccionar: _seleccionarModulo,
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColores.borde)),
                    ),
                    child: _construirVista(modulo),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Abrir menú',
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu),
            ),
            title: const Text(
              'TI-Saturation Predictor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          drawer: Drawer(
            child: BarraLateral(
              indiceSeleccionado: _indiceSeleccionado,
              alSeleccionar: _seleccionarModulo,
            ),
          ),
          body: _construirVista(modulo),
        );
      },
    );
  }
}
