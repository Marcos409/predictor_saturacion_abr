import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/app.dart';
import 'package:predictor_saturacion_abr/app/estado_aplicacion.dart';

import 'engine/configuracion_prueba.dart';

EstadoAplicacion crearEstado() {
  return EstadoAplicacion(
    sistema: cargarSistema(),
    escenarios: cargarEscenarios(),
    solucionAnalitica: cargarSolucionAnalitica(),
  );
}

void main() {
  testWidgets('en escritorio muestra el perfil y navega entre módulos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    expect(find.text('Marcos Chavez'), findsOneWidget);
    expect(find.text('Ingeniero TI · NMiko'), findsOneWidget);
    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(find.text('COLAPSO CAPA WEB'), findsOneWidget);

    await tester.tap(find.text('Ver la matemática').first);
    await tester.pumpAndSettle();

    expect(find.text('Sistema de ecuaciones'), findsOneWidget);
    expect(find.text('Valores propios'), findsOneWidget);
  });

  testWidgets('en móvil la barra se abre como menú desplegable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    expect(find.text('Marcos Chavez'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Marcos Chavez'), findsOneWidget);
    expect(find.text('Ingeniero TI · NMiko'), findsOneWidget);
  });

  testWidgets('la pantalla de escenarios permite cambiar el escenario activo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    await tester.tap(find.text('Escenarios').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Elige el escenario de tráfico que alimenta la simulación.'),
      findsOneWidget,
    );
    expect(find.text('Lineal'), findsOneWidget);
    expect(find.text('Constante'), findsOneWidget);

    await tester.tap(find.text('Exponencial'));
    await tester.pumpAndSettle();

    expect(estado.idEscenarioActivo, 'exponencial');
    expect(find.text('Activo'), findsOneWidget);
  });

  testWidgets('la fase 1 edita parámetros y la fase 2 recalcula la vista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    await tester.tap(find.text('Fase 1 · Tráfico').first);
    await tester.pumpAndSettle();

    expect(find.text('Parámetros del escenario activo'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'm'), '8');
    await tester.pumpAndSettle();

    final parametroM = estado.escenarioActivo.parametros.firstWhere(
      (parametro) => parametro.clave == 'm',
    );
    expect(parametroM.valor, 8);

    await tester.tap(find.text('Fase 2 · Servidores').first);
    await tester.pumpAndSettle();

    expect(find.text('Vista previa del cálculo'), findsOneWidget);
    expect(find.text('Diagrama de tubos y flujos'), findsOneWidget);
    expect(find.text('COLAPSO CAPA WEB'), findsOneWidget);
    expect(find.text('VENTANA DE ACCIÓN'), findsOneWidget);
  });

  testWidgets('la simulación en vivo y las alertas reaccionan al escalado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    await tester.tap(find.text('Simulación en vivo').first);
    await tester.pumpAndSettle();

    expect(find.text('Controles de reproducción'), findsOneWidget);
    expect(find.text('Diagrama de tubos y flujos'), findsOneWidget);
    expect(find.text('Capa Web'), findsOneWidget);
    expect(find.text('Base de Datos'), findsOneWidget);
    expect(find.text('Reproducir'), findsOneWidget);

    await tester.tap(find.text('Alertas y Auto-Scaling').first);
    await tester.pumpAndSettle();

    expect(find.text('Modo de Auto-Scaling'), findsOneWidget);
    expect(find.text('Registro de eventos'), findsOneWidget);

    await tester.tap(find.text('Escalar Capa Web'));
    await tester.pumpAndSettle();

    expect(estado.escaladosWeb, 1);
    expect(find.textContaining('Escalado manual'), findsOneWidget);
  });

  testWidgets('al caer la Capa Web pausa y el modo teórico permite continuar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    await tester.tap(find.text('Simulación en vivo').first);
    await tester.pumpAndSettle();

    expect(estado.continuarTrasColapso, isFalse);

    await tester.tap(find.text('Reproducir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));

    expect(estado.capaWebCaida, isTrue);
    expect(estado.reproduciendo, isFalse);
    expect(estado.tiempoCaidaWeb, closeTo(6.86, 0.05));
    expect(estado.tiempoVivo, estado.tiempoCaidaWeb);

    final eventosCaida = estado.eventos.where(
      (evento) => evento.mensaje.startsWith('Capa Web caída'),
    );
    expect(eventosCaida, hasLength(1));
    expect(eventosCaida.first.minuto, estado.tiempoCaidaWeb);

    expect(find.textContaining('Servidor caído en el minuto'), findsOneWidget);
    expect(find.textContaining('Ventana de Acción:'), findsOneWidget);

    final interruptor = find.text(
      'Continuar después del colapso (modo teórico)',
    );
    await tester.ensureVisible(interruptor);
    await tester.tap(interruptor);
    await tester.pump();

    expect(estado.continuarTrasColapso, isTrue);

    final botonReproducir = find.text('Reproducir');
    await tester.ensureVisible(botonReproducir);
    await tester.tap(botonReproducir);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(estado.reproduciendo, isTrue);
    expect(estado.tiempoVivo, greaterThan(estado.tiempoCaidaWeb!));
    expect(
      find.text('datos teóricos: el servidor ya estaría caído'),
      findsWidgets,
    );

    estado.pausar();
    await tester.pump();
  });

  testWidgets('el Auto-Scaling previo al cruce evita marcar el colapso', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    estado.cambiarModoAutoScaling(ModoAutoScaling.automatico);
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    await tester.tap(find.text('Simulación en vivo').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reproducir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    expect(estado.escaladosWeb, greaterThan(0));
    expect(estado.tiempoVivo, greaterThan(6.86));
    expect(estado.capaWebCaida, isFalse);
    expect(estado.reproduciendo, isTrue);

    estado.pausar();
    await tester.pump();
  });

  testWidgets('dashboard, resultados y matemática muestran datos del motor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    expect(find.text('Evolución de los tanques'), findsOneWidget);

    await tester.tap(find.text('Resultados').first);
    await tester.pumpAndSettle();

    expect(find.text('Comparador de escenarios'), findsOneWidget);
    expect(find.text('Lectura del semáforo'), findsOneWidget);
    expect(find.text('Crítico'), findsWidgets);

    await tester.tap(find.text('Ver la matemática').first);
    await tester.pumpAndSettle();

    expect(find.text('Sistema de ecuaciones'), findsOneWidget);
    expect(find.text('Verificación cruzada'), findsOneWidget);
    expect(find.textContaining('Sin discrepancia'), findsOneWidget);
  });

  testWidgets('la configuración permite restaurar el caso base', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estado = crearEstado();
    addTearDown(estado.dispose);
    await tester.pumpWidget(AplicacionSaturacion(estado: estado));

    await tester.tap(find.text('Configuración (JSON)').first);
    await tester.pumpAndSettle();

    expect(find.text('Cargar JSON'), findsOneWidget);
    expect(find.text('Descargar configuración actual'), findsOneWidget);
    expect(find.text('Restaurar caso base'), findsOneWidget);
    expect(find.text('Configuración activa'), findsOneWidget);

    estado.actualizarParametroEscenario('m', 8);
    await tester.pump();

    await tester.tap(find.text('Restaurar caso base'));
    await tester.pumpAndSettle();

    expect(
      estado.escenarioActivo.parametros
          .firstWhere((parametro) => parametro.clave == 'm')
          .valor,
      5,
    );
    expect(find.textContaining('Caso base restaurado'), findsOneWidget);
  });
}
