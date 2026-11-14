import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/estado_aplicacion.dart';
import '../../app/tema.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/grafico_curva.dart';
import '../../app/widgets/mensaje_error.dart';
import '../../core/models/escenario_trafico.dart';
import '../../core/models/punto_entrada.dart';

class PantallaEscenarios extends StatelessWidget {
  const PantallaEscenarios({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoPantalla(
              titulo: 'Escenarios',
              descripcion:
                  'Elige el escenario de tráfico que alimenta la simulación.',
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, restricciones) {
                final columnas = restricciones.maxWidth >= 1180
                    ? 4
                    : restricciones.maxWidth >= 720
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: estado.escenarios.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnas,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 242,
                  ),
                  itemBuilder: (context, indice) {
                    final escenario = estado.escenarios[indice];
                    return _TarjetaEscenario(
                      escenario: escenario,
                      activa: escenario.id == estado.idEscenarioActivo,
                      curva: estado.curvaEscenario(escenario.id),
                      alSeleccionar: () => context
                          .read<EstadoAplicacion>()
                          .seleccionarEscenario(escenario.id),
                    );
                  },
                );
              },
            ),
            if (estado.error != null) ...[
              const SizedBox(height: 16),
              MensajeError(mensaje: estado.error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaEscenario extends StatelessWidget {
  final EscenarioTrafico escenario;
  final bool activa;
  final List<PuntoEntrada> curva;
  final VoidCallback alSeleccionar;

  const _TarjetaEscenario({
    required this.escenario,
    required this.activa,
    required this.curva,
    required this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: alSeleccionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: activa
                ? ColoresApp.acento.withValues(alpha: 0.08)
                : ColoresApp.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activa ? ColoresApp.acento : ColoresApp.borde,
              width: activa ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      escenario.nombre,
                      style: const TextStyle(
                        color: ColoresApp.textoPrimario,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (activa) const _EtiquetaActivo(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                escenario.edo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'v1(t) = ${escenario.expresionV1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ColoresApp.acento, fontSize: 12),
              ),
              const Spacer(),
              GraficoCurva(
                puntos: curva,
                altura: 66,
                color: activa
                    ? ColoresApp.acento
                    : ColoresApp.acento.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtiquetaActivo extends StatelessWidget {
  const _EtiquetaActivo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColoresApp.acento.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Activo',
        style: TextStyle(
          color: ColoresApp.acento,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
