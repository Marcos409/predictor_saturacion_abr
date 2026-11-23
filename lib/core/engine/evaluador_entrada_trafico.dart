import '../models/escenario_trafico.dart';
import 'evaluador_expresiones.dart';

class EvaluadorEntradaTrafico {
  final EscenarioTrafico escenario;
  final EvaluadorExpresiones _evaluador;
  final String _variableTiempo;
  late final double Function(double t) _compilada;

  EvaluadorEntradaTrafico({
    required this.escenario,
    EvaluadorExpresiones? evaluador,
    String variableTiempo = 't',
  }) : _evaluador = evaluador ?? EvaluadorExpresiones(),
       _variableTiempo = variableTiempo {
    final parametros = escenario.mapaParametros;
    if (escenario.id == 'exponencial' &&
        (parametros['r'] ?? 1).abs() < 1e-12) {
      _compilada = _evaluador.compilarEntrada(
        'P0 + b*t',
        parametros,
        variableTiempo: _variableTiempo,
      );
      return;
    }
    _compilada = _evaluador.compilarEntrada(
      escenario.expresionV1,
      parametros,
      variableTiempo: _variableTiempo,
    );
  }

  double evaluar(double t) => _compilada(t);
}
