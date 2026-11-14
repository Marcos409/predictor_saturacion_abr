import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/evento_simulacion.dart';
import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';
import '../../app/widgets/tarjeta_indicador.dart';

class PantallaAlertasAutoScaling extends StatelessWidget {
  const PantallaAlertasAutoScaling({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final configuracion = estado.sistema.autoScaling;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoPantalla(
              titulo: 'Alertas y Auto-Scaling',
              descripcion:
                  'Avisos por umbral, alerta crítica y escalado automático o manual.',
            ),
            const SizedBox(height: 24),
            if (estado.error != null) ...[
              MensajeError(mensaje: estado.error!),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, restricciones) {
                final tarjetas = [
                  TarjetaIndicador(
                    titulo: 'AVISO TEMPRANO · CAPA WEB',
                    valor: estado.avisoWeb ? 'Activo' : 'Sin aviso',
                    detalle:
                        'Umbral ${formatearNumero(estado.sistema.umbralAlerta * 100, decimales: 0)} % '
                        'de la capacidad efectiva.',
                    icono: Icons.water_drop_outlined,
                    color: estado.avisoWeb ? ColoresApp.aviso : ColoresApp.ok,
                  ),
                  TarjetaIndicador(
                    titulo: 'AVISO TEMPRANO · BASE DE DATOS',
                    valor: estado.avisoBaseDatos ? 'Activo' : 'Sin aviso',
                    detalle:
                        'Umbral ${formatearNumero(estado.sistema.umbralAlerta * 100, decimales: 0)} % '
                        'de la capacidad efectiva.',
                    icono: Icons.storage_outlined,
                    color: estado.avisoBaseDatos
                        ? ColoresApp.aviso
                        : ColoresApp.ok,
                  ),
                  TarjetaIndicador(
                    titulo: 'ALERTA CRÍTICA',
                    valor: estado.alertaCritica
                        ? 'Ventana negativa'
                        : 'Sin alerta',
                    detalle: estado.ventanaAccion?.ventanaAccion == null
                        ? 'Sin colapso en el horizonte simulado.'
                        : 'Ventana de Acción: '
                              '${formatearNumero(estado.ventanaAccion!.ventanaAccion!)} min.',
                    icono: Icons.warning_amber_rounded,
                    color: estado.alertaCritica
                        ? ColoresApp.alerta
                        : ColoresApp.ok,
                  ),
                ];
                if (restricciones.maxWidth >= 980) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < tarjetas.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: tarjetas[i]),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < tarjetas.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      tarjetas[i],
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            PanelSeccion(
              titulo: 'Modo de Auto-Scaling',
              subtitulo:
                  'Automático: escala al saltar el aviso, tras un retraso. '
                  'Manual: tú decides cuándo escalar.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ModoAutoScaling>(
                    segments: const [
                      ButtonSegment(
                        value: ModoAutoScaling.automatico,
                        label: Text('Automático'),
                        icon: Icon(Icons.autorenew_rounded),
                      ),
                      ButtonSegment(
                        value: ModoAutoScaling.manual,
                        label: Text('Manual'),
                        icon: Icon(Icons.pan_tool_alt_outlined),
                      ),
                    ],
                    selected: {estado.modoAutoScaling},
                    onSelectionChanged: (seleccion) => context
                        .read<EstadoAplicacion>()
                        .cambiarModoAutoScaling(seleccion.first),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DatoConfiguracion(
                        etiqueta: 'Incremento',
                        valor: formatearNumero(
                          configuracion.incrementoCapacidad,
                        ),
                      ),
                      _DatoConfiguracion(
                        etiqueta: 'Retraso',
                        valor: '${formatearNumero(configuracion.retraso)} min',
                      ),
                      _DatoConfiguracion(
                        etiqueta: 'Máximo de escalados',
                        valor: '${configuracion.maximoEscalados}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, restricciones) {
                final paneles = [
                  _PanelEscalado(
                    nombre: 'Capa Web',
                    capacidadBase: estado.sistema.capacidades.capaWeb,
                    capacidadEfectiva: estado.capacidadWebEfectiva,
                    escalados: estado.escaladosWeb,
                    maximo: configuracion.maximoEscalados,
                    color: ColoresApp.acento,
                    alEscalar: () =>
                        context.read<EstadoAplicacion>().escalar('capa_web'),
                  ),
                  _PanelEscalado(
                    nombre: 'Base de Datos',
                    capacidadBase: estado.sistema.capacidades.baseDatos,
                    capacidadEfectiva: estado.capacidadBaseDatosEfectiva,
                    escalados: estado.escaladosBaseDatos,
                    maximo: configuracion.maximoEscalados,
                    color: ColoresApp.aviso,
                    alEscalar: () =>
                        context.read<EstadoAplicacion>().escalar('base_datos'),
                  ),
                ];
                if (restricciones.maxWidth >= 760) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: paneles[0]),
                      const SizedBox(width: 20),
                      Expanded(child: paneles[1]),
                    ],
                  );
                }
                return Column(
                  children: [
                    paneles[0],
                    const SizedBox(height: 16),
                    paneles[1],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            PanelSeccion(
              titulo: 'Registro de eventos',
              subtitulo:
                  'Cada evento queda marcado con el minuto de simulación en que ocurrió.',
              child: estado.eventos.isEmpty
                  ? const Text(
                      'Sin eventos todavía. Reproduce la simulación o escala manualmente.',
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 12,
                      ),
                    )
                  : Column(
                      children: [
                        for (final evento in estado.eventos)
                          _EventoFila(evento: evento),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelEscalado extends StatelessWidget {
  final String nombre;
  final double capacidadBase;
  final double capacidadEfectiva;
  final int escalados;
  final int maximo;
  final Color color;
  final VoidCallback alEscalar;

  const _PanelEscalado({
    required this.nombre,
    required this.capacidadBase,
    required this.capacidadEfectiva,
    required this.escalados,
    required this.maximo,
    required this.color,
    required this.alEscalar,
  });

  @override
  Widget build(BuildContext context) {
    final alcanzoMaximo = escalados >= maximo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresApp.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: const TextStyle(
              color: ColoresApp.textoPrimario,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DatoConfiguracion(
                  etiqueta: 'Capacidad actual',
                  valor: formatearNumero(capacidadEfectiva),
                ),
              ),
              Expanded(
                child: _DatoConfiguracion(
                  etiqueta: 'Base',
                  valor: formatearNumero(capacidadBase),
                ),
              ),
              Expanded(
                child: _DatoConfiguracion(
                  etiqueta: 'Escalados',
                  valor: '$escalados / $maximo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: alcanzoMaximo ? null : alEscalar,
              style: FilledButton.styleFrom(backgroundColor: color),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                alcanzoMaximo ? 'Máximo alcanzado' : 'Escalar $nombre',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoConfiguracion extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoConfiguracion({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EventoFila extends StatelessWidget {
  final EventoSimulacion evento;

  const _EventoFila({required this.evento});

  @override
  Widget build(BuildContext context) {
    final (color, icono) = switch (evento.tipo) {
      TipoEventoSimulacion.aviso => (
        ColoresApp.aviso,
        Icons.notifications_active_outlined,
      ),
      TipoEventoSimulacion.critico => (
        ColoresApp.alerta,
        Icons.warning_amber_rounded,
      ),
      TipoEventoSimulacion.escalado => (
        ColoresApp.acento,
        Icons.arrow_upward_rounded,
      ),
      TipoEventoSimulacion.sistema => (
        ColoresApp.textoSecundario,
        Icons.info_outline,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresApp.fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresApp.borde),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'T+${formatearNumero(evento.minuto)} min',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icono, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              evento.mensaje,
              style: const TextStyle(
                color: ColoresApp.textoPrimario,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
