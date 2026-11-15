import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/semaforo.dart';
import '../../app/tema.dart';
import '../../app/widgets/contenedor_modulo.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/grafico_series.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';
import '../../app/widgets/tarjeta_indicador.dart';
import '../../core/models/punto_entrada.dart';

class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final resultado = estado.resultado;
    final sistema = estado.sistema;
    final ventana = estado.ventanaAccion?.ventanaAccion;
    final nivel = estado.nivelSemaforo;

    final colorVentana = switch (nivel) {
      NivelSemaforo.critico => AppColores.importante,
      NivelSemaforo.precaucion => AppColores.secundarioTexto,
      NivelSemaforo.estable => AppColores.exito,
      NivelSemaforo.sinColapso => AppColores.exito,
    };

    final serieX = <PuntoEntrada>[
      if (resultado != null)
        for (final punto in resultado.puntos)
          PuntoEntrada(t: punto.t, valor: punto.x),
    ];
    final serieY = <PuntoEntrada>[
      if (resultado != null)
        for (final punto in resultado.puntos)
          PuntoEntrada(t: punto.t, valor: punto.y),
    ];

    final marcadores = <MarcadorVertical>[
      if (sistema.tiempoReaccion <= estado.horizonteActivo)
        MarcadorVertical(
          tiempo: sistema.tiempoReaccion,
          etiqueta: 'Reacción TI',
          color: AppColores.secundario,
        ),
    ];

    final tarjetas = [
      TarjetaIndicador(
        titulo: 'COLAPSO CAPA WEB',
        valor: estado.colapsoCapaWeb?.tiempo == null
            ? 'No colapsa'
            : '${formatearNumero(estado.colapsoCapaWeb!.tiempo!)} min',
        detalle:
            'Límite efectivo: ${formatearNumero(estado.capacidadWebEfectiva)}.',
        icono: Icons.language_outlined,
        color: estado.colapsoCapaWeb?.tiempo == null
            ? AppColores.exito
            : AppColores.primarioOscuro,
      ),
      TarjetaIndicador(
        titulo: 'COLAPSO BASE DE DATOS',
        valor: estado.colapsoBaseDatos?.tiempo == null
            ? 'No colapsa'
            : '${formatearNumero(estado.colapsoBaseDatos!.tiempo!)} min',
        detalle:
            'Límite efectivo: ${formatearNumero(estado.capacidadBaseDatosEfectiva)}.',
        icono: Icons.storage_outlined,
        color: estado.colapsoBaseDatos?.tiempo == null
            ? AppColores.exito
            : AppColores.graficoBD,
      ),
      TarjetaIndicador(
        titulo: 'VENTANA DE ACCIÓN',
        valor: ventana == null
            ? 'Sin colapso'
            : '${formatearNumero(ventana)} min',
        detalle:
            'Reacción de TI: ${formatearNumero(sistema.tiempoReaccion)} min · '
            '${etiquetaNivelSemaforo(nivel)}.',
        icono: Icons.schedule_outlined,
        color: ventana == null ? AppColores.exito : colorVentana,
      ),
      TarjetaIndicador(
        titulo: 'AUTO-SCALING',
        valor: estado.modoAutoScaling == ModoAutoScaling.automatico
            ? 'Automático'
            : 'Manual',
        detalle:
            'Escalados Web ${estado.escaladosWeb} · BD '
            '${estado.escaladosBaseDatos}. Capacidades: '
            '${formatearNumero(estado.capacidadWebEfectiva)} / '
            '${formatearNumero(estado.capacidadBaseDatosEfectiva)}.',
        icono: Icons.autorenew_rounded,
        color: estado.escaladosWeb + estado.escaladosBaseDatos > 0
            ? AppColores.secundarioTexto
            : AppColores.primarioOscuro,
      ),
    ];

    return ContenedorModulo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoPantalla(
            titulo: 'Dashboard',
            descripcion:
                'Escenario ${estado.escenarioActivo.nombre}. Resumen de colapsos y '
                'comportamiento de los tanques.',
          ),
          const SizedBox(height: 24),
          if (estado.error != null) ...[
            MensajeError(mensaje: estado.error!),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, restricciones) {
              final columnas = restricciones.maxWidth >= 1100
                  ? 4
                  : restricciones.maxWidth >= 680
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tarjetas.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 176,
                ),
                itemBuilder: (context, indice) => tarjetas[indice],
              );
            },
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Evolución de los tanques',
            subtitulo:
                'x(t) y y(t) con sus límites efectivos y la línea de reacción de TI.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GraficoSeries(
                  series: [
                    SerieGrafico(
                      nombre: 'Capa Web x(t)',
                      puntos: serieX,
                      color: AppColores.grafico,
                    ),
                    SerieGrafico(
                      nombre: 'Base de Datos y(t)',
                      puntos: serieY,
                      color: AppColores.graficoBD,
                    ),
                  ],
                  limites: [
                    LineaLimite(
                      valor: estado.capacidadWebEfectiva,
                      etiqueta: 'Límite Web',
                      color: AppColores.importante,
                    ),
                    LineaLimite(
                      valor: estado.capacidadBaseDatosEfectiva,
                      etiqueta: 'Límite BD',
                      color: AppColores.importante,
                    ),
                  ],
                  marcadores: marcadores,
                  altura: 320,
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _Leyenda(
                      color: AppColores.grafico,
                      texto: 'x(t) · Capa Web',
                    ),
                    _Leyenda(
                      color: AppColores.graficoBD,
                      texto: 'y(t) · Base de Datos',
                    ),
                    _Leyenda(
                      color: AppColores.secundario,
                      texto: 'Reacción de TI',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
