import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/columnas_adaptativas.dart';
import '../../app/widgets/contenedor_modulo.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';

class PantallaMatematica extends StatelessWidget {
  const PantallaMatematica({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final sistema = estado.sistema;
    final coeficientes = sistema.coeficientes;
    final traza = coeficientes.a11 + coeficientes.a22;
    final determinante =
        coeficientes.a11 * coeficientes.a22 -
        coeficientes.a12 * coeficientes.a21;
    final discriminante = traza * traza - 4 * determinante;
    final raiz = math.sqrt(discriminante.abs());
    final real = traza / 2;
    final imaginaria =
        math.sqrt((-discriminante).clamp(0.0, double.infinity)) / 2;
    final limites = _calcularLimites(estado, traza, determinante);
    final verificacion = estado.verificacion;

    final textoLambda1 = discriminante >= 0
        ? formatearNumero((traza + raiz) / 2, decimales: 3)
        : '${formatearNumero(real, decimales: 3)} + ${formatearNumero(imaginaria, decimales: 3)}i';
    final textoLambda2 = discriminante >= 0
        ? formatearNumero((traza - raiz) / 2, decimales: 3)
        : '${formatearNumero(real, decimales: 3)} - ${formatearNumero(imaginaria, decimales: 3)}i';

    return ContenedorModulo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoPantalla(
            titulo: 'Ver la matemática',
            descripcion:
                'El sistema, la EDO de segundo orden, los valores propios y la solución analítica.',
          ),
          const SizedBox(height: 24),
          if (estado.error != null) ...[
            MensajeError(mensaje: estado.error!),
            const SizedBox(height: 16),
          ],
          PanelSeccion(
            titulo: 'Sistema de ecuaciones',
            subtitulo: 'Coeficientes cargados desde la configuración actual.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ecuacion(
                  texto:
                      "x' = v1(t)${_termino(coeficientes.a11, 'x')}${_termino(coeficientes.a12, 'y')}",
                ),
                const SizedBox(height: 8),
                _Ecuacion(
                  texto:
                      "y' = ${_terminoInicial(coeficientes.a21, 'x')}${_termino(coeficientes.a22, 'y')}",
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _Dato(
                      etiqueta: 'x(0)',
                      valor: formatearNumero(sistema.condicionesIniciales.x0),
                    ),
                    _Dato(
                      etiqueta: 'y(0)',
                      valor: formatearNumero(sistema.condicionesIniciales.y0),
                    ),
                    _Dato(
                      etiqueta: 'Unidad de tiempo',
                      valor: sistema.unidadTiempo,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Entrada de tráfico',
            subtitulo:
                'Escenario ${estado.escenarioActivo.nombre}. Parámetros actuales.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ecuacion(
                  texto: 'v1(t) = ${estado.escenarioActivo.expresionV1}',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    for (final parametro in estado.escenarioActivo.parametros)
                      _Dato(
                        etiqueta: parametro.nombre,
                        valor: formatearNumero(parametro.valor, decimales: 3),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'EDO de segundo orden',
            subtitulo:
                'Se obtiene eliminando una variable del sistema de dos tanques.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ecuacion(
                  texto:
                      "x''${_termino(-traza, "x'")}${_termino(determinante, 'x')} = v1'(t)${_termino(-coeficientes.a22, 'v1(t)')}",
                ),
                const SizedBox(height: 8),
                _Ecuacion(
                  texto:
                      "y''${_termino(-traza, "y'")}${_termino(determinante, 'y')} = ${_terminoInicial(coeficientes.a21, 'v1(t)')}",
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _Dato(
                      etiqueta: 'Traza',
                      valor: formatearNumero(traza, decimales: 3),
                    ),
                    _Dato(
                      etiqueta: 'Determinante',
                      valor: formatearNumero(determinante, decimales: 3),
                    ),
                    _Dato(
                      etiqueta: 'Discriminante',
                      valor: formatearNumero(discriminante, decimales: 3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, restricciones) {
              final valores = PanelSeccion(
                titulo: 'Valores propios',
                subtitulo: 'Raíces de la ecuación característica del sistema.',
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _Dato(etiqueta: 'λ1', valor: textoLambda1),
                    _Dato(etiqueta: 'λ2', valor: textoLambda2),
                    _Dato(
                      etiqueta: 'Comportamiento',
                      valor: (traza > 0 || determinante < 0)
                          ? 'Inestable'
                          : 'Estable',
                    ),
                  ],
                ),
              );
              final derivadas = PanelSeccion(
                titulo: 'Derivadas iniciales',
                subtitulo:
                    'Evaluadas con v1(0), x(0) e y(0) de la configuración.',
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _Dato(
                      etiqueta: "x'(0)",
                      valor: formatearNumero(
                        estado.derivadaXInicial,
                        decimales: 3,
                      ),
                    ),
                    _Dato(
                      etiqueta: "y'(0)",
                      valor: formatearNumero(
                        estado.derivadaYInicial,
                        decimales: 3,
                      ),
                    ),
                    _Dato(
                      etiqueta: 'v1(0)',
                      valor: formatearNumero(
                        estado.entradaInicial,
                        decimales: 3,
                      ),
                    ),
                  ],
                ),
              );
              return ColumnasAdaptativas(
                columnas: [
                  [valores],
                  [derivadas],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Límites cuando t → ∞',
            subtitulo:
                'Calculados con los valores propios y el tipo de escenario activo.',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Dato(etiqueta: 'lim x(t)', valor: limites.x),
                _Dato(etiqueta: 'lim y(t)', valor: limites.y),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Solución analítica',
            subtitulo:
                'Expresiones leídas desde assets/config/soluciones.json.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ecuacion(
                  texto: 'x(t) = ${estado.solucionAnalitica.expresionX}',
                ),
                const SizedBox(height: 8),
                _Ecuacion(
                  texto: 'y(t) = ${estado.solucionAnalitica.expresionY}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Verificación cruzada',
            subtitulo: 'Comparación entre la solución numérica y la analítica.',
            child: verificacion == null
                ? const Text(
                    'Sin datos de verificación para el escenario activo.',
                    style: TextStyle(
                      color: AppColores.textoSecundario,
                      fontSize: 12,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _Dato(
                            etiqueta: 'Error máximo',
                            valor: formatearNumero(
                              verificacion.errorMaximo,
                              decimales: 5,
                            ),
                          ),
                          _Dato(
                            etiqueta: 'Umbral',
                            valor: formatearNumero(
                              verificacion.umbral,
                              decimales: 5,
                            ),
                          ),
                          _Dato(
                            etiqueta: 'Error en x',
                            valor: formatearNumero(
                              verificacion.errorMaximoX,
                              decimales: 5,
                            ),
                          ),
                          _Dato(
                            etiqueta: 'Error en y',
                            valor: formatearNumero(
                              verificacion.errorMaximoY,
                              decimales: 5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              (verificacion.hayDiscrepancia
                                      ? AppColores.importante
                                      : AppColores.exito)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                (verificacion.hayDiscrepancia
                                        ? AppColores.importante
                                        : AppColores.exito)
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              verificacion.hayDiscrepancia
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              color: verificacion.hayDiscrepancia
                                  ? AppColores.importante
                                  : AppColores.exito,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                verificacion.hayDiscrepancia
                                    ? 'Discrepancia detectada: el error máximo supera el umbral configurado.'
                                    : 'Sin discrepancia: la solución numérica coincide con la analítica dentro del umbral.',
                                style: TextStyle(
                                  color: verificacion.hayDiscrepancia
                                      ? AppColores.importante
                                      : AppColores.exito,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
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
    );
  }

  String _termino(double coeficiente, String variable) {
    final signo = coeficiente < 0 ? '-' : '+';
    return ' $signo ${formatearNumero(coeficiente.abs(), decimales: 3)}·$variable';
  }

  String _terminoInicial(double coeficiente, String variable) {
    final signo = coeficiente < 0 ? '-' : '';
    return '$signo${formatearNumero(coeficiente.abs(), decimales: 3)}·$variable';
  }

  ({String x, String y}) _calcularLimites(
    EstadoAplicacion estado,
    double traza,
    double determinante,
  ) {
    final coeficientes = estado.sistema.coeficientes;
    final parametros = estado.escenarioActivo.mapaParametros;

    if (traza > 0 || determinante < 0) {
      return (x: 'No acotado', y: 'No acotado');
    }

    final escenario = estado.escenarioActivo.id;
    if (escenario == 'ciclico') {
      return (x: 'Acotado (oscila)', y: 'Acotado (oscila)');
    }
    if (escenario == 'lineal') {
      final pendiente = parametros['m'] ?? 0;
      if (pendiente > 0) return (x: '+∞', y: '+∞');
      if (pendiente < 0) return (x: '-∞', y: '-∞');
    }
    if (escenario == 'exponencial') {
      final tasa = parametros['r'] ?? 0;
      if (tasa > 0) return (x: '+∞', y: '+∞');
    }

    var entradaLimite = estado.entradaInicial;
    if (escenario == 'exponencial') {
      final tasa = parametros['r'] ?? 0;
      final base = parametros['b'] ?? 0;
      final inicial = parametros['P0'] ?? 0;
      entradaLimite = tasa == 0 ? base + inicial : base;
    }

    if (determinante.abs() < 1e-12) {
      return (x: 'No determinado', y: 'No determinado');
    }

    final x = -entradaLimite * coeficientes.a22 / determinante;
    final y = entradaLimite * coeficientes.a21 / determinante;
    return (
      x: formatearNumero(x, decimales: 3),
      y: formatearNumero(y, decimales: 3),
    );
  }
}

class _Ecuacion extends StatelessWidget {
  final String texto;

  const _Ecuacion({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColores.panelSecundario,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColores.borde),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColores.primarioOscuro,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
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
