import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'modulos.dart';
import 'sesion.dart';
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
      width: 240,
      color: AppColores.primario,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PerfilUsuario(),
            const Divider(height: 1, color: AppColores.primarioOscuro),
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
            Container(
              color: AppColores.primarioOscuro,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'TI-Saturation Predictor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColores.sobrePrimario,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
    final usuario = context.watch<Sesion>().usuario;

    return Container(
      color: AppColores.primarioOscuro,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColores.superficie,
                child: Text(
                  usuario?.iniciales ?? '?',
                  style: const TextStyle(
                    color: AppColores.primarioOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario?.nombre ?? 'Sesión',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColores.sobrePrimario,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario?.rol ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColores.sobrePrimario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _BotonCerrarSesion(),
        ],
      ),
    );
  }
}

class _BotonCerrarSesion extends StatelessWidget {
  const _BotonCerrarSesion();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.read<Sesion>().cerrarSesion(),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: AppColores.sobrePrimario,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(44, 40),
      ),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text(
        'Cerrar sesión',
        style: TextStyle(
          color: AppColores.sobrePrimario,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: seleccionado
            ? AppColores.primarioOscuro
            : AppColores.transparente,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColores.primarioOscuro.withValues(alpha: 0.55),
          splashColor: AppColores.sobrePrimario.withValues(alpha: 0.12),
          onTap: alPresionar,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(modulo.icono, size: 20, color: AppColores.sobrePrimario),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    modulo.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColores.sobrePrimario,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
