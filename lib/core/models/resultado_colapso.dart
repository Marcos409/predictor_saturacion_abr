class ResultadoColapso {
  final String tanque;
  final double limite;
  final double? tiempo;

  const ResultadoColapso({
    required this.tanque,
    required this.limite,
    required this.tiempo,
  });

  bool get colapsa => tiempo != null;
}
