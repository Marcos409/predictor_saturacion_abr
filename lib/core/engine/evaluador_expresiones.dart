import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart' as me;

class EvaluadorExpresiones {
  final Map<String, me.Expression> _cache = {};
  final me.GrammarParser _parser;

  EvaluadorExpresiones() : _parser = _crearParser();

  static me.GrammarParser _crearParser() {
    final parser = me.GrammarParser();
    parser.addFunction('Exp', (argumentos) => math.exp(argumentos.first));
    return parser;
  }

  String _normalizar(String expresion) {
    return expresion.replaceAll(
      RegExp(r'\bexp\s*\(', caseSensitive: false),
      'Exp(',
    );
  }

  me.Expression _parsear(String expresion) {
    return _cache.putIfAbsent(
      expresion,
      () => _parser.parse(_normalizar(expresion)),
    );
  }

  double evaluar(String expresion, Map<String, double> variables) {
    final contexto = me.ContextModel();
    variables.forEach((nombre, valor) {
      contexto.bindVariable(me.Variable(nombre), me.Number(valor));
    });
    final resultado = me.RealEvaluator(contexto).evaluate(_parsear(expresion));
    return resultado.toDouble();
  }

  double Function(double t) compilarEntrada(
    String expresion,
    Map<String, double> parametros, {
    String variableTiempo = 't',
  }) {
    final expresionParseada = _parsear(expresion);
    final contexto = me.ContextModel();
    parametros.forEach((nombre, valor) {
      contexto.bindVariableName(nombre, me.Number(valor));
    });
    final evaluador = me.RealEvaluator(contexto);
    return (t) {
      contexto.bindVariableName(variableTiempo, me.Number(t));
      return evaluador.evaluate(expresionParseada).toDouble();
    };
  }
}
