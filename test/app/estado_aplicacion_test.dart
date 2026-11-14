import 'package:flutter_test/flutter_test.dart';
import 'package:predictor_saturacion_abr/app/estado_aplicacion.dart';
import 'package:predictor_saturacion_abr/app/evento_simulacion.dart';
import 'package:predictor_saturacion_abr/app/semaforo.dart';
import 'package:predictor_saturacion_abr/core/models/sistema.dart';
import 'package:predictor_saturacion_abr/core/models/solucion_analitica.dart';

import '../engine/configuracion_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EstadoAplicacion estado;

  setUp(() {
    estado = EstadoAplicacion(
      sistema: cargarSistema(),
      escenarios: cargarEscenarios(),
      solucionAnalitica: cargarSolucionAnalitica(),
    );
  });

  tearDown(() => estado.dispose());

  test('al construirse calcula el resultado y las curvas de entrada', () {
    expect(estado.error, isNull);
    expect(estado.resultado, isNotNull);
    expect(estado.curvaEntradaActiva, isNotEmpty);
    expect(estado.colapsoCapaWeb?.tiempo, closeTo(6.87, 0.1));
    expect(estado.colapsoBaseDatos?.tiempo, closeTo(24.97, 0.1));
  });

  test('actualizar un parámetro del escenario recalcula la entrada', () {
    final valorAntes = estado.curvaEntradaActiva.last.valor;

    estado.actualizarParametroEscenario('m', 8);

    final valorDespues = estado.curvaEntradaActiva.last.valor;
    final parametro = estado.escenarioActivo.parametros.firstWhere(
      (parametro) => parametro.clave == 'm',
    );
    expect(parametro.valor, 8);
    expect(valorDespues, greaterThan(valorAntes));
  });

  test('seleccionar un escenario cambia la curva y el resultado', () {
    final colapsoLineal = estado.colapsoCapaWeb?.tiempo;

    estado.seleccionarEscenario('exponencial');

    expect(estado.idEscenarioActivo, 'exponencial');
    expect(estado.escenarioActivo.nombre, 'Exponencial');
    expect(estado.curvaEntradaActiva, isNotEmpty);
    expect(estado.curvaEntradaActiva.last.valor, isNot(closeTo(0, 1e-9)));
    expect(estado.colapsoCapaWeb?.tiempo, isNot(equals(colapsoLineal)));
  });

  test('actualizar el límite de la base de datos adelanta su colapso', () {
    final colapsoAntes = estado.colapsoBaseDatos?.tiempo;

    estado.actualizarLimite('limite_B', 50);

    final colapsoDespues = estado.colapsoBaseDatos?.tiempo;
    expect(colapsoAntes, isNotNull);
    expect(colapsoDespues, isNotNull);
    expect(colapsoDespues!, lessThan(colapsoAntes!));
  });

  test('calcula los cuatro escenarios y la verificación cruzada', () {
    expect(estado.escenarios.length, 4);
    for (final escenario in estado.escenarios) {
      expect(estado.resultadoEscenario(escenario.id), isNotNull);
      expect(estado.colapsoWebEscenario(escenario.id), isNotNull);
      expect(estado.colapsoBaseDatosEscenario(escenario.id), isNotNull);
      expect(estado.ventanaEscenario(escenario.id), isNotNull);
    }
    expect(estado.verificacion, isNotNull);
    expect(estado.verificacion!.hayDiscrepancia, isFalse);
    expect(estado.nivelSemaforo, NivelSemaforo.critico);
  });

  test('calcula las derivadas iniciales y los límites del sistema', () {
    expect(estado.derivadaXInicial, closeTo(10, 1e-9));
    expect(estado.derivadaYInicial, closeTo(0, 1e-9));
    expect(estado.entradaInicial, closeTo(10, 1e-9));
  });

  test('escalar manualmente sube la capacidad y registra el evento', () {
    final capacidadBase = estado.sistema.capacidades.capaWeb;

    estado.escalar('capa_web');

    expect(estado.escaladosWeb, 1);
    expect(
      estado.capacidadWebEfectiva,
      capacidadBase + estado.sistema.autoScaling.incrementoCapacidad,
    );
    expect(estado.eventos, isNotEmpty);
    expect(estado.eventos.last.tipo, TipoEventoSimulacion.escalado);

    estado.escalar('base_datos');
    expect(estado.escaladosBaseDatos, 1);
  });

  test('la capacidad efectiva pospone el colapso de la Capa Web', () {
    final colapsoAntes = estado.colapsoCapaWeb?.tiempo;
    expect(colapsoAntes, isNotNull);

    estado.escalar('capa_web');

    final colapsoDespues = estado.colapsoCapaWeb?.tiempo;
    expect(colapsoDespues, isNotNull);
    expect(colapsoDespues!, greaterThan(colapsoAntes!));
  });

  test('el modo teórico está apagado por defecto y es conmutable', () {
    expect(estado.continuarTrasColapso, isFalse);
    expect(estado.capaWebCaida, isFalse);
    expect(estado.baseDatosCaida, isFalse);

    estado.cambiarContinuarTrasColapso(true);

    expect(estado.continuarTrasColapso, isTrue);
    expect(estado.eventos.last.mensaje, contains('Modo teórico activado'));
  });

  test('reiniciar devuelve la simulación al inicio y limpia los escalados', () {
    estado.escalar('capa_web');
    estado.cambiarModoAutoScaling(ModoAutoScaling.automatico);

    estado.reiniciar();

    expect(estado.tiempoVivo, 0);
    expect(estado.reproduciendo, isFalse);
    expect(estado.escaladosWeb, 0);
    expect(estado.escaladosBaseDatos, 0);
    expect(estado.eventos, isEmpty);
    expect(estado.modoAutoScaling, ModoAutoScaling.automatico);
  });

  test('reemplazar la configuración aplica los valores y reinicia', () {
    estado.escalar('capa_web');
    final sistemaNuevo = cargarSistema().copyWith(umbralAlerta: 0.8);

    estado.reemplazarConfiguracion(
      sistema: sistemaNuevo,
      escenarios: cargarEscenarios(),
      solucionAnalitica: cargarSolucionAnalitica(),
    );

    expect(estado.sistema.umbralAlerta, 0.8);
    expect(estado.tiempoVivo, 0);
    expect(estado.escaladosWeb, 0);
    expect(estado.eventos, isEmpty);
    expect(estado.configuracionEscenarios.escenarios.length, 4);
  });

  test('rechaza una solución analítica inválida sin alterar el estado', () {
    estado.actualizarParametroEscenario('m', 8);
    final solucionInvalida = const SolucionAnalitica(
      version: 1,
      unidadTiempo: 'min',
      variable: 't',
      expresionX: 'exp(',
      expresionY: '0',
    );

    expect(
      () => estado.reemplazarConfiguracion(
        sistema: cargarSistema().copyWith(umbralAlerta: 0.8),
        escenarios: cargarEscenarios(),
        solucionAnalitica: solucionInvalida,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(estado.sistema.umbralAlerta, 0.7);
    expect(
      estado.escenarioActivo.parametros
          .firstWhere((parametro) => parametro.clave == 'm')
          .valor,
      8,
    );
  });

  test('rechaza una configuración con una unidad de tiempo distinta', () {
    final base = cargarSistema();
    final sistemaHoras = ConfiguracionSistema(
      version: base.version,
      unidadTiempo: 'h',
      tanques: base.tanques,
      condicionesIniciales: base.condicionesIniciales,
      umbralAlerta: base.umbralAlerta,
      simulacion: base.simulacion,
      autoScaling: base.autoScaling,
      verificacion: base.verificacion,
      semaforo: base.semaforo,
    );

    expect(
      () => estado.reemplazarConfiguracion(
        sistema: sistemaHoras,
        escenarios: cargarEscenarios(),
        solucionAnalitica: cargarSolucionAnalitica(),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(estado.sistema.unidadTiempo, 'min');
  });

  test('restaurar el caso base recupera los valores originales', () async {
    estado.actualizarParametroEscenario('m', 8);
    estado.actualizarLimite('limite_A', 150);

    await estado.restaurarCasoBase();

    expect(
      estado.escenarioActivo.parametros
          .firstWhere((parametro) => parametro.clave == 'm')
          .valor,
      5,
    );
    expect(estado.sistema.capacidades.capaWeb, 100);
    expect(estado.sistema.umbralAlerta, 0.7);
  });
}
