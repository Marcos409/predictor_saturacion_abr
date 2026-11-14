import 'package:flutter/material.dart';

import 'modulos.dart';
import 'tema.dart';

class BarraLateral extends StatelessWidget {
  final int indiceSeleccionado;
  final ValueChanged<int> alSeleccionar;

  const BarraLateral({
    super.key,
    required this.indiceSeleccionado,
    required this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: ColoresApp.panel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PerfilUsuario(),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: modulosApp.length,
                itemBuilder: (context, indice) {
                  return _ItemMenu(
                    modulo: modulosApp[indice],
                    seleccionado: indice == indiceSeleccionado,
                    alPresionar: () => alSeleccionar(indice),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'TI-Saturation Predictor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerfilUsuario extends StatelessWidget {
  const _PerfilUsuario();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ColoresApp.acento,
            child: Text(
              'MC',
              style: TextStyle(
                color: ColoresApp.fondo,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marcos Chavez',
                  style: TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ingeniero TI · NMiko',
                  style: TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final ModuloApp modulo;
  final bool seleccionado;
  final VoidCallback alPresionar;

  const _ItemMenu({
    required this.modulo,
    required this.seleccionado,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    final colorIcono = seleccionado
        ? ColoresApp.acento
        : ColoresApp.textoSecundario;
    final colorTexto = seleccionado
        ? ColoresApp.textoPrimario
        : ColoresApp.textoSecundario;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: seleccionado
            ? ColoresApp.acento.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: alPresionar,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(modulo.icono, size: 20, color: colorIcono),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    modulo.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: 14,
                      fontWeight: seleccionado
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
