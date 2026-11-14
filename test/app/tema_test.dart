import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/tema.dart';

double _contraste(Color primero, Color segundo) {
  final luminanciaPrimero = primero.computeLuminance();
  final luminanciaSegundo = segundo.computeLuminance();
  final mayor = math.max(luminanciaPrimero, luminanciaSegundo);
  final menor = math.min(luminanciaPrimero, luminanciaSegundo);
  return (mayor + 0.05) / (menor + 0.05);
}

void main() {
  group('Accesibilidad del tema', () {
    const fondos = [ColoresApp.fondo, ColoresApp.panel];

    test('los textos y colores de estado superan 4.5:1', () {
      const primerosPlanos = [
        ColoresApp.textoPrimario,
        ColoresApp.textoSecundario,
        ColoresApp.acento,
        ColoresApp.alerta,
        ColoresApp.aviso,
        ColoresApp.ok,
      ];

      for (final fondo in fondos) {
        for (final primerPlano in primerosPlanos) {
          expect(
            _contraste(primerPlano, fondo),
            greaterThanOrEqualTo(4.5),
            reason: 'Contraste insuficiente entre $primerPlano y $fondo',
          );
        }
      }
    });

    test('los bordes de controles superan 3:1', () {
      for (final fondo in fondos) {
        expect(
          _contraste(ColoresApp.bordeControl, fondo),
          greaterThanOrEqualTo(3),
          reason: 'Contraste insuficiente entre el borde y $fondo',
        );
      }
    });

    test('los botones tienen un área táctil mínima de 44 px', () {
      final tema = construirTemaOscuro();
      const minimo = Size(44, 44);

      expect(tema.filledButtonTheme.style?.minimumSize?.resolve({}), minimo);
      expect(tema.outlinedButtonTheme.style?.minimumSize?.resolve({}), minimo);
      expect(tema.textButtonTheme.style?.minimumSize?.resolve({}), minimo);
    });
  });
}
