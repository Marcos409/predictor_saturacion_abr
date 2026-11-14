import '../core/models/resultado_ventana_accion.dart';
import '../core/models/sistema.dart';

enum NivelSemaforo { sinColapso, estable, precaucion, critico }

NivelSemaforo evaluarNivelSemaforo({
  required ResultadoVentanaAccion? ventana,
  required ConfiguracionSemaforo configuracion,
}) {
  if (ventana == null || ventana.ventanaAccion == null) {
    return NivelSemaforo.sinColapso;
  }
  final valor = ventana.ventanaAccion!;
  if (valor < configuracion.ventanaAmarilla) return NivelSemaforo.critico;
  if (valor < configuracion.ventanaVerde) return NivelSemaforo.precaucion;
  return NivelSemaforo.estable;
}

String etiquetaNivelSemaforo(NivelSemaforo nivel) {
  return switch (nivel) {
    NivelSemaforo.sinColapso => 'Sin colapso',
    NivelSemaforo.estable => 'Estable',
    NivelSemaforo.precaucion => 'Precaución',
    NivelSemaforo.critico => 'Crítico',
  };
}
