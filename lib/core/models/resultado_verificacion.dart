enum EstadoVerificacion { coincide, discrepancia, noDisponible }

class ResultadoVerificacion {
  final double errorMaximo;
  final double errorMaximoX;
  final double errorMaximoY;
  final double errorRelativo;
  final double valorMaximo;
  final double tiempoErrorMaximo;
  final double umbral;
  final int cantidadPuntos;
  final bool disponible;
  final String? motivoNoDisponible;

  const ResultadoVerificacion({
    required this.errorMaximo,
    required this.errorMaximoX,
    required this.errorMaximoY,
    required this.errorRelativo,
    required this.valorMaximo,
    required this.tiempoErrorMaximo,
    required this.umbral,
    required this.cantidadPuntos,
    this.disponible = true,
    this.motivoNoDisponible,
  });

  factory ResultadoVerificacion.noDisponible({
    required double umbral,
    required String motivo,
  }) {
    return ResultadoVerificacion(
      errorMaximo: 0,
      errorMaximoX: 0,
      errorMaximoY: 0,
      errorRelativo: 0,
      valorMaximo: 0,
      tiempoErrorMaximo: 0,
      umbral: umbral,
      cantidadPuntos: 0,
      disponible: false,
      motivoNoDisponible: motivo,
    );
  }

  bool get hayDiscrepancia =>
      disponible && errorMaximo > 0 && errorRelativo >= umbral;

  bool get hayCoincidencia => disponible && !hayDiscrepancia;

  EstadoVerificacion get estado {
    if (!disponible) return EstadoVerificacion.noDisponible;
    return hayDiscrepancia
        ? EstadoVerificacion.discrepancia
        : EstadoVerificacion.coincide;
  }
}
