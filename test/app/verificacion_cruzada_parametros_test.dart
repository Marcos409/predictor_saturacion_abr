import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/estado_aplicacion.dart';
import 'package:predictor_saturacion_abr/core/models/resultado_verificacion.dart';

import '../engine/configuracion_prueba.dart';

EstadoAplicacion crearEstado() {
  return EstadoAplicacion(
    sistema: cargarSistema(),
    escenarios: cargarEscenarios(),
    solucionAnalitica: cargarSolucionAnalitica(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void comprobar(String nombre, void Function(EstadoAplicacion) aplicar) {
    final estado = crearEstado();
    addTearDown(estado.dispose);
    aplicar(estado);

    final verificacion = estado.verificacion;
    expect(verificacion, isNotNull, reason: nombre);
    expect(
      verificacion!.estado,
      EstadoVerificacion.coincide,
      reason: '${verificacion.motivoNoDisponible ?? ''} en $nombre',
    );
    expect(verificacion.errorRelativo, lessThan(1e-6), reason: nombre);
    expect(estado.solucionGeneralActiva, isNotNull, reason: nombre);
  }

  test('cambiar P0, q, r, periodo y dP0 mantiene la coincidencia', () {
    final casos = <(String, String, Map<String, double>, double?)>[
      ('constante · P0', 'constante', {'P0': 750}, null),
      ('exponencial · P0 y q', 'exponencial', {'P0': 35, 'b': -6}, null),
      ('exponencial · r = -0.5', 'exponencial', {'r': -0.5}, null),
      (
        'cíclico · periodo 60',
        'ciclico',
        {'P0': 25, 'dP0': -15, 'periodo_min': 60},
        240,
      ),
      (
        'cíclico · periodo 720',
        'ciclico',
        {'P0': 25, 'dP0': -15, 'periodo_min': 720},
        1440,
      ),
    ];

    for (final caso in casos) {
      comprobar(caso.$1, (estado) {
        estado.seleccionarEscenario(caso.$2);
        for (final entrada in caso.$3.entries) {
          estado.actualizarParametroEscenario(entrada.key, entrada.value);
        }
        if (caso.$4 != null) {
          estado.actualizarTiempoMaxEscenario(caso.$4!);
        }
      });
    }
  });

  test('cambiar c1, caudal y condiciones iniciales en escenarios nuevos', () {
    for (final id in ['constante', 'exponencial', 'ciclico']) {
      comprobar('$id con sistema modificado', (estado) {
        estado.seleccionarEscenario(id);
        estado.actualizarC1(1.5);
        estado.actualizarCaudal('A_a_B', 25);
        estado.actualizarCondicionInicial('x0', 3);
        estado.actualizarCondicionInicial('y0', 4);
        if (id == 'ciclico') estado.actualizarTiempoMaxEscenario(240);
      });
    }
  });
}
