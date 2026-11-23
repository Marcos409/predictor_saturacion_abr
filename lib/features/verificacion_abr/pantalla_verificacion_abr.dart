import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/campo_numerico.dart';
import '../../app/widgets/contenedor_modulo.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../app/widgets/panel_seccion.dart';
import '../../core/config/cargador_referencia_abr.dart';
import '../../core/models/escenario_trafico.dart';
import '../../core/models/referencia_abr.dart';
import '../../core/models/sistema.dart';
import 'calculadora_verificacion_abr.dart';
import 'resultado_verificacion_abr.dart';

class PantallaVerificacionAbr extends StatefulWidget {
  const PantallaVerificacionAbr({super.key});

  @override
  State<PantallaVerificacionAbr> createState() =>
      _PantallaVerificacionAbrState();
}

class _PantallaVerificacionAbrState extends State<PantallaVerificacionAbr> {
  final CalculadoraVerificacionAbr _calculadora = CalculadoraVerificacionAbr();

  ConfiguracionSistema? _sistemaBase;
  List<EscenarioTrafico> _escenarios = const [];
  ReferenciaAbr? _referencia;
  bool _cargando = true;
  String? _errorCarga;
  String? _errorCalculo;

  String _idEscenario = '';
  final Map<String, Map<String, double>> _parametrosPorEscenario = {};

  String _modo = 'derivado';
  double _c1 = 0;
  double _volumenA = 0;
  double _volumenB = 0;
  double _limiteA = 0;
  double _limiteB = 0;
  double _tiempoReaccion = 0;
  double _aAB = 0;
  double _aSalida = 0;
  double _bAA = 0;
  double _bSalida = 0;
  double _a11 = 0;
  double _a12 = 0;
  double _a21 = 0;
  double _a22 = 0;
  double _x0 = 0;
  double _y0 = 0;
  double _umbral = 0;

  ResultadoVerificacionAbr? _resultado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final sistemaJson = await rootBundle.loadString(
        'assets/config/sistema.json',
      );
      final escenariosJson = await rootBundle.loadString(
        'assets/config/escenarios.json',
      );

      final sistema = ConfiguracionSistema.fromJson(
        jsonDecode(sistemaJson) as Map<String, dynamic>,
      );
      final configuracionEscenarios = ConfiguracionEscenarios.fromJson(
        jsonDecode(escenariosJson) as Map<String, dynamic>,
      );

      ReferenciaAbr? referencia;
      try {
        referencia = await const CargadorReferenciaAbr().cargar();
      } catch (_) {
        referencia = null;
      }

      if (!mounted) return;

      setState(() {
        _sistemaBase = sistema;
        _escenarios = configuracionEscenarios.escenarios;
        _referencia = referencia;
        _idEscenario = _escenarios.first.id;
        _parametrosPorEscenario
          ..clear()
          ..addEntries(
            _escenarios.map(
              (escenario) => MapEntry(escenario.id, {
                for (final parametro in escenario.parametros)
                  parametro.clave: parametro.valor,
              }),
            ),
          );
        _aplicarTanquesSistema(sistema.tanques);
        _x0 = sistema.condicionesIniciales.x0;
        _y0 = sistema.condicionesIniciales.y0;
        _umbral = sistema.verificacion.umbralError;
        _cargando = false;
      });
      _resolver();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorCarga = 'No se pudo cargar la configuración del ABR: $error';
        _cargando = false;
      });
    }
  }

  void _aplicarTanquesSistema(TanquesSistema tanques) {
    _modo = tanques.modoCoeficientes;
    _c1 = tanques.c1;
    _volumenA = tanques.volumenA;
    _volumenB = tanques.volumenB;
    _limiteA = tanques.limiteA;
    _limiteB = tanques.limiteB;
    _tiempoReaccion = tanques.tiempoReaccionMin;
    _aAB = tanques.caudales.aAB;
    _aSalida = tanques.caudales.aSalida;
    _bAA = tanques.caudales.bAA;
    _bSalida = tanques.caudales.bSalida;
    _a11 = tanques.coeficientesDirectos.a11;
    _a12 = tanques.coeficientesDirectos.a12;
    _a21 = tanques.coeficientesDirectos.a21;
    _a22 = tanques.coeficientesDirectos.a22;
  }

  void _aplicarTanquesReferencia(TanquesAbr tanques) {
    _modo = tanques.modoCoeficientes;
    _c1 = tanques.c1;
    _volumenA = tanques.volumenA;
    _volumenB = tanques.volumenB;
    _limiteA = tanques.limiteA;
    _limiteB = tanques.limiteB;
    _tiempoReaccion = tanques.tiempoReaccionMin;
    _aAB = tanques.caudales.aAB;
    _aSalida = tanques.caudales.aSalida;
    _bAA = tanques.caudales.bAA;
    _bSalida = tanques.caudales.bSalida;
    _a11 = tanques.coeficientesDirectos.a11;
    _a12 = tanques.coeficientesDirectos.a12;
    _a21 = tanques.coeficientesDirectos.a21;
    _a22 = tanques.coeficientesDirectos.a22;
  }

  Map<String, double> get _parametrosActuales =>
      _parametrosPorEscenario[_idEscenario] ?? const {};

  EscenarioTrafico get _escenarioActual {
    final base = _escenarios.firstWhere(
      (escenario) => escenario.id == _idEscenario,
      orElse: () => _escenarios.first,
    );
    return base.copyWith(
      parametros: [
        for (final parametro in base.parametros)
          parametro.copyWith(
            valor: _parametrosActuales[parametro.clave] ?? parametro.valor,
          ),
      ],
    );
  }

  ConfiguracionSistema _configuracionActual() {
    final base = _sistemaBase!;
    final tanques = TanquesSistema(
      modoCoeficientes: _modo,
      c1: _c1,
      volumenA: _volumenA,
      volumenB: _volumenB,
      limiteA: _limiteA,
      limiteB: _limiteB,
      tiempoReaccionMin: _tiempoReaccion,
      caudales: CaudalesSistema(
        aAB: _aAB,
        aSalida: _aSalida,
        bAA: _bAA,
        bSalida: _bSalida,
      ),
      coeficientesDirectos: CoeficientesSistema(
        a11: _a11,
        a12: _a12,
        a21: _a21,
        a22: _a22,
      ),
    );
    return base.copyWith(
      tanques: tanques,
      condicionesIniciales: CondicionesIniciales(x0: _x0, y0: _y0),
      verificacion: base.verificacion.copyWith(umbralError: _umbral),
    );
  }

  void _actualizar(VoidCallback cambio) {
    setState(cambio);
    _resolver();
  }

  void _actualizarParametro(String clave, double valor) {
    _actualizar(() {
      _parametrosPorEscenario.putIfAbsent(_idEscenario, () => {})[clave] =
          valor;
    });
  }

  void _resolver() {
    final sistema = _sistemaBase;
    if (sistema == null || _escenarios.isEmpty) return;

    final configuracion = _configuracionActual();
    final errorTanques = configuracion.tanques.validar();
    if (errorTanques != null) {
      setState(() {
        _errorCalculo = errorTanques;
        _resultado = null;
      });
      return;
    }
    if (_umbral < 0) {
      setState(() {
        _errorCalculo = 'El umbral de comparación no puede ser negativo.';
        _resultado = null;
      });
      return;
    }

    try {
      final resultado = _calculadora.calcular(
        escenario: _escenarioActual,
        configuracion: configuracion,
        referencia: _referencia,
        umbralComparacion: _umbral,
      );
      setState(() {
        _resultado = resultado;
        _errorCalculo = null;
      });
    } catch (error) {
      setState(() {
        _errorCalculo = error.toString();
        _resultado = null;
      });
    }
  }

  void _cargarValoresAbr() {
    final referencia = _referencia;
    if (referencia == null) {
      setState(() {
        _errorCalculo = 'No se pudo leer assets/config/referencia_abr.json.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final caso = referencia.buscarCasoPorId(_idEscenario);

    setState(() {
      _aplicarTanquesReferencia(referencia.tanques);
      if (caso != null) {
        final parametros = _parametrosPorEscenario.putIfAbsent(
          _idEscenario,
          () => {},
        );
        parametros['P0'] = caso.fase1.p0;
        final r = caso.fase1.r;
        final b = caso.fase1.b;
        final dP0 = caso.fase1.dP0;
        final periodo = caso.fase1.periodoMin;
        if (r != null) parametros['r'] = r;
        if (b != null) parametros['b'] = b;
        if (dP0 != null) parametros['dP0'] = dP0;
        if (periodo != null) parametros['periodo_min'] = periodo;
        _x0 = caso.fase2.x0;
        _y0 = caso.fase2.y0;
      }
    });
    _resolver();
  }

  void _cambiarModo(bool directo) {
    setState(() {
      if (directo) {
        final derivados = calcularCoeficientesSistema(
          TanquesSistema(
            modoCoeficientes: 'derivado',
            c1: _c1,
            volumenA: _volumenA,
            volumenB: _volumenB,
            limiteA: _limiteA,
            limiteB: _limiteB,
            tiempoReaccionMin: _tiempoReaccion,
            caudales: CaudalesSistema(
              aAB: _aAB,
              aSalida: _aSalida,
              bAA: _bAA,
              bSalida: _bSalida,
            ),
            coeficientesDirectos: CoeficientesSistema(
              a11: _a11,
              a12: _a12,
              a21: _a21,
              a22: _a22,
            ),
          ),
        );
        _a11 = derivados.a11;
        _a12 = derivados.a12;
        _a21 = derivados.a21;
        _a22 = derivados.a22;
      }
      _modo = directo ? 'directo' : 'derivado';
    });
    _resolver();
  }

  Future<void> _copiarEcuaciones() async {
    final resultado = _resultado;
    if (resultado == null) {
      _mostrarAviso('Primero resuelve para generar las ecuaciones.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _textoEcuaciones(resultado)));
    if (!mounted) return;
    _mostrarAviso('Ecuaciones copiadas al portapapeles.');
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return ContenedorModulo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoPantalla(
            titulo: 'Verificación ABR',
            descripcion:
                'Carga tus valores del ABR, resuelve el paso a paso y compara '
                'las ecuaciones del motor con la referencia.',
          ),
          const SizedBox(height: 24),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorCarga != null) ...[
            MensajeError(mensaje: _errorCarga!),
            const SizedBox(height: 16),
          ],
          if (!_cargando && _errorCarga == null) ...[
            _construirFormulario(),
            const SizedBox(height: 20),
            if (_errorCalculo != null) ...[
              MensajeError(mensaje: _errorCalculo!),
              const SizedBox(height: 16),
            ],
            if (_resultado != null) _construirResultados(_resultado!),
          ],
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    final escenario = _escenarioActual;
    final esDirecto = _modo == 'directo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelSeccion(
          titulo: 'Escenario y acciones',
          subtitulo:
              'Elige el escenario de Fase 1, carga los valores del ABR o '
              'resuelve con los valores actuales.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<String>(
                      initialValue: _idEscenario,
                      isExpanded: true,
                      items: [
                        for (final item in _escenarios)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.nombre),
                          ),
                      ],
                      onChanged: (id) {
                        if (id == null) return;
                        setState(() => _idEscenario = id);
                        _resolver();
                      },
                      decoration: const InputDecoration(labelText: 'Escenario'),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _cargarValoresAbr,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Cargar valores del ABR'),
                  ),
                  FilledButton.icon(
                    onPressed: _resolver,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Resolver'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resultado == null ? null : _copiarEcuaciones,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar ecuaciones'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'El motor usa minutos como única unidad de tiempo. '
                'Los valores de referencia_abr.json no se corrigen ni se recalculan.',
                style: TextStyle(
                  color: AppColores.textoSecundario,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PanelSeccion(
          titulo: 'Fase 1 · Tráfico',
          subtitulo:
              'Parámetros del escenario ${escenario.nombre}. Se usan para '
              'construir V1(t).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final parametro in escenario.parametros)
                    _campo(
                      clave: ValueKey(
                        'fase1-${escenario.id}-${parametro.clave}',
                      ),
                      etiqueta: parametro.nombre,
                      valor: parametro.valor,
                      alCambiar: (valor) =>
                          _actualizarParametro(parametro.clave, valor),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _Ecuacion(texto: 'Receta registrada: ${escenario.expresionV1}'),
              if (_resultado != null) ...[
                const SizedBox(height: 8),
                _Ecuacion(
                  texto:
                      'V1(t) con los números sustituidos: '
                      '${_resultado!.expresionV1}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        PanelSeccion(
          titulo: 'Tanques y coeficientes',
          subtitulo:
              'Los tubos son fijos; caudales, volúmenes, límites, c1 y '
              'condiciones iniciales son editables.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usar coeficientes directos'),
                subtitle: Text(
                  esDirecto
                      ? 'Se usan a11, a12, a21 y a22 ingresados a mano.'
                      : 'Los coeficientes se derivan de los caudales y volúmenes.',
                  style: const TextStyle(
                    color: AppColores.textoSecundario,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                value: esDirecto,
                onChanged: _cambiarModo,
              ),
              const SizedBox(height: 8),
              const _Subtitulo(texto: 'Parámetros de los tanques'),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _campo(
                    clave: const ValueKey('c1'),
                    etiqueta: 'c1 · concentración de entrada',
                    valor: _c1,
                    alCambiar: (valor) => _actualizar(() => _c1 = valor),
                  ),
                  _campo(
                    clave: const ValueKey('volumen_A'),
                    etiqueta: 'volumen_A · Capa Web',
                    valor: _volumenA,
                    alCambiar: (valor) => _actualizar(() => _volumenA = valor),
                  ),
                  _campo(
                    clave: const ValueKey('volumen_B'),
                    etiqueta: 'volumen_B · Base de Datos',
                    valor: _volumenB,
                    alCambiar: (valor) => _actualizar(() => _volumenB = valor),
                  ),
                  _campo(
                    clave: const ValueKey('limite_A'),
                    etiqueta: 'limite_A · límite crítico Web',
                    valor: _limiteA,
                    alCambiar: (valor) => _actualizar(() => _limiteA = valor),
                  ),
                  _campo(
                    clave: const ValueKey('limite_B'),
                    etiqueta: 'limite_B · límite crítico BD',
                    valor: _limiteB,
                    alCambiar: (valor) => _actualizar(() => _limiteB = valor),
                  ),
                  _campo(
                    clave: const ValueKey('tiempo_reaccion'),
                    etiqueta: 'tiempo_reaccion_min · TI',
                    valor: _tiempoReaccion,
                    sufijo: 'min',
                    alCambiar: (valor) =>
                        _actualizar(() => _tiempoReaccion = valor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _Subtitulo(texto: 'Caudales de los tubos'),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _campo(
                    clave: const ValueKey('A_a_B'),
                    etiqueta: 'A → B · consultas',
                    valor: _aAB,
                    habilitado: !esDirecto,
                    alCambiar: (valor) => _actualizar(() => _aAB = valor),
                  ),
                  _campo(
                    clave: const ValueKey('A_salida'),
                    etiqueta: 'A · salida (rate limiting)',
                    valor: _aSalida,
                    habilitado: !esDirecto,
                    alCambiar: (valor) => _actualizar(() => _aSalida = valor),
                  ),
                  _campo(
                    clave: const ValueKey('B_a_A'),
                    etiqueta: 'B → A · caché y retorno',
                    valor: _bAA,
                    habilitado: !esDirecto,
                    alCambiar: (valor) => _actualizar(() => _bAA = valor),
                  ),
                  _campo(
                    clave: const ValueKey('B_salida'),
                    etiqueta: 'B · salida',
                    valor: _bSalida,
                    habilitado: !esDirecto,
                    alCambiar: (valor) => _actualizar(() => _bSalida = valor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _Subtitulo(texto: 'Coeficientes directos'),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _campo(
                    clave: const ValueKey('a11'),
                    etiqueta: 'a11 · Capa Web sobre sí misma',
                    valor: _a11,
                    habilitado: esDirecto,
                    alCambiar: (valor) => _actualizar(() => _a11 = valor),
                  ),
                  _campo(
                    clave: const ValueKey('a12'),
                    etiqueta: 'a12 · BD hacia Capa Web',
                    valor: _a12,
                    habilitado: esDirecto,
                    alCambiar: (valor) => _actualizar(() => _a12 = valor),
                  ),
                  _campo(
                    clave: const ValueKey('a21'),
                    etiqueta: 'a21 · Capa Web hacia BD',
                    valor: _a21,
                    habilitado: esDirecto,
                    alCambiar: (valor) => _actualizar(() => _a21 = valor),
                  ),
                  _campo(
                    clave: const ValueKey('a22'),
                    etiqueta: 'a22 · BD sobre sí misma',
                    valor: _a22,
                    habilitado: esDirecto,
                    alCambiar: (valor) => _actualizar(() => _a22 = valor),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PanelSeccion(
          titulo: 'Condiciones iniciales y comparación',
          subtitulo:
              'Nivel inicial de cada tanque y umbral para decidir si las '
              'ecuaciones coinciden con la referencia.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _campo(
                clave: const ValueKey('x0'),
                etiqueta: 'x(0) · Capa Web',
                valor: _x0,
                alCambiar: (valor) => _actualizar(() => _x0 = valor),
              ),
              _campo(
                clave: const ValueKey('y0'),
                etiqueta: 'y(0) · Base de Datos',
                valor: _y0,
                alCambiar: (valor) => _actualizar(() => _y0 = valor),
              ),
              _campo(
                clave: const ValueKey('umbral_comparacion'),
                etiqueta: 'Umbral de comparación',
                valor: _umbral,
                alCambiar: (valor) => _actualizar(() => _umbral = valor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _campo({
    required Key clave,
    required String etiqueta,
    required double valor,
    required ValueChanged<double> alCambiar,
    bool habilitado = true,
    String? sufijo,
  }) {
    return SizedBox(
      width: 250,
      child: CampoNumerico(
        key: clave,
        etiqueta: etiqueta,
        valorInicial: valor,
        sufijo: sufijo,
        habilitado: habilitado,
        alCambiar: alCambiar,
      ),
    );
  }

  Widget _construirResultados(ResultadoVerificacionAbr resultado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTanques(resultado),
        const SizedBox(height: 20),
        _panelFase1(resultado),
        const SizedBox(height: 20),
        _panelSistema(resultado),
        const SizedBox(height: 20),
        _panelHomogenea(resultado),
        const SizedBox(height: 20),
        _panelEcuacionesFinales(resultado),
        const SizedBox(height: 20),
        _panelColapso(resultado),
        const SizedBox(height: 20),
        _panelLimites(resultado),
        const SizedBox(height: 20),
        _panelComparacion(resultado),
      ],
    );
  }

  Widget _panelTanques(ResultadoVerificacionAbr resultado) {
    final tanques = resultado.configuracion.tanques;
    final derivados = calcularCoeficientesSistema(
      tanques.copyWith(modoCoeficientes: 'derivado'),
    );
    final usados = resultado.configuracion.coeficientes;

    return PanelSeccion(
      titulo: 'Tanques: caudales y volúmenes → coeficientes',
      subtitulo: tanques.modoCoeficientes == 'derivado'
          ? 'Modo derivado: los coeficientes usados salen de los tubos y los volúmenes.'
          : 'Modo directo: los coeficientes usados son los ingresados; la derivación se muestra como referencia.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Ecuacion(
            texto:
                'a11 = −(A→B + salida A) / volumen_A = '
                '−(${_n(tanques.caudales.aAB)} + ${_n(tanques.caudales.aSalida)}) '
                '/ ${_n(tanques.volumenA)} = ${_n(derivados.a11)}',
          ),
          const SizedBox(height: 8),
          _Ecuacion(
            texto:
                'a12 = (B→A) / volumen_B = '
                '${_n(tanques.caudales.bAA)} / ${_n(tanques.volumenB)} = '
                '${_n(derivados.a12)}',
          ),
          const SizedBox(height: 8),
          _Ecuacion(
            texto:
                'a21 = (A→B) / volumen_A = '
                '${_n(tanques.caudales.aAB)} / ${_n(tanques.volumenA)} = '
                '${_n(derivados.a21)}',
          ),
          const SizedBox(height: 8),
          _Ecuacion(
            texto:
                'a22 = −(B→A + salida B) / volumen_B = '
                '−(${_n(tanques.caudales.bAA)} + ${_n(tanques.caudales.bSalida)}) '
                '/ ${_n(tanques.volumenB)} = ${_n(derivados.a22)}',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(
                etiqueta: 'Capa Web · A',
                valor:
                    'volumen ${_n(tanques.volumenA)} · '
                    'límite ${_n(tanques.limiteA)}',
              ),
              _Dato(
                etiqueta: 'Base de Datos · B',
                valor:
                    'volumen ${_n(tanques.volumenB)} · '
                    'límite ${_n(tanques.limiteB)}',
              ),
              _Dato(
                etiqueta: 'Tiempo de reacción de TI',
                valor: '${_n(tanques.tiempoReaccionMin)} min',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(etiqueta: 'a11 usado', valor: _n(usados.a11)),
              _Dato(etiqueta: 'a12 usado', valor: _n(usados.a12)),
              _Dato(etiqueta: 'a21 usado', valor: _n(usados.a21)),
              _Dato(etiqueta: 'a22 usado', valor: _n(usados.a22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelFase1(ResultadoVerificacionAbr resultado) {
    return PanelSeccion(
      titulo: 'Fase 1 · EDO y V1(t)',
      subtitulo: 'EDO, método de resolución y entrada final con números.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(
                etiqueta: 'Escenario',
                valor:
                    '${resultado.escenario.nombre} '
                    '(${resultado.escenario.id})',
              ),
              _Dato(etiqueta: 'Método', valor: resultado.metodoFase1),
              _Dato(
                etiqueta: 'Horizonte',
                valor: '${_n(resultado.horizonteMin, decimales: 0)} min',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Ecuacion(texto: 'EDO: ${resultado.edoFase1}'),
          const SizedBox(height: 8),
          _Ecuacion(texto: 'V1(t) = ${resultado.expresionV1}'),
          if (resultado.traficoNegativoEnHorizonte) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColores.importante.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColores.importante.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColores.importante,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Advertencia: c1·V1(t) toma valores negativos en el horizonte. '
                      'Valor mínimo: ${_n(resultado.traficoMinimoEnHorizonte, decimales: 6)}.',
                      style: const TextStyle(
                        color: AppColores.importante,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panelSistema(ResultadoVerificacionAbr resultado) {
    final coeficientes = resultado.configuracion.coeficientes;
    final c1 = resultado.configuracion.tanques.c1;
    final pasos = resultado.solucion.pasos;

    return PanelSeccion(
      titulo: 'Fase 2 · Sistema y EDO de 2.º orden',
      subtitulo: 'Sistema de dos tanques con x = Capa Web, y = Base de Datos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Ecuacion(
            texto:
                "x' = ${_n(c1)}·V1(t)"
                "${_termino(coeficientes.a11, 'x')}"
                "${_termino(coeficientes.a12, 'y')}",
          ),
          const SizedBox(height: 8),
          _Ecuacion(
            texto:
                "y' = ${_terminoInicial(coeficientes.a21, 'x')}"
                "${_termino(coeficientes.a22, 'y')}",
          ),
          const SizedBox(height: 14),
          _Ecuacion(texto: pasos.edo),
          const SizedBox(height: 8),
          _Ecuacion(
            texto:
                'Ecuación característica: '
                'r² + (${_n(pasos.a)})·r + (${_n(pasos.b)}) = 0',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(etiqueta: 'a', valor: _n(pasos.a)),
              _Dato(etiqueta: 'b', valor: _n(pasos.b)),
              _Dato(etiqueta: 'c', valor: _n(pasos.c)),
              _Dato(
                etiqueta: 'r1',
                valor: pasos.r1 == null ? '—' : _n(pasos.r1!),
              ),
              _Dato(
                etiqueta: 'r2',
                valor: pasos.r2 == null ? '—' : _n(pasos.r2!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelHomogenea(ResultadoVerificacionAbr resultado) {
    final pasos = resultado.solucion.pasos;
    final coeficientes = pasos.coeficientesParticulares;

    return PanelSeccion(
      titulo: 'Fase 2 · Yc, Yp, C1 y C2',
      subtitulo:
          'Solución homogénea y particular antes de aplicar las condiciones iniciales.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Ecuacion(texto: resultado.expresionYc),
          const SizedBox(height: 8),
          _Ecuacion(texto: 'Yp(t) = ${resultado.expresionYp}'),
          if (coeficientes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                for (final entrada in coeficientes.entries)
                  _Dato(
                    etiqueta: entrada.key,
                    valor: _n(entrada.value, decimales: 6),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(
                etiqueta: 'C1',
                valor: resultado.c1Homogenea == null
                    ? '—'
                    : _n(resultado.c1Homogenea!, decimales: 6),
              ),
              _Dato(
                etiqueta: 'C2',
                valor: resultado.c2Homogenea == null
                    ? '—'
                    : _n(resultado.c2Homogenea!, decimales: 6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelEcuacionesFinales(ResultadoVerificacionAbr resultado) {
    return PanelSeccion(
      titulo: 'Fase 2 · Ecuaciones finales',
      subtitulo: 'Soluciones x(t), y(t) y sus derivadas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Ecuacion(texto: 'x(t) = ${resultado.solucion.expresionX}'),
          const SizedBox(height: 8),
          _Ecuacion(texto: 'y(t) = ${resultado.solucion.expresionY}'),
          const SizedBox(height: 8),
          _Ecuacion(texto: "x'(t) = ${resultado.expresionXPrima}"),
          const SizedBox(height: 8),
          _Ecuacion(texto: "y'(t) = ${resultado.expresionYPrima}"),
        ],
      ),
    );
  }

  Widget _panelColapso(ResultadoVerificacionAbr resultado) {
    final colapsoWeb = resultado.colapsoWeb.tiempo;
    final colapsoBd = resultado.colapsoBd.tiempo;
    final ventana = resultado.ventana.ventanaAccion;
    final ventanaWeb = resultado.ventana.ventanaCapaWeb;
    final ventanaBd = resultado.ventana.ventanaBaseDatos;

    return PanelSeccion(
      titulo: 'Colapso y Ventana de Acción',
      subtitulo:
          'Detección sobre la solución del motor en un horizonte de '
          '${_n(resultado.horizonteMin, decimales: 0)} min.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _IndicadorResultado(
                titulo: 'COLAPSO CAPA WEB',
                valor: colapsoWeb == null
                    ? 'No colapsa'
                    : '${_n(colapsoWeb)} min',
                color: AppColores.primarioOscuro,
              ),
              _IndicadorResultado(
                titulo: 'COLAPSO BASE DE DATOS',
                valor: colapsoBd == null
                    ? 'No colapsa'
                    : '${_n(colapsoBd)} min',
                color: AppColores.graficoBD,
              ),
              _IndicadorResultado(
                titulo: 'VENTANA DE ACCIÓN',
                valor: ventana == null ? 'Sin colapso' : '${_n(ventana)} min',
                color: ventana != null && ventana < 0
                    ? AppColores.importante
                    : AppColores.exito,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Dato(
                etiqueta: 'Tiempo de reacción de TI',
                valor: '${_n(resultado.configuracion.tiempoReaccion)} min',
              ),
              _Dato(
                etiqueta: 'Ventana Web',
                valor: ventanaWeb == null
                    ? 'Sin colapso'
                    : '${_n(ventanaWeb)} min',
              ),
              _Dato(
                etiqueta: 'Ventana BD',
                valor: ventanaBd == null
                    ? 'Sin colapso'
                    : '${_n(ventanaBd)} min',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelLimites(ResultadoVerificacionAbr resultado) {
    return PanelSeccion(
      titulo: 'Límites cuando t → ∞',
      subtitulo:
          'Comportamiento asintótico de las ecuaciones finales del motor.',
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _Dato(etiqueta: 'lim x(t)', valor: resultado.limiteX),
          _Dato(etiqueta: 'lim y(t)', valor: resultado.limiteY),
        ],
      ),
    );
  }

  Widget _panelComparacion(ResultadoVerificacionAbr resultado) {
    return PanelSeccion(
      titulo: 'Comparación con la referencia ABR',
      subtitulo:
          'Ecuación del motor frente a referencia_abr.json. '
          'Umbral configurable: ${_n(_umbral, decimales: 6)}.',
      child: resultado.comparacion.isEmpty
          ? const Text(
              'Sin datos de comparación para este escenario.',
              style: TextStyle(color: AppColores.textoSecundario, fontSize: 12),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resultado.notaComparacion != null) ...[
                  Text(
                    resultado.notaComparacion!,
                    style: const TextStyle(
                      color: AppColores.secundarioTexto,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStatePropertyAll(
                      AppColores.panelSecundario.withValues(alpha: 0.6),
                    ),
                    columns: const [
                      DataColumn(label: Text('Variable')),
                      DataColumn(label: Text('Ecuación del motor')),
                      DataColumn(label: Text('Ecuación de referencia')),
                      DataColumn(label: Text('Error máximo')),
                      DataColumn(label: Text('Estado')),
                    ],
                    rows: [
                      for (final fila in resultado.comparacion)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                fila.variable,
                                style: const TextStyle(
                                  color: AppColores.textoPrincipal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 300,
                                child: Text(
                                  fila.ecuacionMotor,
                                  style: const TextStyle(
                                    color: AppColores.primarioOscuro,
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 300,
                                child: Text(
                                  fila.ecuacionReferencia,
                                  style: const TextStyle(
                                    color: AppColores.textoPrincipal,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                fila.errorMaximo == null
                                    ? '—'
                                    : _n(fila.errorMaximo!, decimales: 6),
                                style: const TextStyle(
                                  color: AppColores.textoPrincipal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(_chipEstado(fila)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chipEstado(FilaComparacionAbr fila) {
    final coincide = fila.coincide;
    final color = coincide ? AppColores.exito : AppColores.importante;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        coincide ? 'coincide' : 'difiere',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _textoEcuaciones(ResultadoVerificacionAbr resultado) {
    final tanques = resultado.configuracion.tanques;
    final coeficientes = resultado.configuracion.coeficientes;
    final pasos = resultado.solucion.pasos;
    final buffer = StringBuffer()
      ..writeln('TI-Saturation Predictor · Verificación ABR')
      ..writeln(
        'Escenario: ${resultado.escenario.nombre} '
        '(${resultado.escenario.id})',
      )
      ..writeln('Unidad de tiempo: ${resultado.configuracion.unidadTiempo}')
      ..writeln()
      ..writeln('TANQUES')
      ..writeln('Modo de coeficientes: ${tanques.modoCoeficientes}')
      ..writeln('c1 = ${_n(tanques.c1)}')
      ..writeln('volumen_A = ${_n(tanques.volumenA)}')
      ..writeln('volumen_B = ${_n(tanques.volumenB)}')
      ..writeln('limite_A = ${_n(tanques.limiteA)}')
      ..writeln('limite_B = ${_n(tanques.limiteB)}')
      ..writeln('tiempo_reaccion_min = ${_n(tanques.tiempoReaccionMin)}')
      ..writeln('A_a_B = ${_n(tanques.caudales.aAB)}')
      ..writeln('A_salida = ${_n(tanques.caudales.aSalida)}')
      ..writeln('B_a_A = ${_n(tanques.caudales.bAA)}')
      ..writeln('B_salida = ${_n(tanques.caudales.bSalida)}')
      ..writeln(
        'a11 = ${_n(coeficientes.a11)} · '
        'a12 = ${_n(coeficientes.a12)} · '
        'a21 = ${_n(coeficientes.a21)} · '
        'a22 = ${_n(coeficientes.a22)}',
      )
      ..writeln()
      ..writeln('FASE 1')
      ..writeln('EDO: ${resultado.edoFase1}')
      ..writeln('Método: ${resultado.metodoFase1}')
      ..writeln('V1(t) = ${resultado.expresionV1}');

    if (resultado.traficoNegativoEnHorizonte) {
      buffer.writeln(
        'Advertencia: c1·V1(t) negativo en el horizonte; '
        'mínimo ${_n(resultado.traficoMinimoEnHorizonte, decimales: 6)}.',
      );
    }

    buffer
      ..writeln()
      ..writeln('FASE 2')
      ..writeln(
        "x' = ${_n(tanques.c1)}·V1(t)"
        "${_termino(coeficientes.a11, 'x')}"
        "${_termino(coeficientes.a12, 'y')}",
      )
      ..writeln(
        "y' = ${_terminoInicial(coeficientes.a21, 'x')}"
        "${_termino(coeficientes.a22, 'y')}",
      )
      ..writeln('EDO de 2.º orden: ${pasos.edo}')
      ..writeln(
        'Ecuación característica: '
        'r² + (${_n(pasos.a)})·r + (${_n(pasos.b)}) = 0',
      )
      ..writeln('r1 = ${pasos.r1 == null ? '—' : _n(pasos.r1!)}')
      ..writeln('r2 = ${pasos.r2 == null ? '—' : _n(pasos.r2!)}')
      ..writeln(resultado.expresionYc)
      ..writeln('Yp(t) = ${resultado.expresionYp}')
      ..writeln(
        'C1 = ${resultado.c1Homogenea == null ? '—' : _n(resultado.c1Homogenea!, decimales: 6)}',
      )
      ..writeln(
        'C2 = ${resultado.c2Homogenea == null ? '—' : _n(resultado.c2Homogenea!, decimales: 6)}',
      )
      ..writeln('x(t) = ${resultado.solucion.expresionX}')
      ..writeln('y(t) = ${resultado.solucion.expresionY}')
      ..writeln("x'(t) = ${resultado.expresionXPrima}")
      ..writeln("y'(t) = ${resultado.expresionYPrima}")
      ..writeln()
      ..writeln('COLAPSO Y VENTANA')
      ..writeln(
        'Colapso Capa Web: '
        '${resultado.colapsoWeb.tiempo == null ? 'No colapsa' : '${_n(resultado.colapsoWeb.tiempo!)} min'}',
      )
      ..writeln(
        'Colapso Base de Datos: '
        '${resultado.colapsoBd.tiempo == null ? 'No colapsa' : '${_n(resultado.colapsoBd.tiempo!)} min'}',
      )
      ..writeln(
        'Ventana de Acción: '
        '${resultado.ventana.ventanaAccion == null ? 'Sin colapso' : '${_n(resultado.ventana.ventanaAccion!)} min'}',
      )
      ..writeln()
      ..writeln('LÍMITES t → ∞')
      ..writeln('lim x(t) = ${resultado.limiteX}')
      ..writeln('lim y(t) = ${resultado.limiteY}')
      ..writeln()
      ..writeln('COMPARACIÓN CON LA REFERENCIA')
      ..writeln(
        'Umbral: ${_n(_umbral, decimales: 6)}'
        '${resultado.notaComparacion == null ? '' : ' · ${resultado.notaComparacion}'}',
      );

    for (final fila in resultado.comparacion) {
      buffer
        ..writeln('${fila.variable}:')
        ..writeln('  Motor: ${fila.ecuacionMotor}')
        ..writeln('  Referencia: ${fila.ecuacionReferencia}')
        ..writeln(
          '  Error máximo: '
          '${fila.errorMaximo == null ? '—' : _n(fila.errorMaximo!, decimales: 6)}',
        )
        ..writeln('  Estado: ${fila.coincide ? 'coincide' : 'difiere'}');
    }

    return buffer.toString();
  }

  String _termino(double coeficiente, String variable) {
    final signo = coeficiente < 0 ? '-' : '+';
    return ' $signo ${_n(coeficiente.abs())}·$variable';
  }

  String _terminoInicial(double coeficiente, String variable) {
    final signo = coeficiente < 0 ? '-' : '';
    return '$signo${_n(coeficiente.abs())}·$variable';
  }

  String _n(double valor, {int decimales = 3}) {
    return formatearNumero(valor, decimales: decimales);
  }
}

class _Subtitulo extends StatelessWidget {
  final String texto;

  const _Subtitulo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColores.textoSecundario,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
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
            fontSize: 11,
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
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontSize: 11,
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
