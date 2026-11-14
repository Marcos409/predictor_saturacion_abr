import 'dart:math' as math;

import '../models/escenario_trafico.dart';
import '../models/sistema.dart';
import '../models/solucion_general.dart';

class SolucionadorAnaliticoGeneral {
  final ConfiguracionSistema configuracion;

  const SolucionadorAnaliticoGeneral({required this.configuracion});

  SolucionGeneral resolver(EscenarioTrafico escenario) {
    final coeficientes = configuracion.coeficientes;
    final condiciones = configuracion.condicionesIniciales;
    final factor = configuracion.tanques.c1;

    final terminosV1 = _terminosV1(escenario);

    final a = -(coeficientes.a11 + coeficientes.a22);
    final b =
        coeficientes.a11 * coeficientes.a22 -
        coeficientes.a12 * coeficientes.a21;
    final c = coeficientes.a21;

    final discriminante = a * a - 4 * b;
    final r1 = discriminante > 1e-12
        ? (-a + math.sqrt(discriminante)) / 2
        : null;
    final r2 = discriminante > 1e-12
        ? (-a - math.sqrt(discriminante)) / 2
        : null;

    final edo =
        "y'' + ${_num(a)}·y' + ${_num(b)}·y = ${_num(c)}·u(t), "
        "con u(t) = ${_num(factor)}·V1(t)";

    PasosSolucionAnalitica pasos({
      Map<String, double> coeficientesParticulares = const {},
      double? c1Homogenea,
      double? c2Homogenea,
    }) {
      return PasosSolucionAnalitica(
        edo: edo,
        a: a,
        b: b,
        c: c,
        r1: r1,
        r2: r2,
        coeficientesParticulares: coeficientesParticulares,
        c1Homogenea: c1Homogenea,
        c2Homogenea: c2Homogenea,
      );
    }

    if (c.abs() < 1e-12) {
      return SolucionGeneral.noSoportado(
        motivo: 'a21 = 0: no se puede despejar x(t) desde y(t).',
        pasos: pasos(),
        terminosV1: terminosV1,
      );
    }
    if (r1 == null || r2 == null) {
      return SolucionGeneral.noSoportado(
        motivo:
            'Raíces no reales distintas (discriminante $discriminante): '
            'usar solo el solver numérico.',
        pasos: pasos(),
        terminosV1: terminosV1,
      );
    }

    final particular = _particular(
      escenario: escenario,
      factor: factor,
      a: a,
      b: b,
      c: c,
      r1: r1,
      r2: r2,
    );
    if (particular == null) {
      return SolucionGeneral.noSoportado(
        motivo:
            'No se pudo construir la solución particular de este escenario.',
        pasos: pasos(),
        terminosV1: terminosV1,
      );
    }

    final yParticular = particular.terminos;
    final yp0 = evaluarTerminos(yParticular, 0);
    final ypDerivada0 = _evaluarDerivadas(yParticular, 0);

    final s = condiciones.y0 - yp0;
    final velocidadInicial =
        c * condiciones.x0 + coeficientes.a22 * condiciones.y0;
    final v = velocidadInicial - ypDerivada0;

    final denominador = r2 - r1;
    final c1Homogenea = (s * r2 - v) / denominador;
    final c2Homogenea = (v - s * r1) / denominador;

    final yTerminos = combinarTerminos([
      TerminoSolucion(
        coeficiente: c1Homogenea,
        tipo: TipoTermino.exponencial,
        parametro: r1,
      ),
      TerminoSolucion(
        coeficiente: c2Homogenea,
        tipo: TipoTermino.exponencial,
        parametro: r2,
      ),
      ...yParticular,
    ]);

    final xTerminos = combinarTerminos(
      _despejarX(yTerminos, coeficientes.a22, c),
    );

    return SolucionGeneral(
      estado: EstadoSolucionGeneral.ok,
      variable: 't',
      terminosV1: terminosV1,
      terminosX: xTerminos,
      terminosY: yTerminos,
      pasos: pasos(
        coeficientesParticulares: particular.coeficientes,
        c1Homogenea: c1Homogenea,
        c2Homogenea: c2Homogenea,
      ),
    );
  }

  List<TerminoSolucion> _terminosV1(EscenarioTrafico escenario) {
    final parametros = escenario.mapaParametros;
    switch (escenario.id) {
      case 'lineal':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        final m = _parametro(parametros, 'm', escenario.id);
        return [
          TerminoSolucion(coeficiente: p0, tipo: TipoTermino.constante),
          TerminoSolucion(coeficiente: m, tipo: TipoTermino.lineal),
        ];
      case 'constante':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        return [TerminoSolucion(coeficiente: p0, tipo: TipoTermino.constante)];
      case 'exponencial':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        final r = _parametro(parametros, 'r', escenario.id);
        final bExp = _parametro(parametros, 'b', escenario.id);
        if (r.abs() < 1e-12) {
          throw FormatException(
            'El escenario exponencial requiere r != 0 (escenario "${escenario.id}")',
          );
        }
        return [
          TerminoSolucion(coeficiente: -bExp / r, tipo: TipoTermino.constante),
          TerminoSolucion(
            coeficiente: p0 + bExp / r,
            tipo: TipoTermino.exponencial,
            parametro: r,
          ),
        ];
      case 'ciclico':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        final dP0 = _parametro(parametros, 'dP0', escenario.id);
        final periodo = _parametro(parametros, 'periodo_min', escenario.id);
        if (periodo.abs() < 1e-12) {
          throw FormatException(
            'El escenario cíclico requiere periodo_min != 0 (escenario "${escenario.id}")',
          );
        }
        final omega = 2 * math.pi / periodo;
        return [
          TerminoSolucion(
            coeficiente: p0,
            tipo: TipoTermino.coseno,
            parametro: omega,
          ),
          TerminoSolucion(
            coeficiente: dP0 / omega,
            tipo: TipoTermino.seno,
            parametro: omega,
          ),
        ];
      default:
        throw ArgumentError.value(
          escenario.id,
          'escenario',
          'Escenario no soportado por el solver analítico',
        );
    }
  }

  _Particular? _particular({
    required EscenarioTrafico escenario,
    required double factor,
    required double a,
    required double b,
    required double c,
    required double r1,
    required double r2,
  }) {
    final parametros = escenario.mapaParametros;
    switch (escenario.id) {
      case 'lineal':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        final m = _parametro(parametros, 'm', escenario.id);
        return _particularPolinomial(
          [factor * p0, factor * m],
          a: a,
          b: b,
          c: c,
          r1: r1,
          r2: r2,
        );
      case 'constante':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        return _particularPolinomial(
          [factor * p0],
          a: a,
          b: b,
          c: c,
          r1: r1,
          r2: r2,
        );
      case 'exponencial':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        final r = _parametro(parametros, 'r', escenario.id);
        final bExp = _parametro(parametros, 'b', escenario.id);
        final constante = _particularPolinomial(
          [-factor * bExp / r],
          a: a,
          b: b,
          c: c,
          r1: r1,
          r2: r2,
        );
        if (constante == null) return null;
        final amplitud = factor * (p0 + bExp / r);
        final resonante = (r - r1).abs() < 1e-9 || (r - r2).abs() < 1e-9;
        if (resonante) {
          final coeficiente = c * amplitud / (2 * r + a);
          return _Particular(
            terminos: [
              ...constante.terminos,
              TerminoSolucion(
                coeficiente: coeficiente,
                tipo: TipoTermino.exponencialLineal,
                parametro: r,
              ),
            ],
            coeficientes: {...constante.coeficientes, 'B': coeficiente},
          );
        }
        final coeficiente = c * amplitud / ((r - r1) * (r - r2));
        return _Particular(
          terminos: [
            ...constante.terminos,
            TerminoSolucion(
              coeficiente: coeficiente,
              tipo: TipoTermino.exponencial,
              parametro: r,
            ),
          ],
          coeficientes: {...constante.coeficientes, 'B': coeficiente},
        );
      case 'ciclico':
        final p0 = _parametro(parametros, 'P0', escenario.id);
        final dP0 = _parametro(parametros, 'dP0', escenario.id);
        final periodo = _parametro(parametros, 'periodo_min', escenario.id);
        final omega = 2 * math.pi / periodo;
        final g = c * factor * p0;
        final h = c * factor * dP0 / omega;
        final p = b - omega * omega;
        final q = a * omega;
        final determinante = p * p + q * q;
        if (determinante.abs() < 1e-14) return null;
        final amplitudCoseno = (p * g - q * h) / determinante;
        final amplitudSeno = (q * g + p * h) / determinante;
        return _Particular(
          terminos: [
            TerminoSolucion(
              coeficiente: amplitudCoseno,
              tipo: TipoTermino.coseno,
              parametro: omega,
            ),
            TerminoSolucion(
              coeficiente: amplitudSeno,
              tipo: TipoTermino.seno,
              parametro: omega,
            ),
          ],
          coeficientes: {'A': amplitudCoseno, 'B': amplitudSeno},
        );
      default:
        throw ArgumentError.value(
          escenario.id,
          'escenario',
          'Escenario no soportado por el solver analítico',
        );
    }
  }

  _Particular? _particularPolinomial(
    List<double> entrada, {
    required double a,
    required double b,
    required double c,
    required double r1,
    required double r2,
  }) {
    final gradoEntrada = entrada.length - 1;
    var multiplicidadCero = 0;
    if (r1.abs() < 1e-9) multiplicidadCero++;
    if (r2.abs() < 1e-9) multiplicidadCero++;
    final grado = gradoEntrada + multiplicidadCero;
    if (grado > 2) return null;

    final cantidad = grado + 1;
    final matriz = List.generate(
      cantidad,
      (_) => List<double>.filled(cantidad, 0),
    );
    final vector = List<double>.filled(cantidad, 0);
    for (var j = 0; j < cantidad; j++) {
      matriz[j][j] += b;
      if (j + 1 < cantidad) matriz[j][j + 1] += a * (j + 1);
      if (j + 2 < cantidad) matriz[j][j + 2] += (j + 2) * (j + 1);
      vector[j] = c * (j < entrada.length ? entrada[j] : 0);
    }

    final solucion = _resolverLineal(matriz, vector);
    if (solucion == null) return null;

    final terminos = <TerminoSolucion>[];
    final coeficientes = <String, double>{};
    for (var j = 0; j < solucion.length; j++) {
      final coeficiente = solucion[j];
      if (coeficiente.abs() < 1e-12) continue;
      final tipo = switch (j) {
        0 => TipoTermino.constante,
        1 => TipoTermino.lineal,
        _ => TipoTermino.cuadratico,
      };
      terminos.add(TerminoSolucion(coeficiente: coeficiente, tipo: tipo));
      coeficientes['p$j'] = coeficiente;
    }
    return _Particular(terminos: terminos, coeficientes: coeficientes);
  }

  List<TerminoSolucion> _despejarX(
    List<TerminoSolucion> terminosY,
    double a22,
    double a21,
  ) {
    final terminos = <TerminoSolucion>[];
    for (final termino in terminosY) {
      for (final derivada in termino.derivar()) {
        terminos.add(derivada.escalar(1 / a21));
      }
      terminos.add(termino.escalar(-a22 / a21));
    }
    return terminos;
  }

  double _evaluarDerivadas(List<TerminoSolucion> terminos, double t) {
    var total = 0.0;
    for (final termino in terminos) {
      total += termino.evaluarDerivada(t);
    }
    return total;
  }

  List<double>? _resolverLineal(
    List<List<double>> matriz,
    List<double> vector,
  ) {
    final n = vector.length;
    final aumentada = [
      for (var i = 0; i < n; i++) [...matriz[i], vector[i]],
    ];
    for (var columna = 0; columna < n; columna++) {
      var pivote = columna;
      for (var fila = columna + 1; fila < n; fila++) {
        if (aumentada[fila][columna].abs() > aumentada[pivote][columna].abs()) {
          pivote = fila;
        }
      }
      if (aumentada[pivote][columna].abs() < 1e-14) return null;
      final temporal = aumentada[columna];
      aumentada[columna] = aumentada[pivote];
      aumentada[pivote] = temporal;
      final valorPivote = aumentada[columna][columna];
      for (var k = columna; k <= n; k++) {
        aumentada[columna][k] /= valorPivote;
      }
      for (var fila = 0; fila < n; fila++) {
        if (fila == columna) continue;
        final factor = aumentada[fila][columna];
        if (factor == 0) continue;
        for (var k = columna; k <= n; k++) {
          aumentada[fila][k] -= factor * aumentada[columna][k];
        }
      }
    }
    return [for (var i = 0; i < n; i++) aumentada[i][n]];
  }

  double _parametro(
    Map<String, double> parametros,
    String clave,
    String escenario,
  ) {
    final valor = parametros[clave];
    if (valor == null) {
      throw FormatException(
        'Falta el parámetro "$clave" en el escenario "$escenario"',
      );
    }
    return valor;
  }

  static String _num(double valor) {
    final texto = valor.toStringAsFixed(6);
    return texto.contains('.')
        ? texto
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '')
        : texto;
  }
}

class _Particular {
  final List<TerminoSolucion> terminos;
  final Map<String, double> coeficientes;

  const _Particular({required this.terminos, required this.coeficientes});
}
