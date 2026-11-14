import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_expresiones.dart';
import 'package:predictor_saturacion_abr/core/engine/evaluador_solucion_analitica.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_general.dart';

void main() {
  group('TerminoSolucion', () {
    const t = 1.5;
    final casos =
        <
          ({
            String nombre,
            TerminoSolucion termino,
            double valor,
            double derivada,
          })
        >[
          (
            nombre: 'constante',
            termino: const TerminoSolucion(
              coeficiente: 2.5,
              tipo: TipoTermino.constante,
            ),
            valor: 2.5,
            derivada: 0,
          ),
          (
            nombre: 'lineal',
            termino: const TerminoSolucion(
              coeficiente: 3,
              tipo: TipoTermino.lineal,
            ),
            valor: 4.5,
            derivada: 3,
          ),
          (
            nombre: 'cuadrático',
            termino: const TerminoSolucion(
              coeficiente: 2,
              tipo: TipoTermino.cuadratico,
            ),
            valor: 4.5,
            derivada: 6,
          ),
          (
            nombre: 'exponencial',
            termino: const TerminoSolucion(
              coeficiente: 4,
              tipo: TipoTermino.exponencial,
              parametro: 0.5,
            ),
            valor: 4 * math.exp(0.75),
            derivada: 2 * math.exp(0.75),
          ),
          (
            nombre: 'exponencial lineal',
            termino: const TerminoSolucion(
              coeficiente: 1.5,
              tipo: TipoTermino.exponencialLineal,
              parametro: -0.2,
            ),
            valor: 2.25 * math.exp(-0.3),
            derivada: 1.05 * math.exp(-0.3),
          ),
          (
            nombre: 'seno',
            termino: const TerminoSolucion(
              coeficiente: 2,
              tipo: TipoTermino.seno,
              parametro: 0.7,
            ),
            valor: 2 * math.sin(1.05),
            derivada: 1.4 * math.cos(1.05),
          ),
          (
            nombre: 'coseno',
            termino: const TerminoSolucion(
              coeficiente: -3,
              tipo: TipoTermino.coseno,
              parametro: 0.4,
            ),
            valor: -3 * math.cos(0.6),
            derivada: 1.2 * math.sin(0.6),
          ),
        ];

    for (final caso in casos) {
      test('${caso.nombre} evalúa, deriva y escala', () {
        expect(caso.termino.evaluar(t), closeTo(caso.valor, 1e-12));
        expect(caso.termino.evaluarDerivada(t), closeTo(caso.derivada, 1e-12));

        final derivadas = caso.termino.derivar();
        final sumaDerivadas = derivadas.fold<double>(
          0,
          (total, termino) => total + termino.evaluar(t),
        );
        expect(sumaDerivadas, closeTo(caso.derivada, 1e-12));

        final escalado = caso.termino.escalar(2);
        expect(escalado.evaluar(t), closeTo(2 * caso.valor, 1e-12));
        expect(escalado.tipo, caso.termino.tipo);
        expect(escalado.parametro, caso.termino.parametro);
      });
    }

    test('detecta coeficientes nulos', () {
      expect(
        const TerminoSolucion(coeficiente: 0, tipo: TipoTermino.lineal).esNulo,
        isTrue,
      );
      expect(
        const TerminoSolucion(
          coeficiente: 1e-13,
          tipo: TipoTermino.lineal,
        ).esNulo,
        isTrue,
      );
      expect(
        const TerminoSolucion(coeficiente: 1, tipo: TipoTermino.lineal).esNulo,
        isFalse,
      );
    });
  });

  group('combinarTerminos', () {
    test('suma términos del mismo tipo y parámetro', () {
      final combinados = combinarTerminos(const [
        TerminoSolucion(coeficiente: 1, tipo: TipoTermino.constante),
        TerminoSolucion(coeficiente: 2, tipo: TipoTermino.constante),
        TerminoSolucion(
          coeficiente: 3,
          tipo: TipoTermino.exponencial,
          parametro: 0.5,
        ),
        TerminoSolucion(
          coeficiente: 4,
          tipo: TipoTermino.exponencial,
          parametro: 0.5,
        ),
        TerminoSolucion(
          coeficiente: 5,
          tipo: TipoTermino.exponencial,
          parametro: 0.2,
        ),
        TerminoSolucion(
          coeficiente: 6,
          tipo: TipoTermino.exponencialLineal,
          parametro: 0.5,
        ),
        TerminoSolucion(coeficiente: 0, tipo: TipoTermino.seno, parametro: 1),
      ]);

      expect(combinados, hasLength(4));
      expect(combinados[0].tipo, TipoTermino.constante);
      expect(combinados[0].coeficiente, 3);
      expect(combinados[1].tipo, TipoTermino.exponencial);
      expect(combinados[1].parametro, 0.5);
      expect(combinados[1].coeficiente, 7);
      expect(combinados[2].parametro, 0.2);
      expect(combinados[2].coeficiente, 5);
      expect(combinados[3].tipo, TipoTermino.exponencialLineal);
      expect(combinados[3].coeficiente, 6);
    });

    test('considera iguales los parámetros dentro de la tolerancia', () {
      final combinados = combinarTerminos(const [
        TerminoSolucion(
          coeficiente: 1,
          tipo: TipoTermino.exponencial,
          parametro: 0.5,
        ),
        TerminoSolucion(
          coeficiente: 2,
          tipo: TipoTermino.exponencial,
          parametro: 0.5000000001,
        ),
      ]);

      expect(combinados, hasLength(1));
      expect(combinados.single.coeficiente, 3);
    });

    test('elimina los términos cuya suma es cero', () {
      final combinados = combinarTerminos(const [
        TerminoSolucion(coeficiente: 2, tipo: TipoTermino.lineal),
        TerminoSolucion(coeficiente: -2, tipo: TipoTermino.lineal),
        TerminoSolucion(coeficiente: 3, tipo: TipoTermino.constante),
      ]);

      expect(combinados, hasLength(1));
      expect(combinados.single.coeficiente, 3);
    });
  });

  group('formatearExpresion y evaluarTerminos', () {
    test('formatea una lista vacía como cero', () {
      expect(formatearExpresion(const [], 't'), '0');
      expect(evaluarTerminos(const [], 5), 0);
    });

    test('respeta el signo del primer término y los separadores', () {
      expect(
        formatearExpresion(const [
          TerminoSolucion(coeficiente: -2, tipo: TipoTermino.lineal),
        ], 't'),
        '-2.0*t',
      );

      expect(
        formatearExpresion(const [
          TerminoSolucion(coeficiente: 2, tipo: TipoTermino.lineal),
          TerminoSolucion(coeficiente: -3, tipo: TipoTermino.constante),
        ], 't'),
        '2.0*t - 3.0',
      );
    });

    test('la expresión formateada se evalúa igual que los términos', () {
      const terminos = [
        TerminoSolucion(coeficiente: 2, tipo: TipoTermino.lineal),
        TerminoSolucion(
          coeficiente: -3,
          tipo: TipoTermino.exponencial,
          parametro: -0.2,
        ),
        TerminoSolucion(coeficiente: 4, tipo: TipoTermino.seno, parametro: 0.5),
      ];
      final expresion = formatearExpresion(terminos, 't');
      final evaluador = EvaluadorExpresiones();

      for (final t in [0.0, 1.0, 2.5]) {
        expect(
          evaluador.evaluar(expresion, {'t': t}),
          closeTo(evaluarTerminos(terminos, t), 1e-12),
        );
      }
    });
  });

  group('SolucionGeneral', () {
    const pasos = PasosSolucionAnalitica(edo: "y'' + y = 0", a: 0, b: 1, c: 1);
    const v1 = [TerminoSolucion(coeficiente: 10, tipo: TipoTermino.constante)];

    test('noSoportado conserva el motivo y anula x e y', () {
      final solucion = SolucionGeneral.noSoportado(
        motivo: 'sin soporte',
        pasos: pasos,
        terminosV1: v1,
      );

      expect(solucion.soportada, isFalse);
      expect(solucion.motivo, 'sin soporte');
      expect(solucion.terminosX, isEmpty);
      expect(solucion.terminosY, isEmpty);
      expect(solucion.evaluarX(2), 0);
      expect(solucion.evaluarY(2), 0);
      expect(solucion.evaluarV1(2), 10);
      expect(solucion.variable, 't');
      expect(solucion.expresionV1, '10.0');
      expect(solucion.expresionX, '0');
      expect(solucion.expresionY, '0');
    });

    test('evalúa términos y derivadas y se convierte a SolucionAnalitica', () {
      const solucion = SolucionGeneral(
        estado: EstadoSolucionGeneral.ok,
        pasos: pasos,
        terminosV1: v1,
        terminosX: [
          TerminoSolucion(coeficiente: 2, tipo: TipoTermino.lineal),
          TerminoSolucion(
            coeficiente: -1,
            tipo: TipoTermino.exponencial,
            parametro: -0.2,
          ),
        ],
        terminosY: [
          TerminoSolucion(coeficiente: 3, tipo: TipoTermino.constante),
          TerminoSolucion(
            coeficiente: 4,
            tipo: TipoTermino.seno,
            parametro: 0.5,
          ),
        ],
      );

      expect(solucion.soportada, isTrue);
      expect(solucion.motivo, isNull);
      expect(solucion.evaluarV1(7), 10);
      expect(solucion.evaluarX(2), closeTo(4 - math.exp(-0.4), 1e-12));
      expect(
        solucion.evaluarDerivadaX(2),
        closeTo(2 + 0.2 * math.exp(-0.4), 1e-12),
      );
      expect(solucion.evaluarY(2), closeTo(3 + 4 * math.sin(1), 1e-12));
      expect(solucion.evaluarDerivadaY(2), closeTo(2 * math.cos(1), 1e-12));

      final analitica = solucion.aSolucionAnalitica(
        version: 2,
        unidadTiempo: 'min',
      );
      expect(analitica.version, 2);
      expect(analitica.unidadTiempo, 'min');
      expect(analitica.variable, 't');
      expect(analitica.expresionX, solucion.expresionX);
      expect(analitica.expresionY, solucion.expresionY);

      final evaluador = EvaluadorSolucionAnalitica(solucion: analitica);
      for (final t in [0.0, 1.0, 2.0]) {
        expect(evaluador.evaluarX(t), closeTo(solucion.evaluarX(t), 1e-9));
        expect(evaluador.evaluarY(t), closeTo(solucion.evaluarY(t), 1e-9));
      }
    });
  });
}
