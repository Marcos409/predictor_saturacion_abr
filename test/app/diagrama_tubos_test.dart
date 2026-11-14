import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/formato.dart';
import 'package:predictor_saturacion_abr/app/widgets/diagrama_tubos.dart';

import '../engine/configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sistema = cargarSistema();

  Widget montar({
    double x = 0,
    double y = 0,
    double entrada = 10,
    bool editable = false,
    bool capaWebCaida = false,
    bool baseDatosCaida = false,
    bool mostrarNotaTeorica = false,
    void Function(String clave, double valor)? alCambiarCaudal,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DiagramaTubos(
            datos: DatosDiagramaTubos(
              sistema: sistema,
              tiempo: 0,
              x: x,
              y: y,
              entradaExterna: entrada,
              capacidadA: sistema.capacidades.capaWeb,
              capacidadB: sistema.capacidades.baseDatos,
              umbralAlerta: sistema.umbralAlerta,
              capaWebCaida: capaWebCaida,
              baseDatosCaida: baseDatosCaida,
              mostrarNotaTeorica: mostrarNotaTeorica,
            ),
            editable: editable,
            alCambiarCaudal: alCambiarCaudal,
            alCambiarVolumen: editable ? (_, _) {} : null,
          ),
        ),
      ),
    );
  }

  testWidgets('muestra los cinco tubos y la tabla Entra / Sale', (
    tester,
  ) async {
    await tester.pumpWidget(montar());

    expect(find.text('Entrada externa · c1·v1(t)'), findsOneWidget);
    expect(find.text('A → B · consultas'), findsOneWidget);
    expect(find.text('A · salida (rate limiting)'), findsOneWidget);
    expect(find.text('B → A · caché (retorno)'), findsOneWidget);
    expect(find.text('B · salida'), findsOneWidget);
    expect(find.text('Entra / Sale por tanque'), findsOneWidget);
    expect(find.textContaining("Balance neto · x'(t)"), findsOneWidget);
    expect(find.textContaining("Balance neto · y'(t)"), findsOneWidget);
  });

  testWidgets('el balance neto coincide con las derivadas del motor', (
    tester,
  ) async {
    await tester.pumpWidget(montar(x: 102.33, y: 32.33, entrada: 45));

    final coeficientes = sistema.coeficientes;
    final balanceA = 45 + coeficientes.a11 * 102.33 + coeficientes.a12 * 32.33;
    final balanceB = coeficientes.a21 * 102.33 + coeficientes.a22 * 32.33;

    expect(find.text(formatearNumero(balanceA)), findsWidgets);
    expect(find.text(formatearNumero(balanceB)), findsWidgets);
  });

  testWidgets('editar un caudal dispara la actualización del estado', (
    tester,
  ) async {
    String? clave;
    double? valor;

    await tester.pumpWidget(
      montar(
        editable: true,
        alCambiarCaudal: (claveCambiada, valorCambiado) {
          clave = claveCambiada;
          valor = valorCambiado;
        },
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'caudal · A_a_B'),
      '35',
    );
    await tester.pump();

    expect(clave, 'A_a_B');
    expect(valor, 35);
  });

  testWidgets('marca CAÍDO y muestra el desborde sin salir del recuadro', (
    tester,
  ) async {
    await tester.pumpWidget(
      montar(
        x: 120,
        y: 250,
        capaWebCaida: true,
        baseDatosCaida: true,
        mostrarNotaTeorica: true,
      ),
    );

    expect(find.text('CAÍDO'), findsNWidgets(2));
    expect(find.textContaining('Desborde: 120 %'), findsOneWidget);
    expect(find.textContaining('Desborde: 125 %'), findsOneWidget);
    expect(
      find.text('datos teóricos: el servidor ya estaría caído'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('se reordena en pantallas estrechas sin desbordarse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(montar(editable: true));

    expect(find.text('A → B · consultas'), findsOneWidget);
    expect(find.text('Entrada externa · c1·v1(t)'), findsOneWidget);
  });
}
