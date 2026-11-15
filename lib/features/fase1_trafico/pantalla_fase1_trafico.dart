import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/campo_numerico.dart';
import '../../app/widgets/contenedor_modulo.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/grafico_curva.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';
import '../../core/models/escenario_trafico.dart';
import '../../core/models/punto_entrada.dart';

typedef _DatosFase1 = ({
  EscenarioTrafico escenario,
  List<PuntoEntrada> curva,
  String? error,
  bool entradaNegativa,
  double horizonte,
  double c1,
  String unidad,
});

class PantallaFase1Trafico extends StatelessWidget {
  const PantallaFase1Trafico({super.key});

  @override
  Widget build(BuildContext context) {
    final datos = context.select<EstadoAplicacion, _DatosFase1>(
      (estado) => (
        escenario: estado.escenarioActivo,
        curva: estado.curvaEntradaActiva,
        error: estado.error,
        entradaNegativa: estado.entradaNegativaEnHorizonte,
        horizonte: estado.horizonteActivo,
        c1: estado.sistema.tanques.c1,
        unidad: estado.sistema.unidadTiempo,
      ),
    );
    final escenario = datos.escenario;
    final curva = datos.curva;
    final valorFinal = curva.isEmpty ? null : curva.last.valor;

    final formulario = PanelSeccion(
      titulo: 'Parámetros del escenario activo',
      subtitulo:
          'Escenario ${escenario.nombre}. Cada cambio recalcula la simulación.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColores.panelSecundario,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColores.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entrada de tráfico',
                  style: TextStyle(
                    color: AppColores.textoSecundario,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'v1(t) = ${escenario.expresionV1}',
                  style: const TextStyle(
                    color: AppColores.primarioOscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  escenario.edo,
                  style: const TextStyle(
                    color: AppColores.textoSecundario,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final parametro in escenario.parametros)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CampoNumerico(
                key: ValueKey('${escenario.id}-${parametro.clave}'),
                etiqueta: parametro.nombre,
                valorInicial: parametro.valor,
                ayuda: _ayudaParametro(parametro.clave),
                alCambiar: (valor) => context
                    .read<EstadoAplicacion>()
                    .actualizarParametroEscenario(parametro.clave, valor),
              ),
            ),
          CampoNumerico(
            key: ValueKey('${escenario.id}-tiempo_max_min'),
            etiqueta: 'tiempo_max_min',
            valorInicial: escenario.tiempoMaxMin,
            ayuda: 'Horizonte de simulación de este escenario',
            sufijo: datos.unidad,
            alCambiar: (valor) => context
                .read<EstadoAplicacion>()
                .actualizarTiempoMaxEscenario(valor),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrada efectiva: c1 · v1(t), con c1 = '
            '${formatearNumero(datos.c1)}.',
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unidad de tiempo: ${datos.unidad}.',
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    final grafico = PanelSeccion(
      titulo: 'Curva de entrada v1(t)',
      subtitulo:
          'Horizonte de ${formatearNumero(datos.horizonte, decimales: 0)} min.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GraficoCurva(puntos: curva, altura: 260, mostrarEtiquetas: true),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _DatoResumen(etiqueta: 'Escenario', valor: escenario.nombre),
              _DatoResumen(
                etiqueta: 'v1 al final',
                valor: valorFinal == null
                    ? '—'
                    : formatearNumero(valorFinal, decimales: 1),
              ),
              _DatoResumen(
                etiqueta: 'Puntos de curva',
                valor: '${curva.length}',
              ),
            ],
          ),
        ],
      ),
    );

    return ContenedorModulo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoPantalla(
            titulo: 'Fase 1 · Tráfico',
            descripcion:
                'Ajusta el escenario y observa cómo cambia la entrada v1(t).',
          ),
          const SizedBox(height: 24),
          if (datos.error != null) ...[
            MensajeError(mensaje: datos.error!),
            const SizedBox(height: 16),
          ],
          if (datos.entradaNegativa) ...[
            _AvisoEntradaNegativa(c1: datos.c1, tiempoMaxMin: datos.horizonte),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, restricciones) {
              if (restricciones.maxWidth >= 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: formulario),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: grafico),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [formulario, const SizedBox(height: 20), grafico],
              );
            },
          ),
        ],
      ),
    );
  }

  String? _ayudaParametro(String clave) {
    return switch (clave) {
      'P0' => 'Nivel base de tráfico',
      'm' => 'Pendiente de crecimiento por minuto',
      'r' => 'Tasa de crecimiento exponencial',
      'b' => 'Carga base adicional',
      'dP0' => 'Velocidad inicial del ciclo',
      'periodo_min' => 'Duración del ciclo en minutos (omega = 2·PI/periodo)',
      _ => null,
    };
  }
}

class _AvisoEntradaNegativa extends StatelessWidget {
  final double c1;
  final double tiempoMaxMin;

  const _AvisoEntradaNegativa({required this.c1, required this.tiempoMaxMin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.secundarioTexto.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColores.secundarioTexto.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColores.secundarioTexto,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tráfico negativo: c1 · v1(t) toma valores por debajo de cero '
              'en el horizonte de ${formatearNumero(tiempoMaxMin, decimales: 0)} min '
              '(c1 = ${formatearNumero(c1)}). El caso cíclico puede restar carga '
              'a los tanques en parte del ciclo.',
              style: const TextStyle(
                color: AppColores.secundarioTexto,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoResumen({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            color: AppColores.textoPrincipal,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
