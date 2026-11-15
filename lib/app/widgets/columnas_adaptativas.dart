import 'package:flutter/material.dart';

/// Reparte tarjetas en columnas apiladas (tipo masonry).
///
/// Cada columna es una [Column] con la altura natural de sus tarjetas: no se
/// fuerza la misma altura entre columnas, así se evitan los huecos grandes
/// cuando una tarjeta es corta y la de al lado es larga.
///
/// El número de columnas depende del ancho disponible:
/// - 3 columnas si el ancho es mayor o igual a 1100 px.
/// - 2 columnas si el ancho está entre 700 y 1099 px.
/// - 1 columna si el ancho es menor de 700 px.
class ColumnasAdaptativas extends StatelessWidget {
  static const double anchoTresColumnas = 1100;
  static const double anchoDosColumnas = 700;

  /// Distribución en tres columnas (orden natural de lectura).
  final List<List<Widget>> columnas;

  /// Distribución en dos columnas. Si es nula se usa [columnas].
  final List<List<Widget>>? columnasDos;

  /// Orden para una sola columna. Si es nulo se aplana [columnas].
  final List<Widget>? columnaUnica;

  final double separacion;
  final double separacionVertical;

  const ColumnasAdaptativas({
    super.key,
    required this.columnas,
    this.columnasDos,
    this.columnaUnica,
    this.separacion = 20,
    this.separacionVertical = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        if (ancho >= anchoTresColumnas && columnas.length > 1) {
          return _fila(columnas);
        }
        final dosColumnas = columnasDos ?? columnas;
        if (ancho >= anchoDosColumnas && dosColumnas.length > 1) {
          return _fila(dosColumnas);
        }
        final items = columnaUnica ?? [for (final grupo in columnas) ...grupo];
        return _apilado(items);
      },
    );
  }

  Widget _fila(List<List<Widget>> grupos) {
    final hijos = <Widget>[];
    for (var i = 0; i < grupos.length; i++) {
      if (i > 0) hijos.add(SizedBox(width: separacion));
      hijos.add(Expanded(child: _apilado(grupos[i])));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: hijos);
  }

  Widget _apilado(List<Widget> items) {
    final hijos = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) hijos.add(SizedBox(height: separacionVertical));
      hijos.add(items[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: hijos,
    );
  }
}
