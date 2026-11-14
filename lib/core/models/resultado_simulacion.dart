import 'punto_simulacion.dart';

class ResultadoSimulacion {
  final List<PuntoSimulacion> puntos;
  final double paso;
  final double tInicial;
  final double tFinal;

  const ResultadoSimulacion({
    required this.puntos,
    required this.paso,
    required this.tInicial,
    required this.tFinal,
  });

  PuntoSimulacion get inicial => puntos.first;
  PuntoSimulacion get ultimo => puntos.last;
}
