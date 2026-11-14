import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/semaforo.dart';
import '../../app/tema.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';
import '../../core/models/escenario_trafico.dart';
import '../../core/models/resultado_colapso.dart';
import '../../core/models/resultado_ventana_accion.dart';

class PantallaResultados extends StatelessWidget {
  const PantallaResultados({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoPantalla(
              titulo: 'Resultados',
              descripcion:
                  'Comparador de los cuatro escenarios con la configuración actual.',
            ),
            const SizedBox(height: 24),
            if (estado.error != null) ...[
              MensajeError(mensaje: estado.error!),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, restricciones) {
                if (restricciones.maxWidth >= 820) {
                  return PanelSeccion(
                    titulo: 'Comparador de escenarios',
                    subtitulo:
                        'Colapso en minutos, Ventana de Acción y semáforo. '
                        'Toca una fila para activar ese escenario.',
                    child: _TablaResultados(estado: estado),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final escenario in estado.escenarios) ...[
                      _TarjetaResultado(estado: estado, escenario: escenario),
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            PanelSeccion(
              titulo: 'Lectura del semáforo',
              subtitulo:
                  'Umbrales calculados desde la configuración del sistema.',
              child: Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _LeyendaSemaforo(
                    color: ColoresApp.ok,
                    texto:
                        'Estable: ventana ≥ ${formatearNumero(estado.sistema.semaforo.ventanaVerde)} min',
                  ),
                  _LeyendaSemaforo(
                    color: ColoresApp.aviso,
                    texto:
                        'Precaución: ventana entre ${formatearNumero(estado.sistema.semaforo.ventanaAmarilla)} y '
                        '${formatearNumero(estado.sistema.semaforo.ventanaVerde)} min',
                  ),
                  _LeyendaSemaforo(
                    color: ColoresApp.alerta,
                    texto:
                        'Crítico: ventana < ${formatearNumero(estado.sistema.semaforo.ventanaAmarilla)} min',
                  ),
                  const _LeyendaSemaforo(
                    color: ColoresApp.textoSecundario,
                    texto: 'Sin colapso dentro del horizonte simulado',
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

class _TablaResultados extends StatelessWidget {
  final EstadoAplicacion estado;

  const _TablaResultados({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(flex: 20, child: _EncabezadoTabla('Escenario')),
              Expanded(flex: 16, child: _EncabezadoTabla('Colapso Web')),
              Expanded(flex: 16, child: _EncabezadoTabla('Colapso BD')),
              Expanded(flex: 16, child: _EncabezadoTabla('Ventana')),
              Expanded(flex: 16, child: _EncabezadoTabla('Semáforo')),
            ],
          ),
        ),
        for (final escenario in estado.escenarios)
          _FilaResultado(estado: estado, escenario: escenario),
      ],
    );
  }
}

class _FilaResultado extends StatelessWidget {
  final EstadoAplicacion estado;
  final EscenarioTrafico escenario;

  const _FilaResultado({required this.estado, required this.escenario});

  @override
  Widget build(BuildContext context) {
    final activo = escenario.id == estado.idEscenarioActivo;
    final nivel = estado.nivelSemaforoEscenario(escenario.id);
    final ventana = estado.ventanaEscenario(escenario.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            context.read<EstadoAplicacion>().seleccionarEscenario(escenario.id),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: activo
                ? ColoresApp.acento.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 20,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        escenario.nombre,
                        style: const TextStyle(
                          color: ColoresApp.textoPrimario,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (activo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ColoresApp.acento.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(
                            color: ColoresApp.acento,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 16,
                child: _TextoColapso(
                  colapso: estado.colapsoWebEscenario(escenario.id),
                ),
              ),
              Expanded(
                flex: 16,
                child: _TextoColapso(
                  colapso: estado.colapsoBaseDatosEscenario(escenario.id),
                ),
              ),
              Expanded(
                flex: 16,
                child: _TextoVentana(ventana: ventana, nivel: nivel),
              ),
              Expanded(flex: 16, child: _Semaforo(nivel: nivel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  final String texto;

  const _EncabezadoTabla(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        color: ColoresApp.textoSecundario,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _TextoColapso extends StatelessWidget {
  final ResultadoColapso? colapso;

  const _TextoColapso({required this.colapso});

  @override
  Widget build(BuildContext context) {
    final tiempo = colapso?.tiempo;
    return Text(
      tiempo == null ? 'No colapsa' : '${formatearNumero(tiempo)} min',
      style: TextStyle(
        color: tiempo == null
            ? ColoresApp.textoSecundario
            : ColoresApp.textoPrimario,
        fontSize: 12,
        fontWeight: tiempo == null ? FontWeight.w400 : FontWeight.w600,
      ),
    );
  }
}

class _TextoVentana extends StatelessWidget {
  final ResultadoVentanaAccion? ventana;
  final NivelSemaforo nivel;

  const _TextoVentana({required this.ventana, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final valor = ventana?.ventanaAccion;
    return Text(
      valor == null ? '—' : '${formatearNumero(valor)} min',
      style: TextStyle(
        color: _colorNivel(nivel),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TarjetaResultado extends StatelessWidget {
  final EstadoAplicacion estado;
  final EscenarioTrafico escenario;

  const _TarjetaResultado({required this.estado, required this.escenario});

  @override
  Widget build(BuildContext context) {
    final activo = escenario.id == estado.idEscenarioActivo;
    final nivel = estado.nivelSemaforoEscenario(escenario.id);
    final ventana = estado.ventanaEscenario(escenario.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activo
            ? ColoresApp.acento.withValues(alpha: 0.08)
            : ColoresApp.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: activo ? ColoresApp.acento : ColoresApp.borde,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  escenario.nombre,
                  style: const TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _Semaforo(nivel: nivel),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(
                etiqueta: 'Colapso Web',
                valor: _textoColapso(estado.colapsoWebEscenario(escenario.id)),
              ),
              _Dato(
                etiqueta: 'Colapso BD',
                valor: _textoColapso(
                  estado.colapsoBaseDatosEscenario(escenario.id),
                ),
              ),
              _Dato(
                etiqueta: 'Ventana',
                valor: ventana?.ventanaAccion == null
                    ? '—'
                    : '${formatearNumero(ventana!.ventanaAccion!)} min',
                color: _colorNivel(nivel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _textoColapso(ResultadoColapso? colapso) {
    final tiempo = colapso?.tiempo;
    return tiempo == null ? 'No colapsa' : '${formatearNumero(tiempo)} min';
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;

  const _Dato({required this.etiqueta, required this.valor, this.color});

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
          style: TextStyle(
            color: color ?? ColoresApp.textoPrimario,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Semaforo extends StatelessWidget {
  final NivelSemaforo nivel;

  const _Semaforo({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final color = _colorNivel(nivel);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          etiquetaNivelSemaforo(nivel),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LeyendaSemaforo extends StatelessWidget {
  final Color color;
  final String texto;

  const _LeyendaSemaforo({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

Color _colorNivel(NivelSemaforo nivel) {
  return switch (nivel) {
    NivelSemaforo.critico => ColoresApp.alerta,
    NivelSemaforo.precaucion => ColoresApp.aviso,
    NivelSemaforo.estable => ColoresApp.ok,
    NivelSemaforo.sinColapso => ColoresApp.textoSecundario,
  };
}
