import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/diagrama_tubos.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/grafico_series.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';
import '../../core/models/punto_entrada.dart';

class PantallaSimulacionVivo extends StatelessWidget {
  const PantallaSimulacionVivo({super.key});

  static const List<double> _velocidades = [0.5, 1, 2, 4];

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final resultado = estado.resultado;
    final punto = estado.puntoVivo;

    final serieX = <PuntoEntrada>[
      if (resultado != null)
        for (final item in resultado.puntos)
          PuntoEntrada(t: item.t, valor: item.x),
    ];
    final serieY = <PuntoEntrada>[
      if (resultado != null)
        for (final item in resultado.puntos)
          PuntoEntrada(t: item.t, valor: item.y),
    ];

    final tanques = <Widget>[
      _Tanque(
        nombre: 'Capa Web',
        variable: 'x(t)',
        valor: punto?.x ?? 0,
        capacidad: estado.capacidadWebEfectiva,
        umbral: estado.sistema.umbralAlerta,
        color: ColoresApp.acento,
        caido: estado.capaWebCaida,
        tiempoCaida: estado.tiempoCaidaWeb,
        mostrarNotaTeorica: estado.continuarTrasColapso,
      ),
      _Tanque(
        nombre: 'Base de Datos',
        variable: 'y(t)',
        valor: punto?.y ?? 0,
        capacidad: estado.capacidadBaseDatosEfectiva,
        umbral: estado.sistema.umbralAlerta,
        color: ColoresApp.aviso,
        caido: estado.baseDatosCaida,
        tiempoCaida: estado.tiempoCaidaBaseDatos,
        mostrarNotaTeorica: estado.continuarTrasColapso,
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoPantalla(
              titulo: 'Simulación en vivo',
              descripcion:
                  'Los dos tanques se llenan según x(t) e y(t). Reproduce, pausa o cambia la velocidad.',
            ),
            const SizedBox(height: 24),
            if (estado.capaWebCaida) ...[
              _BannerColapso(
                minuto: estado.tiempoCaidaWeb!,
                ventana:
                    estado.ventanaAccionAlCaerWeb ??
                    estado.ventanaAccion?.ventanaAccion,
                continuar: estado.continuarTrasColapso,
              ),
              const SizedBox(height: 16),
            ],
            if (estado.error != null) ...[
              MensajeError(mensaje: estado.error!),
              const SizedBox(height: 16),
            ],
            PanelSeccion(
              titulo: 'Controles de reproducción',
              subtitulo:
                  'Tiempo simulado: ${formatearNumero(estado.tiempoVivo)} / '
                  '${formatearNumero(estado.horizonteActivo, decimales: 0)} min.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            estado.capaWebCaida && !estado.continuarTrasColapso
                            ? null
                            : () {
                                final accion = context.read<EstadoAplicacion>();
                                if (estado.reproduciendo) {
                                  accion.pausar();
                                } else {
                                  accion.reproducir();
                                }
                              },
                        icon: Icon(
                          estado.reproduciendo
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          estado.reproduciendo ? 'Pausar' : 'Reproducir',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.read<EstadoAplicacion>().reiniciar(),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Reiniciar'),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Velocidad',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                      for (final velocidad in _velocidades)
                        _BotonVelocidad(
                          velocidad: velocidad,
                          activa: estado.velocidad == velocidad,
                          alElegir: () => context
                              .read<EstadoAplicacion>()
                              .cambiarVelocidad(velocidad),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Continuar después del colapso (modo teórico)',
                      style: TextStyle(
                        color: ColoresApp.textoPrimario,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'Si está apagado, la simulación se pausa al caer la Capa Web.',
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                    value: estado.continuarTrasColapso,
                    onChanged: (valor) => context
                        .read<EstadoAplicacion>()
                        .cambiarContinuarTrasColapso(valor),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: estado.horizonteActivo <= 0
                          ? 0
                          : (estado.tiempoVivo / estado.horizonteActivo).clamp(
                              0.0,
                              1.0,
                            ),
                      backgroundColor: ColoresApp.fondo,
                      color: ColoresApp.acento,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, restricciones) {
                if (restricciones.maxWidth >= 760) {
                  return Row(
                    children: [
                      Expanded(child: tanques[0]),
                      const SizedBox(width: 20),
                      Expanded(child: tanques[1]),
                    ],
                  );
                }
                return Column(
                  children: [
                    tanques[0],
                    const SizedBox(height: 16),
                    tanques[1],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            PanelSeccion(
              titulo: 'Diagrama de tubos y flujos',
              subtitulo:
                  'Los tubos y su grosor reflejan los flujos en el instante actual.',
              child: DiagramaTubos(
                datos: DatosDiagramaTubos(
                  sistema: estado.sistema,
                  tiempo: estado.tiempoVivo,
                  x: punto?.x ?? 0,
                  y: punto?.y ?? 0,
                  entradaExterna:
                      estado.entradaEn(estado.tiempoVivo) *
                      estado.sistema.tanques.c1,
                  capacidadA: estado.capacidadWebEfectiva,
                  capacidadB: estado.capacidadBaseDatosEfectiva,
                  umbralAlerta: estado.sistema.umbralAlerta,
                  capaWebCaida: estado.capaWebCaida,
                  baseDatosCaida: estado.baseDatosCaida,
                  mostrarNotaTeorica: estado.continuarTrasColapso,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PanelSeccion(
              titulo: 'Curvas y límites',
              subtitulo:
                  'Las líneas horizontales muestran la capacidad efectiva; al escalar, suben.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GraficoSeries(
                    series: [
                      SerieGrafico(
                        nombre: 'Capa Web x(t)',
                        puntos: serieX,
                        color: ColoresApp.acento,
                      ),
                      SerieGrafico(
                        nombre: 'Base de Datos y(t)',
                        puntos: serieY,
                        color: ColoresApp.aviso,
                      ),
                    ],
                    limites: [
                      LineaLimite(
                        valor: estado.capacidadWebEfectiva,
                        etiqueta: 'Límite Web',
                        color: ColoresApp.acento,
                      ),
                      LineaLimite(
                        valor: estado.capacidadBaseDatosEfectiva,
                        etiqueta: 'Límite BD',
                        color: ColoresApp.aviso,
                      ),
                    ],
                    marcadores: [
                      MarcadorVertical(
                        tiempo: estado.tiempoVivo,
                        etiqueta: 'Ahora',
                        color: ColoresApp.textoPrimario,
                      ),
                      MarcadorVertical(
                        tiempo: estado.sistema.tiempoReaccion,
                        etiqueta: 'Reacción TI',
                        color: ColoresApp.alerta,
                      ),
                    ],
                    altura: 300,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: const [
                      _Leyenda(
                        color: ColoresApp.acento,
                        texto: 'x(t) · Capa Web',
                      ),
                      _Leyenda(
                        color: ColoresApp.aviso,
                        texto: 'y(t) · Base de Datos',
                      ),
                      _Leyenda(
                        color: ColoresApp.alerta,
                        texto: 'Reacción de TI',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChipEstado(
                        texto: 'Aviso Web',
                        activo: estado.avisoWeb,
                        color: ColoresApp.aviso,
                      ),
                      _ChipEstado(
                        texto: 'Aviso BD',
                        activo: estado.avisoBaseDatos,
                        color: ColoresApp.aviso,
                      ),
                      _ChipEstado(
                        texto: 'Alerta crítica',
                        activo: estado.alertaCritica,
                        color: ColoresApp.alerta,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerColapso extends StatelessWidget {
  final double minuto;
  final double? ventana;
  final bool continuar;

  const _BannerColapso({
    required this.minuto,
    required this.ventana,
    required this.continuar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.alerta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresApp.alerta.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.dangerous_outlined,
            color: ColoresApp.alerta,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servidor caído en el minuto '
                  '${formatearNumero(minuto)}. Ventana de Acción: '
                  '${formatearNumero(ventana ?? 0)} min',
                  style: const TextStyle(
                    color: ColoresApp.alerta,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  continuar
                      ? 'Modo teórico activo: los valores posteriores son datos teóricos.'
                      : 'La simulación está en pausa. Activa el modo teórico para continuar.',
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tanque extends StatelessWidget {
  final String nombre;
  final String variable;
  final double valor;
  final double capacidad;
  final double umbral;
  final Color color;
  final bool caido;
  final double? tiempoCaida;
  final bool mostrarNotaTeorica;

  const _Tanque({
    required this.nombre,
    required this.variable,
    required this.valor,
    required this.capacidad,
    required this.umbral,
    required this.color,
    required this.caido,
    required this.tiempoCaida,
    required this.mostrarNotaTeorica,
  });

  @override
  Widget build(BuildContext context) {
    final fraccionReal = capacidad <= 0 ? 0.0 : valor / capacidad;
    final fraccion = fraccionReal.clamp(0.0, 1.0);
    final porcentaje = fraccionReal <= 0 ? 0.0 : fraccionReal * 100;
    final desborde = capacidad > 0 && valor > capacidad;
    final estado = caido
        ? 'CAÍDO'
        : capacidad > 0 && valor >= capacidad
        ? 'Crítico'
        : capacidad > 0 && valor >= umbral * capacidad
        ? 'Aviso'
        : 'Normal';
    final colorEstado = caido || desborde
        ? ColoresApp.alerta
        : switch (estado) {
            'Crítico' => ColoresApp.alerta,
            'Aviso' => ColoresApp.aviso,
            _ => ColoresApp.ok,
          };
    final colorRelleno = caido || desborde ? ColoresApp.alerta : color;

    return SizedBox(
      height: 280,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ColoresApp.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColoresApp.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      color: ColoresApp.textoPrimario,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: colorEstado,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 92,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: ColoresApp.fondo,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ColoresApp.borde),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        FractionallySizedBox(
                          heightFactor: fraccion,
                          widthFactor: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colorRelleno.withValues(alpha: 0.95),
                                  colorRelleno.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          child: Text(
                            '${formatearNumero(porcentaje, decimales: 0)} %',
                            style: const TextStyle(
                              color: ColoresApp.textoPrimario,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variable,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatearNumero(valor),
                          style: TextStyle(
                            color: caido || desborde
                                ? ColoresApp.alerta
                                : ColoresApp.textoPrimario,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capacidad efectiva: ${formatearNumero(capacidad)}',
                          style: const TextStyle(
                            color: ColoresApp.textoSecundario,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          'Aviso al ${formatearNumero(umbral * 100, decimales: 0)} % '
                          '(${formatearNumero(umbral * capacidad, decimales: 0)})',
                          style: const TextStyle(
                            color: ColoresApp.textoSecundario,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        if (caido && tiempoCaida != null)
                          Text(
                            'Caída: ${formatearNumero(tiempoCaida!)} min',
                            style: const TextStyle(
                              color: ColoresApp.alerta,
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (mostrarNotaTeorica && caido)
                          const Text(
                            'datos teóricos: el servidor ya estaría caído',
                            style: TextStyle(
                              color: ColoresApp.alerta,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonVelocidad extends StatelessWidget {
  final double velocidad;
  final bool activa;
  final VoidCallback alElegir;

  const _BotonVelocidad({
    required this.velocidad,
    required this.activa,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: alElegir,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: activa
              ? ColoresApp.acento.withValues(alpha: 0.16)
              : ColoresApp.fondo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activa ? ColoresApp.acento : ColoresApp.borde,
          ),
        ),
        child: Text(
          '${formatearNumero(velocidad, decimales: 1)}x',
          style: TextStyle(
            color: activa ? ColoresApp.acento : ColoresApp.textoSecundario,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;

  const _ChipEstado({
    required this.texto,
    required this.activo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorFinal = activo ? color : ColoresApp.textoSecundario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorFinal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorFinal.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activo ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: colorFinal,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: colorFinal,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
            color: ColoresApp.textoSecundario,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
