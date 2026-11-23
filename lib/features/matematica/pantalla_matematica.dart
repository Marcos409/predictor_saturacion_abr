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
import '../../core/engine/verificador_cruzado.dart';
import '../../core/models/resultado_colapso.dart';
import '../../core/models/resultado_verificacion.dart';
import '../../core/models/solucion_general.dart';

class PantallaMatematica extends StatelessWidget {
  const PantallaMatematica({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final sistema = estado.sistema;
    final coeficientes = sistema.coeficientes;
    final general = estado.solucionGeneralActiva;
    final pasos = general?.pasos;
    final verificacion = estado.verificacion;
    final usaSolucionJson = estado.usaSolucionJsonParaVerificacion;
    final limites = _calcularLimites(estado);

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
            titulo: 'Fase 1 · Entrada de tráfico',
            subtitulo:
                'Escenario ${estado.escenarioActivo.nombre}. Parámetros actuales.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ecuacion(texto: 'EDO: ${_edoFase1(estado)}'),
                const SizedBox(height: 8),
                _Ecuacion(
                  texto: general == null
                      ? 'V1(t) = ${estado.escenarioActivo.expresionV1}'
                      : 'V1(t) = ${general.expresionV1}',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    for (final parametro in estado.escenarioActivo.parametros)
                      _Dato(
                        etiqueta: parametro.nombre,
                        valor: formatearNumero(parametro.valor, decimales: 6),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Fase 2 · EDO de segundo orden',
            subtitulo:
                'Se obtiene eliminando una variable del sistema de dos tanques.',
            child: pasos == null
                ? Text(
                    estado.motivoSolucionNoDisponible ??
                        'No hay EDO analítica para esta configuración.',
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      fontSize: 12,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Ecuacion(texto: pasos.edo),
                      const SizedBox(height: 8),
                      _Ecuacion(
                        texto:
                            'Ecuación característica: r² + (${_n(pasos.a)})·r '
                            '+ (${_n(pasos.b)}) = 0',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _Dato(etiqueta: 'a', valor: _n(pasos.a)),
                          _Dato(etiqueta: 'b', valor: _n(pasos.b)),
                          _Dato(etiqueta: 'c', valor: _n(pasos.c)),
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
                    _Dato(
                      etiqueta: 'r1',
                      valor: pasos?.r1 == null ? '—' : _n(pasos!.r1!),
                    ),
                    _Dato(
                      etiqueta: 'r2',
                      valor: pasos?.r2 == null ? '—' : _n(pasos!.r2!),
                    ),
                    _Dato(
                      etiqueta: 'Comportamiento',
                      valor: _comportamiento(pasos),
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
                        decimales: 6,
                      ),
                    ),
                    _Dato(
                      etiqueta: "y'(0)",
                      valor: formatearNumero(
                        estado.derivadaYInicial,
                        decimales: 6,
                      ),
                    ),
                    _Dato(
                      etiqueta: 'v1(0)',
                      valor: formatearNumero(
                        estado.entradaInicial,
                        decimales: 6,
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
            titulo: 'Fase 2 · Desarrollo de la solución',
            subtitulo: usaSolucionJson
                ? 'Los pasos se calculan con el solver general; la verificación usa soluciones.json.'
                : 'Todos los coeficientes se calculan con el solver analítico general.',
            child: general == null || pasos == null
                ? Text(
                    estado.motivoSolucionNoDisponible ??
                        'No hay solución analítica para esta configuración.',
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      fontSize: 12,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Ecuacion(texto: _homogenea(pasos)),
                      const SizedBox(height: 8),
                      _Ecuacion(
                        texto: _particular(estado.escenarioActivo.id, pasos),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          for (final entrada
                              in pasos.coeficientesParticulares.entries)
                            _Dato(
                              etiqueta: entrada.key,
                              valor: _n(entrada.value),
                            ),
                          _Dato(
                            etiqueta: 'C1',
                            valor: pasos.c1Homogenea == null
                                ? '—'
                                : _n(pasos.c1Homogenea!),
                          ),
                          _Dato(
                            etiqueta: 'C2',
                            valor: pasos.c2Homogenea == null
                                ? '—'
                                : _n(pasos.c2Homogenea!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Ecuacion(texto: 'y(t) = ${general.expresionY}'),
                      const SizedBox(height: 8),
                      _Ecuacion(texto: 'x(t) = ${general.expresionX}'),
                      const SizedBox(height: 8),
                      _Ecuacion(
                        texto: "y'(t) = ${formatearExpresion(
                          _derivadas(general.terminosY),
                          general.variable,
                        )}",
                      ),
                      const SizedBox(height: 8),
                      _Ecuacion(
                        texto: "x'(t) = ${formatearExpresion(
                          _derivadas(general.terminosX),
                          general.variable,
                        )}",
                      ),
                    ],
                  ),
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
            titulo: 'Colapso y Ventana de Acción',
            subtitulo:
                'Horizonte de ${_n(estado.horizonteActivo, decimales: 0)} min '
                'y tiempo de reacción de ${_n(estado.sistema.tiempoReaccion)} min.',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Dato(
                  etiqueta: 'Colapso Capa Web',
                  valor: _tiempo(estado.colapsoCapaWeb),
                ),
                _Dato(
                  etiqueta: 'Colapso Base de Datos',
                  valor: _tiempo(estado.colapsoBaseDatos),
                ),
                _Dato(
                  etiqueta: 'Ventana de Acción',
                  valor: estado.ventanaAccion == null ||
                          estado.ventanaAccion!.ventanaAccion == null
                      ? 'Sin colapso'
                      : '${_n(estado.ventanaAccion!.ventanaAccion!)} min',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PanelSeccion(
            titulo: 'Verificación cruzada',
            subtitulo:
                'Comparación entre RK4 y la solución analítica del escenario activo con los parámetros actuales. '
                'Umbral relativo: ${_notacion(verificacion?.umbral ?? VerificadorCruzado.umbralRelativoPorDefecto)}.',
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
                      if (verificacion.disponible) ...[
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _Dato(
                              etiqueta: 'Error máximo (absoluto)',
                              valor: _notacion(verificacion.errorMaximo),
                            ),
                            _Dato(
                              etiqueta: 'Error relativo',
                              valor: _notacion(verificacion.errorRelativo),
                            ),
                            _Dato(
                              etiqueta: 'Umbral relativo',
                              valor: _notacion(verificacion.umbral),
                            ),
                            _Dato(
                              etiqueta: 'Escala (máximo |x|, |y|)',
                              valor: _notacion(verificacion.valorMaximo),
                            ),
                            _Dato(
                              etiqueta: 'Error en x',
                              valor: _notacion(verificacion.errorMaximoX),
                            ),
                            _Dato(
                              etiqueta: 'Error en y',
                              valor: _notacion(verificacion.errorMaximoY),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      _avisoVerificacion(verificacion),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _edoFase1(EstadoAplicacion estado) {
    final parametros = estado.escenarioActivo.mapaParametros;
    String valor(String clave) => _n(parametros[clave] ?? 0);
    switch (estado.escenarioActivo.id) {
      case 'lineal':
        return 'dP/dt = ${valor('m')}  ·  P(0) = ${valor('P0')}';
      case 'constante':
        return 'dP/dt = 0  ·  P(0) = ${valor('P0')}';
      case 'exponencial':
        return 'dP/dt − ${valor('r')}·P = ${valor('b')}  ·  '
            'P(0) = ${valor('P0')}';
      case 'ciclico':
        final omega = 2 * 3.141592653589793 / (parametros['periodo_min'] ?? 1);
        return "P'' + ω²·P = 0  ·  ω = ${_n(omega)} rad/min  ·  "
            'P(0) = ${valor('P0')}, P\'(0) = ${valor('dP0')}';
      default:
        return estado.escenarioActivo.edo;
    }
  }

  String _homogenea(PasosSolucionAnalitica pasos) {
    final r1 = pasos.r1;
    final r2 = pasos.r2;
    if (r1 == null || r2 == null) return 'y_h(t) = No disponible';
    return 'y_h(t) = ${_n(pasos.c1Homogenea ?? 0)}·exp(${_n(r1)}·t) '
        '+ ${_n(pasos.c2Homogenea ?? 0)}·exp(${_n(r2)}·t)';
  }

  String _particular(String idEscenario, PasosSolucionAnalitica pasos) {
    final coeficientes = pasos.coeficientesParticulares;
    switch (idEscenario) {
      case 'lineal':
        return 'y_p(t) = ${_n(coeficientes['p0'] ?? 0)}·t '
            '+ (${_n(coeficientes['p1'] ?? 0)})';
      case 'constante':
        return 'y_p(t) = K = ${_n(coeficientes['K'] ?? 0)}';
      case 'exponencial':
        final a0 = _n(coeficientes['A0'] ?? 0);
        final a1 = _n(coeficientes['A1'] ?? 0);
        final r = _tasaExponencial(pasos);
        if (r == null || r.abs() < 1e-12) {
          return 'y_p(t) = $a0 + $a1·t';
        }
        final resonante = (pasos.r1 != null && (r - pasos.r1!).abs() < 1e-9) ||
            (pasos.r2 != null && (r - pasos.r2!).abs() < 1e-9);
        return resonante
            ? 'y_p(t) = $a0 + $a1·t·exp(${_n(r)}·t)'
            : 'y_p(t) = $a0 + $a1·exp(${_n(r)}·t)';
      case 'ciclico':
        return 'y_p(t) = ${_n(coeficientes['M'] ?? 0)}·cos(ω·t) '
            '+ ${_n(coeficientes['N'] ?? 0)}·sin(ω·t)';
      default:
        return 'y_p(t) = No disponible';
    }
  }

  double? _tasaExponencial(PasosSolucionAnalitica pasos) {
    final r = pasos.coeficientesParticulares['tasa'];
    if (r != null) return r;
    return null;
  }

  List<TerminoSolucion> _derivadas(List<TerminoSolucion> terminos) {
    final derivadas = <TerminoSolucion>[];
    for (final termino in terminos) {
      derivadas.addAll(termino.derivar());
    }
    return derivadas;
  }

  String _comportamiento(PasosSolucionAnalitica? pasos) {
    if (pasos == null || pasos.r1 == null || pasos.r2 == null) {
      return 'No disponible';
    }
    return pasos.r1! > 0 || pasos.r2! > 0 ? 'Inestable' : 'Estable';
  }

  String _tiempo(ResultadoColapso? colapso) {
    if (colapso == null || colapso.tiempo == null) return 'No colapsa';
    return '${_n(colapso.tiempo!)} min';
  }

  String _n(double valor, {int decimales = 6}) =>
      formatearNumero(valor, decimales: decimales);

  String _notacion(double valor) {
    if (valor.isNaN || valor.isInfinite) return '—';
    return valor.toStringAsExponential(2);
  }

  Widget _avisoVerificacion(ResultadoVerificacion verificacion) {
    final estadoVerificacion = verificacion.estado;
    final Color color;
    final IconData icono;
    final String mensaje;
    switch (estadoVerificacion) {
      case EstadoVerificacion.coincide:
        color = AppColores.exito;
        icono = Icons.check_circle_outline;
        mensaje =
            'Coinciden. Sin discrepancia: la solución numérica coincide con la analítica dentro del umbral relativo.';
      case EstadoVerificacion.discrepancia:
        color = AppColores.importante;
        icono = Icons.warning_amber_rounded;
        mensaje =
            'Discrepancia detectada: el error relativo supera el umbral configurado.';
      case EstadoVerificacion.noDisponible:
        color = AppColores.textoSecundario;
        icono = Icons.info_outline;
        mensaje =
            'Verificación analítica no disponible para esta configuración; se usa solo el cálculo numérico';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: TextStyle(color: color, fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
          if (verificacion.motivoNoDisponible != null) ...[
            const SizedBox(height: 8),
            Text(
              verificacion.motivoNoDisponible!,
              style: const TextStyle(
                color: AppColores.textoSecundario,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _termino(double coeficiente, String variable) {
    final signo = coeficiente < 0 ? '-' : '+';
    return ' $signo ${formatearNumero(coeficiente.abs(), decimales: 6)}·$variable';
  }

  String _terminoInicial(double coeficiente, String variable) {
    final signo = coeficiente < 0 ? '-' : '';
    return '$signo${formatearNumero(coeficiente.abs(), decimales: 6)}·$variable';
  }

  ({String x, String y}) _calcularLimites(EstadoAplicacion estado) {
    final coeficientes = estado.sistema.coeficientes;
    final parametros = estado.escenarioActivo.mapaParametros;
    final determinante =
        coeficientes.a11 * coeficientes.a22 -
        coeficientes.a12 * coeficientes.a21;
    final traza = coeficientes.a11 + coeficientes.a22;

    if (traza > 0 || determinante < 0) {
      return (x: 'No acotado', y: 'No acotado');
    }

    final escenario = estado.escenarioActivo.id;
    if (escenario == 'ciclico') {
      return (x: 'Acotado (oscila)', y: 'Acotado (oscila)');
    }
    var divergente = false;
    var entradaLimite = estado.entradaInicial;
    if (escenario == 'lineal') {
      final pendiente = parametros['m'] ?? 0;
      divergente = pendiente.abs() > 1e-12;
    }
    if (escenario == 'exponencial') {
      final tasa = parametros['r'] ?? 0;
      final q = parametros['b'] ?? 0;
      final inicial = parametros['P0'] ?? 0;
      if (tasa.abs() < 1e-12) {
        divergente = q.abs() > 1e-12;
        entradaLimite = divergente ? 0 : inicial;
      } else {
        final amplitud = inicial + q / tasa;
        divergente = tasa > 0 && amplitud.abs() > 1e-12;
        entradaLimite = -q / tasa;
      }
    }
    if (divergente) {
      return (x: 'No acotado', y: 'No acotado');
    }

    if (determinante.abs() < 1e-12) {
      return (x: 'No determinado', y: 'No determinado');
    }

    final x = -entradaLimite * coeficientes.a22 / determinante;
    final y = entradaLimite * coeficientes.a21 / determinante;
    return (
      x: formatearNumero(x, decimales: 6),
      y: formatearNumero(y, decimales: 6),
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
