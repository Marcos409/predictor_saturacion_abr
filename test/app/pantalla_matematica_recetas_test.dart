import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:predictor_saturacion_abr/app/estado_aplicacion.dart';
import 'package:predictor_saturacion_abr/features/matematica/pantalla_matematica.dart';

import '../engine/configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> bombear(WidgetTester tester, String id) async {
    final estado = EstadoAplicacion(
      sistema: cargarSistema(),
      escenarios: cargarEscenarios(),
      solucionAnalitica: cargarSolucionAnalitica(),
    );
    addTearDown(estado.dispose);
    estado.seleccionarEscenario(id);

    await tester.binding.setSurfaceSize(const Size(1400, 2600));
    await tester.pumpWidget(
      ChangeNotifierProvider<EstadoAplicacion>.value(
        value: estado,
        child: const MaterialApp(home: Scaffold(body: PantallaMatematica())),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final id in ['lineal', 'constante', 'exponencial', 'ciclico']) {
    testWidgets('la pantalla muestra el paso a paso de $id', (tester) async {
      await bombear(tester, id);

      expect(find.textContaining('Fase 1 · Entrada de tráfico'), findsOneWidget);
      expect(find.textContaining('EDO:'), findsWidgets);
      expect(find.textContaining('V1(t) ='), findsWidgets);
      expect(
        find.textContaining('Fase 2 · EDO de segundo orden'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Fase 2 · Desarrollo de la solución'),
        findsOneWidget,
      );
      expect(find.textContaining('y_h(t) ='), findsOneWidget);
      expect(find.textContaining('y_p(t) ='), findsOneWidget);
      expect(find.textContaining('x(t) ='), findsWidgets);
      expect(find.textContaining('y(t) ='), findsWidgets);
      expect(find.textContaining("x'(t) ="), findsOneWidget);
      expect(find.textContaining("y'(t) ="), findsOneWidget);
      expect(find.textContaining('Sin discrepancia'), findsOneWidget);
    });
  }
}
