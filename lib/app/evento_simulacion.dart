enum TipoEventoSimulacion { aviso, critico, escalado, sistema }

class EventoSimulacion {
  final double minuto;
  final TipoEventoSimulacion tipo;
  final String mensaje;

  const EventoSimulacion({
    required this.minuto,
    required this.tipo,
    required this.mensaje,
  });
}
