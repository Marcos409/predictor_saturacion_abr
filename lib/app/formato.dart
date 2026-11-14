String formatearNumero(double valor, {int decimales = 2}) {
  if (valor.isNaN || valor.isInfinite) return '—';
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  return valor.toStringAsFixed(decimales).replaceAll('.', ',');
}
