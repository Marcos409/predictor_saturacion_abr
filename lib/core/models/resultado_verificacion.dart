class ResultadoVerificacion {
  final double errorMaximo;
  final double errorMaximoX;
  final double errorMaximoY;
  final double tiempoErrorMaximo;
  final double umbral;
  final int cantidadPuntos;

  const ResultadoVerificacion({
    required this.errorMaximo,
    required this.errorMaximoX,
    required this.errorMaximoY,
    required this.tiempoErrorMaximo,
    required this.umbral,
    required this.cantidadPuntos,
  });

  bool get hayDiscrepancia => errorMaximo > umbral;
}
