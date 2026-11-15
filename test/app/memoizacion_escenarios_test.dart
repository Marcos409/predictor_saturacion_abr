import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/estado_aplicacion.dart';

import '../engine/configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EstadoAplicacion crearEstado() => EstadoAplicacion(
    sistema: cargarSistema(),
    escenarios: cargarEscenarios(),
    solucionAnalitica: cargarSolucionAnalitica(),
  );

  ({double x, double t, double curva}) finalActivo(EstadoAplicacion estado) {
    final resultado = estado.resultado!;
    final ultimo = resultado.puntos.last;
    return (
      x: ultimo.x,
      t: ultimo.t,
      curva: estado.curvaEntradaActiva.last.valor,
    );
  }

  test('reutiliza los escenarios que no cambiaron', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final ciclico = estado.resultadoEscenario('ciclico');
    final lineal = estado.resultadoEscenario('lineal');

    estado.seleccionarEscenario('exponencial');

    expect(estado.idEscenarioActivo, 'exponencial');
    expect(identical(estado.resultadoEscenario('ciclico'), ciclico), isTrue);
    expect(identical(estado.resultadoEscenario('lineal'), lineal), isTrue);
  });

  test('solo invalida el escenario cuyo parámetro cambió', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    estado.seleccionarEscenario('exponencial');
    final lineal = estado.resultadoEscenario('lineal');
    final exponencial = estado.resultadoEscenario('exponencial');

    estado.actualizarParametroEscenario('r', 0.06);

    expect(identical(estado.resultadoEscenario('lineal'), lineal), isTrue);
    expect(
      identical(estado.resultadoEscenario('exponencial'), exponencial),
      isFalse,
    );
  });

  test('cambiar los parámetros del escenario altera el resultado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = finalActivo(estado);

    estado.actualizarParametroEscenario('m', 8);

    final despues = finalActivo(estado);
    expect(despues.x, isNot(closeTo(antes.x, 1e-9)));
    expect(despues.curva, isNot(closeTo(antes.curva, 1e-9)));
  });

  test('cambiar c1 altera el resultado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = finalActivo(estado);

    estado.actualizarC1(1.5);

    expect(finalActivo(estado).x, isNot(closeTo(antes.x, 1e-9)));
  });

  test('cambiar un caudal altera el resultado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = finalActivo(estado);

    estado.actualizarCaudal('A_a_B', 25);

    expect(finalActivo(estado).x, isNot(closeTo(antes.x, 1e-9)));
  });

  test('cambiar un volumen altera el resultado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = finalActivo(estado);

    estado.actualizarVolumen('volumen_A', 120);

    expect(finalActivo(estado).x, isNot(closeTo(antes.x, 1e-9)));
  });

  test('cambiar el modo de coeficientes no altera los valores derivados', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = finalActivo(estado);

    estado.cambiarModoCoeficientes('directo');

    expect(finalActivo(estado).x, closeTo(antes.x, 1e-9));
  });

  test('cambiar un coeficiente directo altera el resultado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    estado.cambiarModoCoeficientes('directo');
    final antes = finalActivo(estado);

    estado.actualizarCoeficienteDirecto('a11', -0.25);

    expect(finalActivo(estado).x, isNot(closeTo(antes.x, 1e-9)));
  });

  test('cambiar las condiciones iniciales altera el resultado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = finalActivo(estado);

    estado.actualizarCondicionInicial('x0', 5);
    estado.actualizarCondicionInicial('y0', 7);

    expect(finalActivo(estado).x, isNot(closeTo(antes.x, 1e-9)));
  });

  test('cambiar un límite adelanta el colapso sin alterar la simulación', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final colapsoAntes = estado.colapsoCapaWeb?.tiempo;
    final antes = finalActivo(estado);

    estado.actualizarLimite('limite_A', 50);

    final colapsoDespues = estado.colapsoCapaWeb?.tiempo;
    expect(colapsoAntes, isNotNull);
    expect(colapsoDespues, isNotNull);
    expect(colapsoDespues!, lessThan(colapsoAntes!));
    expect(finalActivo(estado).x, closeTo(antes.x, 1e-9));
  });

  test('cambiar el tiempo máximo altera el horizonte simulado', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);

    estado.actualizarTiempoMaxEscenario(40);

    expect(finalActivo(estado).t, closeTo(40, 1e-9));
  });

  test('cambiar el tiempo de reacción mueve la ventana de acción', () {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    final antes = estado.ventanaAccion?.ventanaAccion;

    estado.actualizarTiempoReaccion(15);

    final despues = estado.ventanaAccion?.ventanaAccion;
    expect(antes, isNotNull);
    expect(despues, isNotNull);
    expect(despues!, lessThan(antes!));
  });
}
