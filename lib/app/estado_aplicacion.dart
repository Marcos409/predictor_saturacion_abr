import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/engine/detector_colapso.dart';
import '../core/engine/evaluador_entrada_trafico.dart';
import '../core/engine/evaluador_expresiones.dart';
import '../core/engine/evaluador_solucion_analitica.dart';
import '../core/engine/solucionador_analitico_general.dart';
import '../core/engine/solver_runge_kutta.dart';
import '../core/engine/verificador_cruzado.dart';
import '../core/models/escenario_trafico.dart';
import '../core/models/punto_entrada.dart';
import '../core/models/punto_simulacion.dart';
import '../core/models/resultado_colapso.dart';
import '../core/models/resultado_simulacion.dart';
import '../core/models/resultado_ventana_accion.dart';
import '../core/models/resultado_verificacion.dart';
import '../core/models/sistema.dart';
import '../core/models/solucion_analitica.dart';
import '../core/models/solucion_general.dart';
import 'evento_simulacion.dart';
import 'formato.dart';
import 'semaforo.dart';

enum ModoAutoScaling { automatico, manual }

class EstadoAplicacion extends ChangeNotifier {
  ConfiguracionSistema _sistema;
  final List<EscenarioTrafico> _escenarios;
  SolucionAnalitica _solucionAnalitica;
  final EvaluadorExpresiones _evaluadorExpresiones;
  late EvaluadorSolucionAnalitica _evaluadorAnalitico;
  String _idEscenarioActivo;
  int _versionEscenarios;
  String _unidadTiempoEscenarios;
  String _variableEscenarios;

  Map<String, ResultadoSimulacion> _resultados = const {};
  Map<String, ResultadoColapso> _colapsosWeb = const {};
  Map<String, ResultadoColapso> _colapsosBaseDatos = const {};
  Map<String, ResultadoVentanaAccion> _ventanas = const {};
  Map<String, List<PuntoEntrada>> _curvasEntrada = const {};
  Map<String, _EscenarioCalculado> _cacheEscenarios = const {};
  ResultadoVerificacion? _verificacion;
  bool _verificacionPendiente = false;
  SolucionGeneral? _solucionGeneralActiva;
  bool _usaSolucionJsonParaVerificacion = false;
  String? _motivoSolucionNoDisponible;
  String? _error;

  double _tiempoVivo = 0;
  bool _reproduciendo = false;
  double _velocidad = 1;
  ModoAutoScaling _modoAutoScaling = ModoAutoScaling.manual;
  int _escaladosWeb = 0;
  int _escaladosBaseDatos = 0;
  double? _escaladoWebPendienteEn;
  double? _escaladoBaseDatosPendienteEn;
  bool _avisoWebEmitido = false;
  bool _avisoBaseDatosEmitido = false;
  bool _criticoEmitido = false;
  bool _continuarTrasColapso = false;
  double? _tiempoCaidaWeb;
  double? _tiempoCaidaBaseDatos;
  double? _ventanaAccionAlCaerWeb;
  final List<EventoSimulacion> _eventos = [];
  Timer? _temporizador;

  EstadoAplicacion({
    required ConfiguracionSistema sistema,
    required ConfiguracionEscenarios escenarios,
    required SolucionAnalitica solucionAnalitica,
    EvaluadorExpresiones? evaluadorExpresiones,
    String? idEscenarioActivo,
  }) : _sistema = sistema,
       _escenarios = List<EscenarioTrafico>.of(escenarios.escenarios),
       _solucionAnalitica = solucionAnalitica,
       _evaluadorExpresiones = evaluadorExpresiones ?? EvaluadorExpresiones(),
       _versionEscenarios = escenarios.version,
       _unidadTiempoEscenarios = escenarios.unidadTiempo,
       _variableEscenarios = escenarios.variable,
       _idEscenarioActivo =
           idEscenarioActivo ??
           (escenarios.escenarios.isEmpty
               ? ''
               : escenarios.escenarios.first.id) {
    if (_escenarios.isEmpty) {
      throw StateError('No hay escenarios de tráfico configurados');
    }
    _evaluadorAnalitico = EvaluadorSolucionAnalitica(
      solucion: _solucionAnalitica,
      evaluador: _evaluadorExpresiones,
    );
    _recalcular();
  }

  static Future<EstadoAplicacion> cargar() async {
    final escenariosJson = await rootBundle.loadString(
      'assets/config/escenarios.json',
    );
    final sistemaJson = await rootBundle.loadString(
      'assets/config/sistema.json',
    );
    final solucionesJson = await rootBundle.loadString(
      'assets/config/soluciones.json',
    );
    return desdeJson(
      escenariosJson: escenariosJson,
      sistemaJson: sistemaJson,
      solucionesJson: solucionesJson,
    );
  }

  static EstadoAplicacion desdeJson({
    required String escenariosJson,
    required String sistemaJson,
    required String solucionesJson,
  }) {
    final partes = _parsearJson(
      escenariosJson: escenariosJson,
      sistemaJson: sistemaJson,
      solucionesJson: solucionesJson,
    );
    return EstadoAplicacion(
      sistema: partes.sistema,
      escenarios: partes.escenarios,
      solucionAnalitica: partes.solucionAnalitica,
    );
  }

  static ({
    ConfiguracionSistema sistema,
    ConfiguracionEscenarios escenarios,
    SolucionAnalitica solucionAnalitica,
  })
  _parsearJson({
    required String escenariosJson,
    required String sistemaJson,
    required String solucionesJson,
  }) {
    final escenarios = ConfiguracionEscenarios.fromJson(
      jsonDecode(escenariosJson) as Map<String, dynamic>,
    );
    final sistema = ConfiguracionSistema.fromJson(
      jsonDecode(sistemaJson) as Map<String, dynamic>,
    );
    final solucionAnalitica = SolucionAnalitica.fromJson(
      jsonDecode(solucionesJson) as Map<String, dynamic>,
    );
    return (
      sistema: sistema,
      escenarios: escenarios,
      solucionAnalitica: solucionAnalitica,
    );
  }

  Future<void> restaurarCasoBase() async {
    final partes = _parsearJson(
      escenariosJson: await rootBundle.loadString(
        'assets/config/escenarios.json',
      ),
      sistemaJson: await rootBundle.loadString('assets/config/sistema.json'),
      solucionesJson: await rootBundle.loadString(
        'assets/config/soluciones.json',
      ),
    );
    reemplazarConfiguracion(
      sistema: partes.sistema,
      escenarios: partes.escenarios,
      solucionAnalitica: partes.solucionAnalitica,
    );
  }

  void reemplazarConfiguracion({
    required ConfiguracionSistema sistema,
    required ConfiguracionEscenarios escenarios,
    required SolucionAnalitica solucionAnalitica,
  }) {
    if (escenarios.escenarios.isEmpty) {
      throw const FormatException(
        'La configuración debe incluir al menos un escenario.',
      );
    }

    final unidades = {
      sistema.unidadTiempo,
      escenarios.unidadTiempo,
      solucionAnalitica.unidadTiempo,
    };
    if (unidades.length != 1 || !unidades.contains('min')) {
      throw const FormatException(
        'La unidad de tiempo debe ser "min" en las tres secciones.',
      );
    }

    final evaluadorAnalitico = EvaluadorSolucionAnalitica(
      solucion: solucionAnalitica,
      evaluador: _evaluadorExpresiones,
    );
    try {
      evaluadorAnalitico.evaluarX(0);
      evaluadorAnalitico.evaluarY(0);
    } catch (error) {
      throw FormatException(
        'La solución analítica no se puede evaluar: $error',
      );
    }

    final prueba = EstadoAplicacion(
      sistema: sistema,
      escenarios: escenarios,
      solucionAnalitica: solucionAnalitica,
      evaluadorExpresiones: _evaluadorExpresiones,
    );
    final errorPrueba = prueba.error;
    prueba.dispose();
    if (errorPrueba != null) {
      throw FormatException(
        'La configuración no se pudo calcular: $errorPrueba',
      );
    }

    _sistema = sistema;
    _escenarios
      ..clear()
      ..addAll(escenarios.escenarios);
    _solucionAnalitica = solucionAnalitica;
    _evaluadorAnalitico = evaluadorAnalitico;
    _versionEscenarios = escenarios.version;
    _unidadTiempoEscenarios = escenarios.unidadTiempo;
    _variableEscenarios = escenarios.variable;
    if (!_escenarios.any((escenario) => escenario.id == _idEscenarioActivo)) {
      _idEscenarioActivo = _escenarios.first.id;
    }
    _recalcular();
  }

  ConfiguracionSistema get sistema => _sistema;
  List<EscenarioTrafico> get escenarios => List.unmodifiable(_escenarios);
  ConfiguracionEscenarios get configuracionEscenarios =>
      ConfiguracionEscenarios(
        version: _versionEscenarios,
        unidadTiempo: _unidadTiempoEscenarios,
        variable: _variableEscenarios,
        escenarios: List.unmodifiable(_escenarios),
      );
  String get idEscenarioActivo => _idEscenarioActivo;
  SolucionAnalitica get solucionAnalitica => _solucionAnalitica;
  ResultadoVerificacion? get verificacion {
    if (_verificacionPendiente) _actualizarVerificacion();
    return _verificacion;
  }

  SolucionGeneral? get solucionGeneralActiva {
    if (_verificacionPendiente) _actualizarVerificacion();
    return _solucionGeneralActiva;
  }

  SolucionAnalitica? get solucionAnaliticaActiva {
    if (_verificacionPendiente) _actualizarVerificacion();
    if (_usaSolucionJsonParaVerificacion) return _solucionAnalitica;
    return _solucionGeneralActiva?.aSolucionAnalitica(
      version: _sistema.version,
      unidadTiempo: _sistema.unidadTiempo,
    );
  }

  bool get usaSolucionJsonParaVerificacion {
    if (_verificacionPendiente) _actualizarVerificacion();
    return _usaSolucionJsonParaVerificacion;
  }

  String? get motivoSolucionNoDisponible {
    if (_verificacionPendiente) _actualizarVerificacion();
    return _motivoSolucionNoDisponible;
  }

  String? get error => _error;

  ResultadoSimulacion? get resultado => _resultados[_idEscenarioActivo];
  ResultadoColapso? get colapsoCapaWeb => _colapsosWeb[_idEscenarioActivo];
  ResultadoColapso? get colapsoBaseDatos =>
      _colapsosBaseDatos[_idEscenarioActivo];
  ResultadoVentanaAccion? get ventanaAccion => _ventanas[_idEscenarioActivo];

  ResultadoSimulacion? resultadoEscenario(String id) => _resultados[id];
  ResultadoColapso? colapsoWebEscenario(String id) => _colapsosWeb[id];
  ResultadoColapso? colapsoBaseDatosEscenario(String id) =>
      _colapsosBaseDatos[id];
  ResultadoVentanaAccion? ventanaEscenario(String id) => _ventanas[id];

  NivelSemaforo get nivelSemaforo => evaluarNivelSemaforo(
    ventana: ventanaAccion,
    configuracion: _sistema.semaforo,
  );

  NivelSemaforo nivelSemaforoEscenario(String id) => evaluarNivelSemaforo(
    ventana: _ventanas[id],
    configuracion: _sistema.semaforo,
  );

  EscenarioTrafico get escenarioActivo {
    for (final escenario in _escenarios) {
      if (escenario.id == _idEscenarioActivo) return escenario;
    }
    return _escenarios.first;
  }

  List<PuntoEntrada> get curvaEntradaActiva =>
      _curvasEntrada[_idEscenarioActivo] ?? const [];

  List<PuntoEntrada> curvaEscenario(String id) =>
      _curvasEntrada[id] ?? const [];

  double get capacidadWebEfectiva =>
      _sistema.capacidades.capaWeb +
      _escaladosWeb * _sistema.autoScaling.incrementoCapacidad;

  double get capacidadBaseDatosEfectiva =>
      _sistema.capacidades.baseDatos +
      _escaladosBaseDatos * _sistema.autoScaling.incrementoCapacidad;

  bool get maximoEscaladosWeb =>
      _escaladosWeb >= _sistema.autoScaling.maximoEscalados;

  bool get maximoEscaladosBaseDatos =>
      _escaladosBaseDatos >= _sistema.autoScaling.maximoEscalados;

  int get escaladosWeb => _escaladosWeb;
  int get escaladosBaseDatos => _escaladosBaseDatos;

  double get tiempoVivo => _tiempoVivo;
  bool get reproduciendo => _reproduciendo;
  double get velocidad => _velocidad;
  ModoAutoScaling get modoAutoScaling => _modoAutoScaling;
  bool get continuarTrasColapso => _continuarTrasColapso;
  bool get capaWebCaida => _tiempoCaidaWeb != null;
  bool get baseDatosCaida => _tiempoCaidaBaseDatos != null;
  double? get tiempoCaidaWeb => _tiempoCaidaWeb;
  double? get tiempoCaidaBaseDatos => _tiempoCaidaBaseDatos;
  double? get ventanaAccionAlCaerWeb => _ventanaAccionAlCaerWeb;
  List<EventoSimulacion> get eventos => List.unmodifiable(_eventos);

  double get entradaInicial => EvaluadorEntradaTrafico(
    escenario: escenarioActivo,
    evaluador: _evaluadorExpresiones,
  ).evaluar(0);

  double get entradaEfectivaFactor => _sistema.tanques.c1;

  PuntoSimulacion? puntoEn(double tiempo) => _puntoEn(tiempo);

  double entradaEn(double tiempo) => EvaluadorEntradaTrafico(
    escenario: escenarioActivo,
    evaluador: _evaluadorExpresiones,
  ).evaluar(tiempo);

  double get horizonteActivo {
    final tiempo = escenarioActivo.tiempoMaxMin;
    return tiempo > 0 ? tiempo : _sistema.simulacion.tiempoFinal;
  }

  bool get entradaNegativaEnHorizonte {
    final factor = _sistema.tanques.c1;
    for (final punto in curvaEntradaActiva) {
      if (factor * punto.valor < 0) return true;
    }
    return false;
  }

  double get derivadaXInicial {
    final coeficientes = _sistema.coeficientes;
    final condiciones = _sistema.condicionesIniciales;
    return _sistema.tanques.c1 * entradaInicial +
        coeficientes.a11 * condiciones.x0 +
        coeficientes.a12 * condiciones.y0;
  }

  double get derivadaYInicial {
    final coeficientes = _sistema.coeficientes;
    final condiciones = _sistema.condicionesIniciales;
    return coeficientes.a21 * condiciones.x0 +
        coeficientes.a22 * condiciones.y0;
  }

  PuntoSimulacion? get puntoVivo => _puntoEn(_tiempoVivo);

  bool get avisoWeb {
    final punto = puntoVivo;
    if (punto == null) return false;
    return punto.x >= _sistema.umbralAlerta * capacidadWebEfectiva;
  }

  bool get avisoBaseDatos {
    final punto = puntoVivo;
    if (punto == null) return false;
    return punto.y >= _sistema.umbralAlerta * capacidadBaseDatosEfectiva;
  }

  bool get alertaCritica {
    final ventana = ventanaAccion?.ventanaAccion;
    return ventana != null && ventana < 0;
  }

  void seleccionarEscenario(String id) {
    if (id == _idEscenarioActivo) return;
    if (!_escenarios.any((escenario) => escenario.id == id)) return;
    _idEscenarioActivo = id;
    _recalcular();
  }

  void actualizarParametroEscenario(String clave, double valor) {
    final indice = _escenarios.indexWhere(
      (escenario) => escenario.id == _idEscenarioActivo,
    );
    if (indice < 0) return;

    final escenario = _escenarios[indice];
    final parametros = escenario.parametros.map((parametro) {
      if (parametro.clave != clave) return parametro;
      return parametro.copyWith(valor: valor);
    }).toList();

    _escenarios[indice] = escenario.copyWith(parametros: parametros);
    _recalcular();
  }

  void actualizarCoeficienteDirecto(String clave, double valor) {
    final coeficientes = _sistema.tanques.coeficientesDirectos;
    final actualizados = switch (clave) {
      'a11' => coeficientes.copyWith(a11: valor),
      'a12' => coeficientes.copyWith(a12: valor),
      'a21' => coeficientes.copyWith(a21: valor),
      'a22' => coeficientes.copyWith(a22: valor),
      _ => null,
    };
    if (actualizados == null) return;

    _aplicarTanques(
      _sistema.tanques.copyWith(coeficientesDirectos: actualizados),
    );
  }

  void cambiarModoCoeficientes(String modo) {
    if (modo != 'derivado' && modo != 'directo') return;
    final tanques = _sistema.tanques;
    if (modo == tanques.modoCoeficientes) return;

    if (modo == 'directo') {
      _aplicarTanques(
        tanques.copyWith(
          modoCoeficientes: modo,
          coeficientesDirectos: tanques.derivarCoeficientes(),
        ),
      );
      return;
    }
    _aplicarTanques(tanques.copyWith(modoCoeficientes: modo));
  }

  void actualizarCaudal(String clave, double valor) {
    final caudales = _sistema.tanques.caudales;
    final actualizados = switch (clave) {
      'A_a_B' => caudales.copyWith(aAB: valor),
      'A_salida' => caudales.copyWith(aSalida: valor),
      'B_a_A' => caudales.copyWith(bAA: valor),
      'B_salida' => caudales.copyWith(bSalida: valor),
      _ => null,
    };
    if (actualizados == null) return;

    _aplicarTanques(_sistema.tanques.copyWith(caudales: actualizados));
  }

  void actualizarVolumen(String clave, double valor) {
    final tanques = _sistema.tanques;
    final actualizados = switch (clave) {
      'volumen_A' => tanques.copyWith(volumenA: valor),
      'volumen_B' => tanques.copyWith(volumenB: valor),
      _ => null,
    };
    if (actualizados == null) return;

    _aplicarTanques(actualizados);
  }

  void actualizarLimite(String clave, double valor) {
    final tanques = _sistema.tanques;
    final actualizados = switch (clave) {
      'limite_A' => tanques.copyWith(limiteA: valor),
      'limite_B' => tanques.copyWith(limiteB: valor),
      _ => null,
    };
    if (actualizados == null) return;

    _aplicarTanques(actualizados);
  }

  void actualizarC1(double valor) {
    _aplicarTanques(_sistema.tanques.copyWith(c1: valor));
  }

  void actualizarTiempoMaxEscenario(double valor) {
    if (valor <= 0) {
      _error = 'El tiempo máximo debe ser mayor que cero.';
      notifyListeners();
      return;
    }
    final indice = _escenarios.indexWhere(
      (escenario) => escenario.id == _idEscenarioActivo,
    );
    if (indice < 0) return;
    _escenarios[indice] = _escenarios[indice].copyWith(tiempoMaxMin: valor);
    _recalcular();
  }

  void _aplicarTanques(TanquesSistema tanques) {
    final error = tanques.validar();
    if (error != null) {
      _error = error;
      notifyListeners();
      return;
    }
    _sistema = _sistema.copyWith(tanques: tanques);
    _recalcular();
  }

  void actualizarCondicionInicial(String clave, double valor) {
    final condiciones = _sistema.condicionesIniciales;
    final actualizadas = switch (clave) {
      'x0' => condiciones.copyWith(x0: valor),
      'y0' => condiciones.copyWith(y0: valor),
      _ => null,
    };
    if (actualizadas == null) return;

    _sistema = _sistema.copyWith(condicionesIniciales: actualizadas);
    _recalcular();
  }

  void actualizarTiempoReaccion(double valor) {
    _aplicarTanques(_sistema.tanques.copyWith(tiempoReaccionMin: valor));
  }

  void actualizarUmbralAlerta(double valor) {
    if (valor <= 0 || valor > 1) {
      _error = 'El umbral de alerta debe estar entre 0 y 1.';
      notifyListeners();
      return;
    }
    _sistema = _sistema.copyWith(umbralAlerta: valor);
    _recalcular();
  }

  void actualizarUmbralVerificacion(double valor) {
    if (valor < 0) {
      _error = 'El umbral de verificación no puede ser negativo.';
      notifyListeners();
      return;
    }
    _sistema = _sistema.copyWith(
      verificacion: _sistema.verificacion.copyWith(umbralError: valor),
    );
    _verificacion = null;
    _verificacionPendiente = true;
    notifyListeners();
  }

  void reproducir() {
    if (_reproduciendo) return;
    if (capaWebCaida && !_continuarTrasColapso) return;
    if (_tiempoVivo >= horizonteActivo - 1e-12) {
      _reiniciarEstadoVivo();
    }
    _reproduciendo = true;
    _evaluarPendientesEscalado();
    _evaluarAlertasVivo();
    if (_reproduciendo) _iniciarTemporizador();
    notifyListeners();
  }

  void cambiarContinuarTrasColapso(bool valor) {
    if (valor == _continuarTrasColapso) return;
    _continuarTrasColapso = valor;
    _registrar(
      _tiempoVivo,
      TipoEventoSimulacion.sistema,
      valor
          ? 'Modo teórico activado: la simulación continuará tras el colapso.'
          : 'Modo teórico desactivado.',
    );
    if (!valor && capaWebCaida) {
      _reproduciendo = false;
      _detenerTemporizador();
    }
    notifyListeners();
  }

  void pausar() {
    if (!_reproduciendo) return;
    _reproduciendo = false;
    _detenerTemporizador();
    notifyListeners();
  }

  void reiniciar() {
    _detenerTemporizador();
    _reproduciendo = false;
    _reiniciarEstadoVivo();
    notifyListeners();
  }

  void cambiarVelocidad(double velocidad) {
    if (velocidad <= 0 || velocidad == _velocidad) return;
    _velocidad = velocidad;
    notifyListeners();
  }

  void cambiarModoAutoScaling(ModoAutoScaling modo) {
    if (modo == _modoAutoScaling) return;
    _modoAutoScaling = modo;
    _registrar(
      _tiempoVivo,
      TipoEventoSimulacion.sistema,
      modo == ModoAutoScaling.automatico
          ? 'Auto-Scaling automático activado.'
          : 'Auto-Scaling manual activado.',
    );
    if (modo == ModoAutoScaling.automatico) {
      if (avisoWeb) _programarEscalado('capa_web', _tiempoVivo);
      if (avisoBaseDatos) _programarEscalado('base_datos', _tiempoVivo);
    }
    notifyListeners();
  }

  void escalar(String tanque) {
    final esWeb = tanque == 'capa_web';
    final esBaseDatos = tanque == 'base_datos';
    if (!esWeb && !esBaseDatos) return;
    _aplicarEscalado(esWeb ? 'capa_web' : 'base_datos', automatico: false);
    notifyListeners();
  }

  void _recalcular() {
    _detenerTemporizador();
    _reproduciendo = false;
    _reiniciarEstadoVivo();
    notifyListeners();
  }

  void _reiniciarEstadoVivo() {
    _tiempoVivo = 0;
    _escaladosWeb = 0;
    _escaladosBaseDatos = 0;
    _tiempoCaidaWeb = null;
    _tiempoCaidaBaseDatos = null;
    _ventanaAccionAlCaerWeb = null;
    _eventos.clear();
    _reiniciarAlertas();
    _calcularResultados();
  }

  void _reiniciarAlertas() {
    _avisoWebEmitido = false;
    _avisoBaseDatosEmitido = false;
    _criticoEmitido = false;
    _escaladoWebPendienteEn = null;
    _escaladoBaseDatosPendienteEn = null;
  }

  void _calcularResultados() {
    try {
      const detector = DetectorColapso();
      final resultados = <String, ResultadoSimulacion>{};
      final colapsosWeb = <String, ResultadoColapso>{};
      final colapsosBaseDatos = <String, ResultadoColapso>{};
      final ventanas = <String, ResultadoVentanaAccion>{};
      final curvas = <String, List<PuntoEntrada>>{};
      final cachePrevio = _cacheEscenarios;
      final cacheNuevo = <String, _EscenarioCalculado>{};
      final claveSistema = _claveSistema();

      for (final escenario in _escenarios) {
        final clave = _claveEscenario(escenario, claveSistema);
        final calculado =
            cachePrevio[clave] ?? _calcularEscenario(escenario, detector);

        resultados[escenario.id] = calculado.resultado;
        colapsosWeb[escenario.id] = calculado.colapsoWeb;
        colapsosBaseDatos[escenario.id] = calculado.colapsoBaseDatos;
        ventanas[escenario.id] = calculado.ventana;
        curvas[escenario.id] = calculado.curva;
        cacheNuevo[clave] = calculado;
      }

      _resultados = resultados;
      _colapsosWeb = colapsosWeb;
      _colapsosBaseDatos = colapsosBaseDatos;
      _ventanas = ventanas;
      _curvasEntrada = curvas;
      _cacheEscenarios = cacheNuevo;
      _verificacion = null;
      _verificacionPendiente = true;
      _solucionGeneralActiva = null;
      _usaSolucionJsonParaVerificacion = false;
      _motivoSolucionNoDisponible = null;
      _error = null;
    } catch (excepcion) {
      _resultados = const {};
      _colapsosWeb = const {};
      _colapsosBaseDatos = const {};
      _ventanas = const {};
      _curvasEntrada = const {};
      _cacheEscenarios = const {};
      _verificacion = null;
      _verificacionPendiente = false;
      _solucionGeneralActiva = null;
      _usaSolucionJsonParaVerificacion = false;
      _motivoSolucionNoDisponible = null;
      _error = excepcion.toString();
    }
  }

  _EscenarioCalculado _calcularEscenario(
    EscenarioTrafico escenario,
    DetectorColapso detector,
  ) {
    final entrada = EvaluadorEntradaTrafico(
      escenario: escenario,
      evaluador: _evaluadorExpresiones,
    );
    final tiempoFinal = escenario.tiempoMaxMin > 0
        ? escenario.tiempoMaxMin
        : _sistema.simulacion.tiempoFinal;
    final resultado = SolucionadorRungeKutta(configuracion: _sistema).resolver(
      entrada: entrada.evaluar,
      paso: _sistema.simulacion.paso,
      tFinal: tiempoFinal,
    );
    final colapsoWeb = detector.detectar(
      tanque: 'capa_web',
      limite: capacidadWebEfectiva,
      puntos: resultado.puntos,
      valor: (punto) => punto.x,
    );
    final colapsoBaseDatos = detector.detectar(
      tanque: 'base_datos',
      limite: capacidadBaseDatosEfectiva,
      puntos: resultado.puntos,
      valor: (punto) => punto.y,
    );
    return _EscenarioCalculado(
      resultado: resultado,
      colapsoWeb: colapsoWeb,
      colapsoBaseDatos: colapsoBaseDatos,
      ventana: detector.calcularVentanaAccion(
        colapsoCapaWeb: colapsoWeb,
        colapsoBaseDatos: colapsoBaseDatos,
        tiempoReaccion: _sistema.tiempoReaccion,
      ),
      curva: _muestrearEntrada(escenario, tiempoFinal),
    );
  }

  String _claveSistema() {
    final tanques = _sistema.tanques;
    final caudales = tanques.caudales;
    final coeficientes = _sistema.coeficientes;
    final iniciales = _sistema.condicionesIniciales;
    final simulacion = _sistema.simulacion;
    return [
      _unidadTiempoEscenarios,
      _variableEscenarios,
      tanques.modoCoeficientes,
      '${tanques.c1}',
      '${tanques.volumenA}',
      '${tanques.volumenB}',
      '${tanques.limiteA}',
      '${tanques.limiteB}',
      '${tanques.tiempoReaccionMin}',
      '${caudales.aAB}',
      '${caudales.aSalida}',
      '${caudales.bAA}',
      '${caudales.bSalida}',
      '${coeficientes.a11}',
      '${coeficientes.a12}',
      '${coeficientes.a21}',
      '${coeficientes.a22}',
      '${iniciales.x0}',
      '${iniciales.y0}',
      '${simulacion.paso}',
      '${simulacion.tiempoFinal}',
      '$_escaladosWeb',
      '$_escaladosBaseDatos',
    ].join('|');
  }

  String _claveEscenario(EscenarioTrafico escenario, String claveSistema) {
    final parametros = escenario.mapaParametros.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      claveSistema,
      escenario.id,
      escenario.expresionV1,
      '${escenario.tiempoMaxMin}',
      for (final parametro in parametros) '${parametro.key}=${parametro.value}',
    ].join('|');
  }

  void _actualizarVerificacion() {
    _verificacionPendiente = false;
    final resultado = _resultados[_idEscenarioActivo];
    if (resultado == null) {
      _verificacion = null;
      _solucionGeneralActiva = null;
      _usaSolucionJsonParaVerificacion = false;
      _motivoSolucionNoDisponible = null;
      return;
    }

    final umbral = _sistema.verificacion.umbralError;
    final escenario = escenarioActivo;
    final SolucionGeneral general;
    try {
      general = SolucionadorAnaliticoGeneral(
        configuracion: _sistema,
      ).resolver(escenario);
    } catch (error) {
      _marcarNoDisponible(umbral, error.toString());
      return;
    }
    if (!general.soportada) {
      _marcarNoDisponible(
        umbral,
        general.motivo ?? 'La solución analítica no está soportada.',
      );
      return;
    }

    _solucionGeneralActiva = general;
    _motivoSolucionNoDisponible = null;
    final usaJson = _solucionAnalitica.aplicaA(
      escenario: escenario,
      configuracion: _sistema,
    );
    _usaSolucionJsonParaVerificacion = usaJson;
    final EvaluadorAnalitico analitica = usaJson
        ? _evaluadorAnalitico
        : EvaluadorSolucionGeneral(solucion: general);

    try {
      _verificacion = const VerificadorCruzado().verificar(
        puntosNumericos: resultado.puntos,
        analitica: analitica,
        umbral: umbral,
      );
    } catch (error) {
      _marcarNoDisponible(
        umbral,
        'No se pudo evaluar la solución analítica: $error',
      );
    }
  }

  void _marcarNoDisponible(double umbral, String motivo) {
    _verificacion = ResultadoVerificacion.noDisponible(
      umbral: umbral,
      motivo: motivo,
    );
    _solucionGeneralActiva = null;
    _usaSolucionJsonParaVerificacion = false;
    _motivoSolucionNoDisponible = motivo;
  }

  void _iniciarTemporizador() {
    _detenerTemporizador();
    _temporizador = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_reproduciendo) return;
      final avance = _sistema.simulacion.paso * _velocidad;
      _tiempoVivo = math.min(horizonteActivo, _tiempoVivo + avance);
      _evaluarPendientesEscalado();
      _evaluarAlertasVivo();
      if (!_reproduciendo) {
        notifyListeners();
        return;
      }
      if (_tiempoVivo >= horizonteActivo - 1e-12) {
        _reproduciendo = false;
        _detenerTemporizador();
      }
      notifyListeners();
    });
  }

  void _detenerTemporizador() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  void _evaluarAlertasVivo() {
    _evaluarColapsosVivo();

    final punto = _puntoEn(_tiempoVivo);
    if (punto == null) return;

    if (avisoWeb && !_avisoWebEmitido) {
      _avisoWebEmitido = true;
      _registrar(
        _tiempoVivo,
        TipoEventoSimulacion.aviso,
        'Aviso temprano: la Capa Web alcanzó '
        '${formatearNumero(_sistema.umbralAlerta * 100, decimales: 0)} % '
        'de su capacidad.',
      );
      _programarEscalado('capa_web', _tiempoVivo);
    }

    if (avisoBaseDatos && !_avisoBaseDatosEmitido) {
      _avisoBaseDatosEmitido = true;
      _registrar(
        _tiempoVivo,
        TipoEventoSimulacion.aviso,
        'Aviso temprano: la Base de Datos alcanzó '
        '${formatearNumero(_sistema.umbralAlerta * 100, decimales: 0)} % '
        'de su capacidad.',
      );
      _programarEscalado('base_datos', _tiempoVivo);
    }

    final ventana = ventanaAccion?.ventanaAccion;
    if (ventana != null && ventana < 0 && !_criticoEmitido) {
      _criticoEmitido = true;
      _registrar(
        _tiempoVivo,
        TipoEventoSimulacion.critico,
        'Alerta crítica: la Ventana de Acción es '
        '${formatearNumero(ventana)} min.',
      );
    }
  }

  void _evaluarColapsosVivo() {
    final tiempoWeb = colapsoCapaWeb?.tiempo;
    final tiempoBaseDatos = colapsoBaseDatos?.tiempo;
    final webPendiente = tiempoWeb != null && _tiempoCaidaWeb == null;
    final baseDatosPendiente =
        tiempoBaseDatos != null && _tiempoCaidaBaseDatos == null;
    final baseDatosPrimero =
        baseDatosPendiente && webPendiente && tiempoBaseDatos < tiempoWeb;

    if (baseDatosPrimero && _tiempoVivo >= tiempoBaseDatos - 1e-12) {
      _registrarCaidaBaseDatos(tiempoBaseDatos);
    }

    if (webPendiente && _tiempoVivo >= tiempoWeb - 1e-12) {
      _tiempoVivo = tiempoWeb;
      _tiempoCaidaWeb = tiempoWeb;
      _ventanaAccionAlCaerWeb = ventanaAccion?.ventanaAccion;
      _registrar(
        tiempoWeb,
        TipoEventoSimulacion.critico,
        'Capa Web caída en el minuto ${formatearNumero(tiempoWeb)}.',
      );
      if (!_continuarTrasColapso) {
        _reproduciendo = false;
        _detenerTemporizador();
      }
    }

    if (baseDatosPendiente &&
        _tiempoCaidaBaseDatos == null &&
        _tiempoVivo >= tiempoBaseDatos - 1e-12) {
      _registrarCaidaBaseDatos(tiempoBaseDatos);
    }
  }

  void _registrarCaidaBaseDatos(double tiempo) {
    _tiempoCaidaBaseDatos = tiempo;
    _registrar(
      tiempo,
      TipoEventoSimulacion.critico,
      'Base de Datos caída en el minuto ${formatearNumero(tiempo)}.',
    );
  }

  void _programarEscalado(String tanque, double tiempo) {
    if (_modoAutoScaling != ModoAutoScaling.automatico) return;
    final configuracion = _sistema.autoScaling;
    if (tanque == 'capa_web') {
      if (maximoEscaladosWeb || _escaladoWebPendienteEn != null) return;
      _escaladoWebPendienteEn = tiempo + configuracion.retraso;
    } else {
      if (maximoEscaladosBaseDatos || _escaladoBaseDatosPendienteEn != null) {
        return;
      }
      _escaladoBaseDatosPendienteEn = tiempo + configuracion.retraso;
    }
    _registrar(
      tiempo,
      TipoEventoSimulacion.sistema,
      'Auto-Scaling programado en '
      '${formatearNumero(configuracion.retraso)} min.',
    );
  }

  void _evaluarPendientesEscalado() {
    final pendienteWeb = _escaladoWebPendienteEn;
    if (pendienteWeb != null && _tiempoVivo >= pendienteWeb) {
      _escaladoWebPendienteEn = null;
      _aplicarEscalado('capa_web', automatico: true);
    }
    final pendienteBaseDatos = _escaladoBaseDatosPendienteEn;
    if (pendienteBaseDatos != null && _tiempoVivo >= pendienteBaseDatos) {
      _escaladoBaseDatosPendienteEn = null;
      _aplicarEscalado('base_datos', automatico: true);
    }
  }

  void _aplicarEscalado(String tanque, {required bool automatico}) {
    final esWeb = tanque == 'capa_web';
    if (esWeb && maximoEscaladosWeb) return;
    if (!esWeb && maximoEscaladosBaseDatos) return;

    final incremento = _sistema.autoScaling.incrementoCapacidad;
    if (esWeb) {
      _escaladosWeb += 1;
      _escaladoWebPendienteEn = null;
      _avisoWebEmitido = false;
      _registrar(
        _tiempoVivo,
        TipoEventoSimulacion.escalado,
        '${automatico ? 'Auto-Scaling' : 'Escalado manual'}: Capa Web '
        '+${formatearNumero(incremento)} de capacidad '
        '(total ${formatearNumero(capacidadWebEfectiva)}).',
      );
    } else {
      _escaladosBaseDatos += 1;
      _escaladoBaseDatosPendienteEn = null;
      _avisoBaseDatosEmitido = false;
      _registrar(
        _tiempoVivo,
        TipoEventoSimulacion.escalado,
        '${automatico ? 'Auto-Scaling' : 'Escalado manual'}: Base de Datos '
        '+${formatearNumero(incremento)} de capacidad '
        '(total ${formatearNumero(capacidadBaseDatosEfectiva)}).',
      );
    }
    _calcularResultados();
  }

  void _registrar(double minuto, TipoEventoSimulacion tipo, String mensaje) {
    _eventos.add(
      EventoSimulacion(minuto: minuto, tipo: tipo, mensaje: mensaje),
    );
  }

  PuntoSimulacion? _puntoEn(double tiempo) {
    final resultado = _resultados[_idEscenarioActivo];
    if (resultado == null || resultado.puntos.isEmpty) return null;
    final puntos = resultado.puntos;
    if (tiempo <= puntos.first.t) return puntos.first;
    if (tiempo >= puntos.last.t) return puntos.last;

    final indice = (tiempo / _sistema.simulacion.paso).floor().clamp(
      0,
      puntos.length - 2,
    );
    final anterior = puntos[indice];
    final siguiente = puntos[indice + 1];
    final diferencia = siguiente.t - anterior.t;
    if (diferencia.abs() < 1e-12) return siguiente;
    final fraccion = (tiempo - anterior.t) / diferencia;
    return PuntoSimulacion(
      t: tiempo,
      x: anterior.x + (siguiente.x - anterior.x) * fraccion,
      y: anterior.y + (siguiente.y - anterior.y) * fraccion,
    );
  }

  List<PuntoEntrada> _muestrearEntrada(
    EscenarioTrafico escenario,
    double tiempoFinal,
  ) {
    final evaluador = EvaluadorEntradaTrafico(
      escenario: escenario,
      evaluador: _evaluadorExpresiones,
    );
    final paso = _sistema.simulacion.paso;
    final puntos = <PuntoEntrada>[];

    var t = 0.0;
    while (t < tiempoFinal - 1e-12) {
      puntos.add(PuntoEntrada(t: t, valor: evaluador.evaluar(t)));
      t += paso;
    }
    puntos.add(
      PuntoEntrada(t: tiempoFinal, valor: evaluador.evaluar(tiempoFinal)),
    );
    return puntos;
  }

  @override
  void dispose() {
    _detenerTemporizador();
    super.dispose();
  }
}

class _EscenarioCalculado {
  const _EscenarioCalculado({
    required this.resultado,
    required this.colapsoWeb,
    required this.colapsoBaseDatos,
    required this.ventana,
    required this.curva,
  });

  final ResultadoSimulacion resultado;
  final ResultadoColapso colapsoWeb;
  final ResultadoColapso colapsoBaseDatos;
  final ResultadoVentanaAccion ventana;
  final List<PuntoEntrada> curva;
}
