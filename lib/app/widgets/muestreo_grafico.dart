import '../../core/models/punto_entrada.dart';

const int maxPuntosGrafico = 1500;

List<PuntoEntrada> muestrearParaGrafico(
  List<PuntoEntrada> puntos, {
  int maximo = maxPuntosGrafico,
}) {
  if (puntos.length <= maximo || maximo < 2) return puntos;

  final muestreados = <PuntoEntrada>[];
  final paso = (puntos.length - 1) / (maximo - 1);
  for (var i = 0; i < maximo - 1; i++) {
    muestreados.add(puntos[(i * paso).round()]);
  }
  muestreados.add(puntos.last);
  return muestreados;
}
