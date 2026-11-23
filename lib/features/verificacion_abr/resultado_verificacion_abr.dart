import '../../core/models/escenario_trafico.dart';
import '../../core/models/resultado_colapso.dart';
import '../../core/models/resultado_ventana_accion.dart';
import '../../core/models/sistema.dart';
import '../../core/models/solucion_general.dart';

enum EstadoComparacionAbr { coincide, difiere }

class FilaComparacionAbr {
  final String variable;
  final String ecuacionMotor;
  final String ecuacionReferencia;
  final double? errorMaximo;
  final EstadoComparacionAbr? estado;
  final bool referenciaPendiente;

  const FilaComparacionAbr({
    required this.variable,
    required this.ecuacionMotor,
    required this.ecuacionReferencia,
    this.errorMaximo,
    this.estado,
    this.referenciaPendiente = false,
  });

  bool get coincide => estado == EstadoComparacionAbr.coincide;
}

class ResultadoVerificacionAbr {
  final EscenarioTrafico escenario;
  final ConfiguracionSistema configuracion;
  final SolucionGeneral solucion;
  final String edoFase1;
  final String metodoFase1;
  final String expresionV1;
  final String expresionXPrima;
  final String expresionYPrima;
  final String expresionYc;
  final String expresionYp;
  final double? c1Homogenea;
  final double? c2Homogenea;
  final ResultadoColapso colapsoWeb;
  final ResultadoColapso colapsoBd;
  final ResultadoVentanaAccion ventana;
  final String limiteX;
  final String limiteY;
  final List<FilaComparacionAbr> comparacion;
  final String? notaComparacion;
  final double horizonteMin;
  final bool traficoNegativoEnHorizonte;
  final double traficoMinimoEnHorizonte;

  const ResultadoVerificacionAbr({
    required this.escenario,
    required this.configuracion,
    required this.solucion,
    required this.edoFase1,
    required this.metodoFase1,
    required this.expresionV1,
    required this.expresionXPrima,
    required this.expresionYPrima,
    required this.expresionYc,
    required this.expresionYp,
    required this.c1Homogenea,
    required this.c2Homogenea,
    required this.colapsoWeb,
    required this.colapsoBd,
    required this.ventana,
    required this.limiteX,
    required this.limiteY,
    required this.comparacion,
    required this.notaComparacion,
    required this.horizonteMin,
    required this.traficoNegativoEnHorizonte,
    required this.traficoMinimoEnHorizonte,
  });
}
