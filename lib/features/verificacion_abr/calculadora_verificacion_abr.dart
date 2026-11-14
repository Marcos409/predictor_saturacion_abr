import 'dart:math' as math;

import '../../core/engine/detector_colapso.dart';
import '../../core/engine/evaluador_entrada_trafico.dart';
import '../../core/engine/evaluador_expresiones.dart';
import '../../core/engine/evaluador_solucion_analitica.dart';
import '../../core/engine/solucionador_analitico_general.dart';
import '../../core/engine/solver_runge_kutta.dart';
import '../../core/models/escenario_trafico.dart';
import '../../core/models/punto_simulacion.dart';
import '../../core/models/referencia_abr.dart';
import '../../core/models/sistema.dart';
import '../../core/models/solucion_analitica.dart';
import '../../core/models/solucion_general.dart';
import 'resultado_verificacion_abr.dart';

class CalculadoraVerificacionAbr {
  final EvaluadorExpresiones evaluador;

  CalculadoraVerificacionAbr({EvaluadorExpresiones? evaluador})
    : evaluador = evaluador ?? EvaluadorExpresiones();

  ResultadoVerificacionAbr calcular({
    required EscenarioTrafico escenario,
    required ConfiguracionSistema configuracion,
    required ReferenciaAbr? referencia,
    required double umbralComparacion,
  }) {
    if (umbralComparacion < 0) {
      throw const FormatException(
        'El umbral de comparación debe ser mayor o igual que cero.',
      );
    }

    final solucion = SolucionadorAnaliticoGeneral(
      configuracion: configuracion,
    ).resolver(escenario);
    if (!solucion.soportada) {
      throw FormatException(
        solucion.motivo ?? 'La solución analítica no está soportada.',
      );
    }

    final horizonte = escenario.tiempoMaxMin > 0
        ? escenario.tiempoMaxMin
        : configuracion.simulacion.tiempoFinal;
    final paso = configuracion.simulacion.paso;
    final puntos = _muestrearSolucion(solucion, horizonte, paso);
    const detector = DetectorColapso();

    final colapsoWeb = detector.detectar(
      tanque: 'capa_web',
      limite: configuracion.tanques.limiteA,
      puntos: puntos,
      valor: (punto) => punto.x,
    );
    final colapsoBd = detector.detectar(
      tanque: 'base_datos',
      limite: configuracion.tanques.limiteB,
      puntos: puntos,
      valor: (punto) => punto.y,
    );
    final ventana = detector.calcularVentanaAccion(
      colapsoCapaWeb: colapsoWeb,
      colapsoBaseDatos: colapsoBd,
      tiempoReaccion: configuracion.tiempoReaccion,
    );

    final comparacion = _comparar(
      escenario: escenario,
      configuracion: configuracion,
      solucion: solucion,
      referencia: referencia,
      umbral: umbralComparacion,
      horizonte: horizonte,
      paso: paso,
    );

    return ResultadoVerificacionAbr(
      escenario: escenario,
      configuracion: configuracion,
      solucion: solucion,
      edoFase1: _edoFase1(escenario),
      metodoFase1: _metodoFase1(escenario.id),
      expresionV1: solucion.expresionV1,
      expresionXPrima: _expresionDerivada(solucion.terminosX),
      expresionYPrima: _expresionDerivada(solucion.terminosY),
      expresionYc: _expresionYc(solucion.pasos),
      expresionYp: _expresionYp(escenario, solucion.pasos),
      c1Homogenea: solucion.pasos.c1Homogenea,
      c2Homogenea: solucion.pasos.c2Homogenea,
      colapsoWeb: colapsoWeb,
      colapsoBd: colapsoBd,
      ventana: ventana,
      limiteX: _limiteInfinito(solucion.terminosX),
      limiteY: _limiteInfinito(solucion.terminosY),
      comparacion: comparacion.filas,
      notaComparacion: comparacion.nota,
      horizonteMin: horizonte,
    );
  }

  List<PuntoSimulacion> _muestrearSolucion(
    SolucionGeneral solucion,
    double horizonte,
    double paso,
  ) {
    final puntos = <PuntoSimulacion>[];
    final incremento = paso > 0 ? paso : horizonte;
    var t = 0.0;
    while (t < horizonte - 1e-12) {
      puntos.add(
        PuntoSimulacion(t: t, x: solucion.evaluarX(t), y: solucion.evaluarY(t)),
      );
      t += incremento;
    }
    puntos.add(
      PuntoSimulacion(
        t: horizonte,
        x: solucion.evaluarX(horizonte),
        y: solucion.evaluarY(horizonte),
      ),
    );
    return puntos;
  }

  ({List<FilaComparacionAbr> filas, String? nota}) _comparar({
    required EscenarioTrafico escenario,
    required ConfiguracionSistema configuracion,
    required SolucionGeneral solucion,
    required ReferenciaAbr? referencia,
    required double umbral,
    required double horizonte,
    required double paso,
  }) {
    final caso = referencia?.buscarCasoPorId(escenario.id);
    final referenciaX = caso?.fase2.x;
    final referenciaY = caso?.fase2.y;

    if (caso == null || referenciaX == null || referenciaY == null) {
      final errores = _compararConRungeKutta(
        escenario: escenario,
        configuracion: configuracion,
        solucion: solucion,
        horizonte: horizonte,
        paso: paso,
        umbral: umbral,
      );
      final nota = referencia == null
          ? 'No se pudo leer referencia_abr.json; se compara la solución del motor con RK4.'
          : caso == null
          ? 'No hay caso de referencia para este escenario; se compara con RK4.'
          : 'Referencia pendiente para el caso "${caso.id}"; se compara con RK4.';
      return (filas: errores, nota: nota);
    }

    final evaluadorReferencia = EvaluadorSolucionAnalitica(
      solucion: SolucionAnalitica(
        version: configuracion.version,
        unidadTiempo: configuracion.unidadTiempo,
        variable: 't',
        expresionX: referenciaX,
        expresionY: referenciaY,
      ),
      evaluador: evaluador,
    );

    var errorX = 0.0;
    var errorY = 0.0;
    for (final t in _tiempos(horizonte, paso)) {
      errorX = math.max(
        errorX,
        (solucion.evaluarX(t) - evaluadorReferencia.evaluarX(t)).abs(),
      );
      errorY = math.max(
        errorY,
        (solucion.evaluarY(t) - evaluadorReferencia.evaluarY(t)).abs(),
      );
    }

    return (
      filas: [
        _filaComparacion(
          variable: 'x(t)',
          ecuacionMotor: solucion.expresionX,
          ecuacionReferencia: referenciaX,
          errorMaximo: errorX,
          umbral: umbral,
        ),
        _filaComparacion(
          variable: 'y(t)',
          ecuacionMotor: solucion.expresionY,
          ecuacionReferencia: referenciaY,
          errorMaximo: errorY,
          umbral: umbral,
        ),
      ],
      nota: null,
    );
  }

  List<FilaComparacionAbr> _compararConRungeKutta({
    required EscenarioTrafico escenario,
    required ConfiguracionSistema configuracion,
    required SolucionGeneral solucion,
    required double horizonte,
    required double paso,
    required double umbral,
  }) {
    final entrada = EvaluadorEntradaTrafico(
      escenario: escenario,
      evaluador: evaluador,
    );
    final numerica = SolucionadorRungeKutta(
      configuracion: configuracion,
    ).resolver(entrada: entrada.evaluar, paso: paso, tFinal: horizonte);

    var errorX = 0.0;
    var errorY = 0.0;
    for (final punto in numerica.puntos) {
      errorX = math.max(errorX, (solucion.evaluarX(punto.t) - punto.x).abs());
      errorY = math.max(errorY, (solucion.evaluarY(punto.t) - punto.y).abs());
    }

    return [
      _filaComparacion(
        variable: 'x(t)',
        ecuacionMotor: solucion.expresionX,
        ecuacionReferencia: 'Referencia pendiente',
        errorMaximo: errorX,
        umbral: umbral,
        referenciaPendiente: true,
      ),
      _filaComparacion(
        variable: 'y(t)',
        ecuacionMotor: solucion.expresionY,
        ecuacionReferencia: 'Referencia pendiente',
        errorMaximo: errorY,
        umbral: umbral,
        referenciaPendiente: true,
      ),
    ];
  }

  FilaComparacionAbr _filaComparacion({
    required String variable,
    required String ecuacionMotor,
    required String ecuacionReferencia,
    required double errorMaximo,
    required double umbral,
    bool referenciaPendiente = false,
  }) {
    return FilaComparacionAbr(
      variable: variable,
      ecuacionMotor: ecuacionMotor,
      ecuacionReferencia: ecuacionReferencia,
      errorMaximo: errorMaximo,
      estado: errorMaximo <= umbral
          ? EstadoComparacionAbr.coincide
          : EstadoComparacionAbr.difiere,
      referenciaPendiente: referenciaPendiente,
    );
  }

  List<double> _tiempos(double horizonte, double paso) {
    final tiempos = <double>[];
    final incremento = paso > 0 ? paso : horizonte;
    var t = 0.0;
    while (t < horizonte - 1e-12) {
      tiempos.add(t);
      t += incremento;
    }
    tiempos.add(horizonte);
    return tiempos;
  }

  String _edoFase1(EscenarioTrafico escenario) {
    final parametros = escenario.mapaParametros;
    switch (escenario.id) {
      case 'lineal':
        return 'dP/dt = ${_numero(_parametro(parametros, 'm'))}  ·  '
            'P(0) = ${_numero(_parametro(parametros, 'P0'))}';
      case 'constante':
        return 'dP/dt = 0  ·  '
            'P(0) = ${_numero(_parametro(parametros, 'P0'))}';
      case 'exponencial':
        return 'dP/dt − ${_numero(_parametro(parametros, 'r'))}·P = '
            '${_numero(_parametro(parametros, 'b'))}  ·  '
            'P(0) = ${_numero(_parametro(parametros, 'P0'))}';
      case 'ciclico':
        final periodo = _parametro(parametros, 'periodo_min');
        if (periodo.abs() < 1e-12) {
          throw const FormatException(
            'El escenario cíclico requiere un periodo distinto de cero.',
          );
        }
        final omega = 2 * math.pi / periodo;
        return "P'' + ω²·P = 0  ·  ω = ${_numero(omega)} rad/min  ·  "
            'P(0) = ${_numero(_parametro(parametros, 'P0'))}, '
            "P'(0) = ${_numero(_parametro(parametros, 'dP0'))}";
      default:
        return escenario.edo;
    }
  }

  String _metodoFase1(String id) {
    switch (id) {
      case 'lineal':
      case 'constante':
        return 'Integración directa';
      case 'exponencial':
        return 'Transformada de Laplace';
      case 'ciclico':
        return 'EDO homogénea de 2.º orden';
      default:
        return 'Método analítico';
    }
  }

  String _expresionDerivada(List<TerminoSolucion> terminos) {
    final derivadas = <TerminoSolucion>[];
    for (final termino in terminos) {
      derivadas.addAll(termino.derivar());
    }
    return formatearExpresion(derivadas, 't');
  }

  String _expresionYc(PasosSolucionAnalitica pasos) {
    final r1 = pasos.r1;
    final r2 = pasos.r2;
    if (r1 == null || r2 == null) return 'No disponible';
    return 'Yc(t) = C1·exp(${_numero(r1)}·t) + C2·exp(${_numero(r2)}·t)';
  }

  String _expresionYp(
    EscenarioTrafico escenario,
    PasosSolucionAnalitica pasos,
  ) {
    final coeficientes = pasos.coeficientesParticulares;
    switch (escenario.id) {
      case 'lineal':
      case 'constante':
        return formatearExpresion([
          TerminoSolucion(
            coeficiente: coeficientes['p0'] ?? 0,
            tipo: TipoTermino.constante,
          ),
          TerminoSolucion(
            coeficiente: coeficientes['p1'] ?? 0,
            tipo: TipoTermino.lineal,
          ),
          TerminoSolucion(
            coeficiente: coeficientes['p2'] ?? 0,
            tipo: TipoTermino.cuadratico,
          ),
        ], 't');
      case 'exponencial':
        final r = _parametro(escenario.mapaParametros, 'r');
        final resonante =
            (pasos.r1 != null && (r - pasos.r1!).abs() < 1e-9) ||
            (pasos.r2 != null && (r - pasos.r2!).abs() < 1e-9);
        return formatearExpresion([
          TerminoSolucion(
            coeficiente: coeficientes['p0'] ?? 0,
            tipo: TipoTermino.constante,
          ),
          TerminoSolucion(
            coeficiente: coeficientes['B'] ?? 0,
            tipo: resonante
                ? TipoTermino.exponencialLineal
                : TipoTermino.exponencial,
            parametro: r,
          ),
        ], 't');
      case 'ciclico':
        final periodo = _parametro(escenario.mapaParametros, 'periodo_min');
        if (periodo.abs() < 1e-12) {
          throw const FormatException(
            'El escenario cíclico requiere un periodo distinto de cero.',
          );
        }
        final omega = 2 * math.pi / periodo;
        return formatearExpresion([
          TerminoSolucion(
            coeficiente: coeficientes['A'] ?? 0,
            tipo: TipoTermino.coseno,
            parametro: omega,
          ),
          TerminoSolucion(
            coeficiente: coeficientes['B'] ?? 0,
            tipo: TipoTermino.seno,
            parametro: omega,
          ),
        ], 't');
      default:
        return 'No disponible';
    }
  }

  String _limiteInfinito(List<TerminoSolucion> terminos) {
    var finito = 0.0;
    var oscila = false;
    for (final termino in combinarTerminos(terminos)) {
      switch (termino.tipo) {
        case TipoTermino.constante:
          finito += termino.coeficiente;
        case TipoTermino.lineal:
        case TipoTermino.cuadratico:
          if (termino.coeficiente > 0) return '+∞';
          if (termino.coeficiente < 0) return '-∞';
        case TipoTermino.exponencial:
          if (termino.parametro > 1e-9) {
            return termino.coeficiente >= 0 ? '+∞' : '-∞';
          }
          if (termino.parametro.abs() <= 1e-9) {
            finito += termino.coeficiente;
          }
        case TipoTermino.exponencialLineal:
          if (termino.parametro > -1e-9) {
            return termino.coeficiente >= 0 ? '+∞' : '-∞';
          }
        case TipoTermino.seno:
        case TipoTermino.coseno:
          oscila = true;
      }
    }
    if (oscila) return 'Acotado (oscila)';
    return _numero(finito);
  }

  double _parametro(Map<String, double> parametros, String clave) {
    final valor = parametros[clave];
    if (valor == null) {
      throw FormatException('Falta el parámetro "$clave" del escenario.');
    }
    return valor;
  }

  String _numero(double valor) {
    if (valor.isNaN || valor.isInfinite) return '—';
    final texto = valor.toStringAsFixed(6);
    final sinCeros = texto
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return sinCeros.isEmpty || sinCeros == '-' ? '0' : sinCeros;
  }
}
