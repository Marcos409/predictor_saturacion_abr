import 'sistema.dart';

class FlujoTubo {
  final String id;
  final String nombre;
  final double caudal;
  final double flujo;

  const FlujoTubo({
    required this.id,
    required this.nombre,
    required this.caudal,
    required this.flujo,
  });
}

class FlujosTubos {
  final bool hayDesglose;
  final double entradaExterna;
  final double? aAB;
  final double? aSalida;
  final double? bAA;
  final double? bSalida;
  final double entradaTotalA;
  final double salidaTotalA;
  final double balanceA;
  final double entradaTotalB;
  final double salidaTotalB;
  final double balanceB;

  const FlujosTubos({
    required this.hayDesglose,
    required this.entradaExterna,
    required this.aAB,
    required this.aSalida,
    required this.bAA,
    required this.bSalida,
    required this.entradaTotalA,
    required this.salidaTotalA,
    required this.balanceA,
    required this.entradaTotalB,
    required this.salidaTotalB,
    required this.balanceB,
  });

  factory FlujosTubos.calcular({
    required ConfiguracionSistema sistema,
    required double x,
    required double y,
    required double entradaExterna,
  }) {
    final tanques = sistema.tanques;
    if (tanques.modoCoeficientes == 'directo') {
      final coeficientes = sistema.coeficientes;
      return FlujosTubos(
        hayDesglose: false,
        entradaExterna: entradaExterna,
        aAB: null,
        aSalida: null,
        bAA: null,
        bSalida: null,
        entradaTotalA: double.nan,
        salidaTotalA: double.nan,
        balanceA: entradaExterna + coeficientes.a11 * x + coeficientes.a12 * y,
        entradaTotalB: double.nan,
        salidaTotalB: double.nan,
        balanceB: coeficientes.a21 * x + coeficientes.a22 * y,
      );
    }

    final caudales = tanques.caudales;
    final aAB = caudales.aAB / tanques.volumenA * x;
    final aSalida = caudales.aSalida / tanques.volumenA * x;
    final bAA = caudales.bAA / tanques.volumenB * y;
    final bSalida = caudales.bSalida / tanques.volumenB * y;

    final entradaTotalA = entradaExterna + bAA;
    final salidaTotalA = aAB + aSalida;
    final entradaTotalB = aAB;
    final salidaTotalB = bAA + bSalida;

    return FlujosTubos(
      hayDesglose: true,
      entradaExterna: entradaExterna,
      aAB: aAB,
      aSalida: aSalida,
      bAA: bAA,
      bSalida: bSalida,
      entradaTotalA: entradaTotalA,
      salidaTotalA: salidaTotalA,
      balanceA: entradaTotalA - salidaTotalA,
      entradaTotalB: entradaTotalB,
      salidaTotalB: salidaTotalB,
      balanceB: entradaTotalB - salidaTotalB,
    );
  }

  double get flujoMaximo {
    var maximo = entradaExterna.abs();
    for (final valor in [aAB, aSalida, bAA, bSalida]) {
      if (valor != null && valor.abs() > maximo) maximo = valor.abs();
    }
    return maximo;
  }
}
