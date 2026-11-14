import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/campo_numerico.dart';
import '../../app/widgets/diagrama_tubos.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';

class PantallaFase2Servidores extends StatelessWidget {
  const PantallaFase2Servidores({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final sistema = estado.sistema;
    final tanques = sistema.tanques;
    final coeficientes = sistema.coeficientes;
    final esDerivado = tanques.modoCoeficientes == 'derivado';
    final ventana = estado.ventanaAccion?.ventanaAccion;
    final puntos = estado.resultado?.puntos.length;

    final paneles = <Widget>[
      PanelSeccion(
        titulo: 'Modo de coeficientes',
        subtitulo:
            'Derivado: los coeficientes se calculan desde caudales y volúmenes. '
            'Directo: se editan a mano.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'derivado', label: Text('Derivado')),
                ButtonSegment(value: 'directo', label: Text('Directo')),
              ],
              selected: {tanques.modoCoeficientes},
              onSelectionChanged: (seleccion) => context
                  .read<EstadoAplicacion>()
                  .cambiarModoCoeficientes(seleccion.first),
            ),
            const SizedBox(height: 12),
            Text(
              esDerivado
                  ? 'Los coeficientes se obtienen de los tubos y los volúmenes.'
                  : 'Los caudales quedan como referencia; mandan los coeficientes.',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      PanelSeccion(
        titulo: 'Tubos fijos y caudales',
        subtitulo:
            'Los tubos no cambian; sus caudales sí. Se usan en modo derivado.',
        child: Column(
          children: [
            _campo(
              context,
              etiqueta: 'A → B · consultas',
              valor: tanques.caudales.aAB,
              habilitado: esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCaudal('A_a_B', valor),
            ),
            _campo(
              context,
              etiqueta: 'A · salida (rate limiting)',
              valor: tanques.caudales.aSalida,
              habilitado: esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCaudal('A_salida', valor),
            ),
            _campo(
              context,
              etiqueta: 'B → A · caché y retorno',
              valor: tanques.caudales.bAA,
              habilitado: esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCaudal('B_a_A', valor),
            ),
            _campo(
              context,
              etiqueta: 'B · salida',
              valor: tanques.caudales.bSalida,
              habilitado: esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCaudal('B_salida', valor),
            ),
            _campo(
              context,
              etiqueta: 'c1 · concentración de la entrada',
              valor: tanques.c1,
              habilitado: true,
              ultimo: true,
              alCambiar: (valor) =>
                  context.read<EstadoAplicacion>().actualizarC1(valor),
            ),
          ],
        ),
      ),
      PanelSeccion(
        titulo: 'Volúmenes de los tanques',
        subtitulo: 'Capacidad física usada para derivar los coeficientes.',
        child: Column(
          children: [
            _campo(
              context,
              etiqueta: 'volumen_A · Capa Web',
              valor: tanques.volumenA,
              habilitado: esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarVolumen('volumen_A', valor),
            ),
            _campo(
              context,
              etiqueta: 'volumen_B · Base de Datos',
              valor: tanques.volumenB,
              habilitado: esDerivado,
              ultimo: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarVolumen('volumen_B', valor),
            ),
          ],
        ),
      ),
      PanelSeccion(
        titulo: 'Coeficientes de acoplamiento',
        subtitulo: esDerivado
            ? 'Calculados desde los tubos y los volúmenes (solo lectura).'
            : 'Editables en modo directo.',
        child: Column(
          children: [
            _campo(
              context,
              etiqueta: 'a11 · Capa Web sobre sí misma',
              valor: coeficientes.a11,
              habilitado: !esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCoeficienteDirecto('a11', valor),
            ),
            _campo(
              context,
              etiqueta: 'a12 · Base de Datos hacia Capa Web',
              valor: coeficientes.a12,
              habilitado: !esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCoeficienteDirecto('a12', valor),
            ),
            _campo(
              context,
              etiqueta: 'a21 · Capa Web hacia Base de Datos',
              valor: coeficientes.a21,
              habilitado: !esDerivado,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCoeficienteDirecto('a21', valor),
            ),
            _campo(
              context,
              etiqueta: 'a22 · Base de Datos sobre sí misma',
              valor: coeficientes.a22,
              habilitado: !esDerivado,
              ultimo: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCoeficienteDirecto('a22', valor),
            ),
          ],
        ),
      ),
      PanelSeccion(
        titulo: 'Límites críticos',
        subtitulo:
            'Límite a partir del cual se declara el colapso. Es independiente del volumen.',
        child: Column(
          children: [
            _campo(
              context,
              etiqueta: 'limite_A · Capa Web',
              valor: tanques.limiteA,
              habilitado: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarLimite('limite_A', valor),
            ),
            _campo(
              context,
              etiqueta: 'limite_B · Base de Datos',
              valor: tanques.limiteB,
              habilitado: true,
              ultimo: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarLimite('limite_B', valor),
            ),
          ],
        ),
      ),
      PanelSeccion(
        titulo: 'Condiciones iniciales',
        subtitulo: 'Nivel de ocupación al iniciar la simulación.',
        child: Column(
          children: [
            _campo(
              context,
              etiqueta: 'x(0) · Capa Web',
              valor: sistema.condicionesIniciales.x0,
              habilitado: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCondicionInicial('x0', valor),
            ),
            _campo(
              context,
              etiqueta: 'y(0) · Base de Datos',
              valor: sistema.condicionesIniciales.y0,
              habilitado: true,
              ultimo: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarCondicionInicial('y0', valor),
            ),
          ],
        ),
      ),
      PanelSeccion(
        titulo: 'Reacción de TI',
        subtitulo: 'Tiempo que tarda el equipo en actuar ante la alerta.',
        child: Column(
          children: [
            _campo(
              context,
              etiqueta: 'tiempo_reaccion_min',
              valor: sistema.tiempoReaccion,
              sufijo: sistema.unidadTiempo,
              habilitado: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarTiempoReaccion(valor),
            ),
            _campo(
              context,
              etiqueta: 'umbral_alerta · fracción 0-1',
              valor: sistema.umbralAlerta,
              habilitado: true,
              alCambiar: (valor) => context
                  .read<EstadoAplicacion>()
                  .actualizarUmbralAlerta(valor),
              ultimo: true,
            ),
            const SizedBox(height: 4),
            Text(
              'Pasos de simulación: ${formatearNumero(sistema.simulacion.paso, decimales: 2)} '
              '· Horizonte activo: ${formatearNumero(estado.horizonteActivo, decimales: 0)} min.',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoPantalla(
              titulo: 'Fase 2 · Servidores',
              descripcion:
                  'Ajusta tubos, volúmenes, límites y coeficientes. La vista previa se recalcula al editar.',
            ),
            const SizedBox(height: 24),
            if (estado.error != null) ...[
              MensajeError(mensaje: estado.error!),
              const SizedBox(height: 16),
            ],
            if (estado.entradaNegativaEnHorizonte) ...[
              _AvisoEntradaNegativa(
                c1: tanques.c1,
                tiempoMaxMin: estado.horizonteActivo,
              ),
              const SizedBox(height: 16),
            ],
            const _PanelDiagramaTubos(),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, restricciones) {
                if (restricciones.maxWidth >= 860) {
                  final ancho = (restricciones.maxWidth - 20) / 2;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      for (final panel in paneles)
                        SizedBox(width: ancho, child: panel),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final panel in paneles) ...[
                      panel,
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            PanelSeccion(
              titulo: 'Vista previa del cálculo',
              subtitulo:
                  'Se recalcula automáticamente con los valores actuales.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _IndicadorResultado(
                        titulo: 'COLAPSO CAPA WEB',
                        valor: estado.colapsoCapaWeb?.tiempo == null
                            ? 'No colapsa'
                            : '${formatearNumero(estado.colapsoCapaWeb!.tiempo!)} min',
                        color: ColoresApp.acento,
                      ),
                      _IndicadorResultado(
                        titulo: 'COLAPSO BASE DE DATOS',
                        valor: estado.colapsoBaseDatos?.tiempo == null
                            ? 'No colapsa'
                            : '${formatearNumero(estado.colapsoBaseDatos!.tiempo!)} min',
                        color: ColoresApp.acento,
                      ),
                      _IndicadorResultado(
                        titulo: 'VENTANA DE ACCIÓN',
                        valor: ventana == null
                            ? 'Sin colapso'
                            : '${formatearNumero(ventana)} min',
                        color: ventana != null && ventana < 0
                            ? ColoresApp.alerta
                            : ColoresApp.ok,
                      ),
                      _IndicadorResultado(
                        titulo: 'Puntos calculados',
                        valor: puntos == null ? '—' : '$puntos',
                        color: ColoresApp.textoSecundario,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _DatoDerivado(
                        etiqueta: "x'(0)",
                        valor: estado.derivadaXInicial,
                      ),
                      _DatoDerivado(
                        etiqueta: "y'(0)",
                        valor: estado.derivadaYInicial,
                      ),
                      _DatoDerivado(
                        etiqueta: 'c1 · v1(0)',
                        valor: tanques.c1 * estado.entradaInicial,
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

  Widget _campo(
    BuildContext context, {
    required String etiqueta,
    required double valor,
    required ValueChanged<double> alCambiar,
    bool habilitado = true,
    String? sufijo,
    bool ultimo = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
      child: CampoNumerico(
        etiqueta: etiqueta,
        valorInicial: valor,
        sufijo: sufijo,
        habilitado: habilitado,
        alCambiar: alCambiar,
      ),
    );
  }
}

class _PanelDiagramaTubos extends StatefulWidget {
  const _PanelDiagramaTubos();

  @override
  State<_PanelDiagramaTubos> createState() => _PanelDiagramaTubosState();
}

class _PanelDiagramaTubosState extends State<_PanelDiagramaTubos> {
  double _tiempo = 0;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final sistema = estado.sistema;
    final punto = estado.puntoEn(_tiempo);
    final x = punto?.x ?? sistema.condicionesIniciales.x0;
    final y = punto?.y ?? sistema.condicionesIniciales.y0;
    final entrada = estado.entradaEn(_tiempo) * sistema.tanques.c1;

    return PanelSeccion(
      titulo: 'Diagrama de tubos y flujos',
      subtitulo:
          'Los tubos son fijos; sus caudales y volúmenes se editan aquí o en el '
          'formulario y actualizan el mismo estado. Elige el instante t para ver '
          'la tabla Entra / Sale.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: CampoNumerico(
              etiqueta: 't · instante consultado',
              valorInicial: _tiempo,
              sufijo: sistema.unidadTiempo,
              alCambiar: (valor) =>
                  setState(() => _tiempo = valor < 0 ? 0 : valor),
            ),
          ),
          const SizedBox(height: 18),
          DiagramaTubos(
            datos: DatosDiagramaTubos(
              sistema: sistema,
              tiempo: _tiempo,
              x: x,
              y: y,
              entradaExterna: entrada,
              capacidadA: estado.capacidadWebEfectiva,
              capacidadB: estado.capacidadBaseDatosEfectiva,
              umbralAlerta: sistema.umbralAlerta,
            ),
            editable: true,
            alCambiarCaudal: (clave, valor) =>
                context.read<EstadoAplicacion>().actualizarCaudal(clave, valor),
            alCambiarVolumen: (clave, valor) => context
                .read<EstadoAplicacion>()
                .actualizarVolumen(clave, valor),
          ),
        ],
      ),
    );
  }
}

class _DatoDerivado extends StatelessWidget {
  final String etiqueta;
  final double valor;

  const _DatoDerivado({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          formatearNumero(valor, decimales: 3),
          style: const TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
        color: ColoresApp.aviso.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresApp.aviso.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: ColoresApp.aviso,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tráfico negativo: c1 · v1(t) toma valores por debajo de cero '
              'en el horizonte de ${formatearNumero(tiempoMaxMin, decimales: 0)} min '
              '(c1 = ${formatearNumero(c1)}).',
              style: const TextStyle(
                color: ColoresApp.aviso,
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

class _IndicadorResultado extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _IndicadorResultado({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresApp.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresApp.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
