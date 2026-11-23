import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:predictor_saturacion_abr/app/estado_aplicacion.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_verificacion.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_analitica.dart';
import 'package:predictor_saturacion_abr/features/matematica/pantalla_matematica.dart';

import '../engine/configuracion_prueba.dart';

EstadoAplicacion crearEstado({
  ConfiguracionSistema? sistema,
  SolucionAnalitica? solucionAnalitica,
}) {
  return EstadoAplicacion(
    sistema: sistema ?? cargarSistema(),
    escenarios: cargarEscenarios(),
    solucionAnalitica: solucionAnalitica ?? cargarSolucionAnalitica(),
  );
}

SolucionAnalitica solucionAplicable({String? expresionX}) {
  final escenario = cargarEscenarios().buscarPorId('lineal')!;
  return SolucionAnalitica(
    version: 1,
    unidadTiempo: 'min',
    variable: 't',
    expresionX:
        expresionX ?? '-50 + 20*t + 50*exp(-0.2*t)',
    expresionY: '-50 + 10*t + 50*exp(-0.2*t)',
    idEscenario: 'lineal',
    parametros: SolucionAnalitica.parametrosAplicables(
      escenario: escenario,
      configuracion: cargarSistema(),
    ),
  );
}

Future<void> bombearMatematica(
  WidgetTester tester,
  EstadoAplicacion estado,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<EstadoAplicacion>.value(
      value: estado,
      child: const MaterialApp(home: Scaffold(body: PantallaMatematica())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('los cuatro escenarios coinciden con el analítico general', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);

    for (final escenario in estado.escenarios) {
      estado.seleccionarEscenario(escenario.id);
      final verificacion = estado.verificacion!;

      expect(
        verificacion.estado,
        EstadoVerificacion.coincide,
        reason: escenario.id,
      );
      expect(verificacion.errorRelativo, lessThan(1e-6), reason: escenario.id);
      expect(verificacion.valorMaximo, greaterThan(0), reason: escenario.id);
      expect(estado.solucionGeneralActiva, isNotNull, reason: escenario.id);
      expect(
        estado.usaSolucionJsonParaVerificacion,
        isFalse,
        reason: escenario.id,
      );
    }
  });

  test('cambiar caudal, volumen, c1 o x0/y0 mantiene la coincidencia', () {
    final cambios = <(String, void Function(EstadoAplicacion))>[
      ('caudal', (estado) => estado.actualizarCaudal('A_a_B', 25)),
      ('volumen', (estado) => estado.actualizarVolumen('volumen_A', 120)),
      ('c1', (estado) => estado.actualizarC1(1.5)),
      ('x0 e y0', (estado) {
        estado.actualizarCondicionInicial('x0', 5);
        estado.actualizarCondicionInicial('y0', 7);
      }),
    ];

    for (final cambio in cambios) {
      final estado = crearEstado();
      addTearDown(estado.dispose);
      cambio.$2(estado);
      final verificacion = estado.verificacion!;

      expect(verificacion.estado, EstadoVerificacion.coincide, reason: cambio.$1);
      expect(verificacion.errorRelativo, lessThan(1e-6), reason: cambio.$1);
    }
  });

  test('soluciones.json se usa solo cuando identifica el escenario y parámetros', () {
    final sinIdentificador = crearEstado();
    addTearDown(sinIdentificador.dispose);
    final expresionGenerada = sinIdentificador.solucionAnaliticaActiva!;

    expect(sinIdentificador.usaSolucionJsonParaVerificacion, isFalse);
    expect(
      expresionGenerada.expresionX,
      isNot(sinIdentificador.solucionAnalitica.expresionX),
    );

    final aplicable = crearEstado(solucionAnalitica: solucionAplicable());
    addTearDown(aplicable.dispose);
    expect(aplicable.usaSolucionJsonParaVerificacion, isTrue);
    expect(aplicable.verificacion!.estado, EstadoVerificacion.coincide);

    final base = solucionAplicable();
    final parametrosDistintos = {...base.parametros!, 'm': 6};
    final noAplicable = crearEstado(
      solucionAnalitica: SolucionAnalitica(
        version: base.version,
        unidadTiempo: base.unidadTiempo,
        variable: base.variable,
        expresionX: base.expresionX,
        expresionY: base.expresionY,
        idEscenario: base.idEscenario,
        parametros: parametrosDistintos.map(
          (clave, valor) => MapEntry(clave, valor.toDouble()),
        ),
      ),
    );
    addTearDown(noAplicable.dispose);
    expect(noAplicable.usaSolucionJsonParaVerificacion, isFalse);
    expect(noAplicable.verificacion!.estado, EstadoVerificacion.coincide);
  });

  test('un término alterado de la solución analítica genera discrepancia', () {
    final estado = crearEstado(
      solucionAnalitica: solucionAplicable(
        expresionX: '-50 + 25*t + 50*exp(-0.2*t)',
      ),
    );
    addTearDown(estado.dispose);
    final verificacion = estado.verificacion!;

    expect(verificacion.estado, EstadoVerificacion.discrepancia);
    expect(verificacion.hayDiscrepancia, isTrue);
    expect(verificacion.errorMaximo, greaterThan(100));
    expect(verificacion.errorRelativo, greaterThan(1e-6));
  });

  test('el solver analítico no soportado produce aviso neutro', () {
    final sistema = cargarSistema().copyWith(
      tanques: cargarSistema().tanques.copyWith(
        modoCoeficientes: 'directo',
        coeficientesDirectos: const CoeficientesSistema(
          a11: -1,
          a12: 0,
          a21: 0,
          a22: -2,
        ),
      ),
    );
    final estado = crearEstado(sistema: sistema);
    addTearDown(estado.dispose);

    expect(estado.verificacion!.estado, EstadoVerificacion.noDisponible);
    expect(estado.verificacion!.hayDiscrepancia, isFalse);
    expect(estado.solucionGeneralActiva, isNull);
    expect(estado.motivoSolucionNoDisponible, contains('a21'));
  });

  test('el umbral relativo es configurable', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);

    expect(estado.sistema.verificacion.umbralError, 1e-6);
    estado.actualizarUmbralVerificacion(0.5);
    expect(estado.verificacion!.umbral, 0.5);
    expect(estado.verificacion!.estado, EstadoVerificacion.coincide);

    estado.actualizarUmbralVerificacion(1e-15);
    expect(estado.verificacion!.umbral, 1e-15);
    expect(estado.verificacion!.estado, EstadoVerificacion.discrepancia);
  });

  test('los valores de control del caso base no cambian', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);

    expect(estado.colapsoCapaWeb!.tiempo, closeTo(6.86, 0.05));
    expect(estado.colapsoBaseDatos!.tiempo, closeTo(24.97, 0.05));
    expect(estado.ventanaAccion!.ventanaAccion, closeTo(-3.1, 0.1));
  });

  testWidgets('muestra Coinciden con error absoluto y relativo', (tester) async {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    await bombearMatematica(tester, estado);

    expect(find.textContaining('Coinciden'), findsOneWidget);
    expect(find.textContaining('Sin discrepancia'), findsOneWidget);
    expect(find.textContaining('Discrepancia detectada'), findsNothing);
    expect(find.textContaining('Error máximo (absoluto)'), findsOneWidget);
    expect(find.textContaining('Error relativo'), findsWidgets);
    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
  });

  testWidgets('muestra Discrepancia detectada con término alterado', (
    tester,
  ) async {
    final estado = crearEstado(
      solucionAnalitica: solucionAplicable(
        expresionX: '-50 + 25*t + 50*exp(-0.2*t)',
      ),
    );
    addTearDown(estado.dispose);
    await bombearMatematica(tester, estado);

    expect(find.textContaining('Discrepancia detectada'), findsOneWidget);
    expect(find.textContaining('Coinciden'), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });

  testWidgets('muestra el aviso neutro sin solución analítica', (tester) async {
    final sistema = cargarSistema().copyWith(
      tanques: cargarSistema().tanques.copyWith(
        modoCoeficientes: 'directo',
        coeficientesDirectos: const CoeficientesSistema(
          a11: -1,
          a12: 0,
          a21: 0,
          a22: -2,
        ),
      ),
    );
    final estado = crearEstado(sistema: sistema);
    addTearDown(estado.dispose);
    await bombearMatematica(tester, estado);

    expect(
      find.text(
        'Verificación analítica no disponible para esta configuración; se usa solo el cálculo numérico',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Discrepancia detectada'), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsWidgets);
  });
}
