import '../models/punto_simulacion.dart';
import '../models/resultado_colapso.dart';
import '../models/resultado_ventana_accion.dart';

class DetectorColapso {
  const DetectorColapso();

  ResultadoColapso detectar({
    required String tanque,
    required double limite,
    required List<PuntoSimulacion> puntos,
    required double Function(PuntoSimulacion punto) valor,
  }) {
    if (puntos.isEmpty) {
      return ResultadoColapso(tanque: tanque, limite: limite, tiempo: null);
    }

    final valorInicial = valor(puntos.first);
    if (valorInicial >= limite) {
      return ResultadoColapso(
        tanque: tanque,
        limite: limite,
        tiempo: puntos.first.t,
      );
    }

    for (var i = 1; i < puntos.length; i++) {
      final anterior = puntos[i - 1];
      final actual = puntos[i];
      final valorAnterior = valor(anterior);
      final valorActual = valor(actual);

      if (valorAnterior < limite && valorActual >= limite) {
        final diferencia = valorActual - valorAnterior;
        final tiempo = diferencia.abs() < 1e-12
            ? actual.t
            : anterior.t +
                  (limite - valorAnterior) /
                      diferencia *
                      (actual.t - anterior.t);
        return ResultadoColapso(tanque: tanque, limite: limite, tiempo: tiempo);
      }
    }

    return ResultadoColapso(tanque: tanque, limite: limite, tiempo: null);
  }

  ResultadoVentanaAccion calcularVentanaAccion({
    required ResultadoColapso colapsoCapaWeb,
    required ResultadoColapso colapsoBaseDatos,
    required double tiempoReaccion,
  }) {
    return ResultadoVentanaAccion(
      colapsoCapaWeb: colapsoCapaWeb,
      colapsoBaseDatos: colapsoBaseDatos,
      tiempoReaccion: tiempoReaccion,
    );
  }
}
