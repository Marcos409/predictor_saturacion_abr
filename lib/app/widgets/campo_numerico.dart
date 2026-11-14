import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formato.dart';
import '../tema.dart';

class CampoNumerico extends StatefulWidget {
  final String etiqueta;
  final double valorInicial;
  final ValueChanged<double> alCambiar;
  final String? ayuda;
  final String? sufijo;
  final bool habilitado;

  const CampoNumerico({
    super.key,
    required this.etiqueta,
    required this.valorInicial,
    required this.alCambiar,
    this.ayuda,
    this.sufijo,
    this.habilitado = true,
  });

  @override
  State<CampoNumerico> createState() => _CampoNumericoState();
}

class _CampoNumericoState extends State<CampoNumerico> {
  late final TextEditingController _controlador;
  late final FocusNode _foco;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(
      text: formatearNumero(widget.valorInicial),
    );
    _foco = FocusNode();
  }

  @override
  void didUpdateWidget(covariant CampoNumerico oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_foco.hasFocus && widget.valorInicial != oldWidget.valorInicial) {
      _controlador.text = formatearNumero(widget.valorInicial);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    final normalizado = texto.replaceAll(',', '.').trim();
    final valor = double.tryParse(normalizado);
    if (valor != null) widget.alCambiar(valor);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controlador,
      focusNode: _foco,
      enabled: widget.habilitado,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
      ],
      onChanged: _alEscribir,
      style: const TextStyle(color: ColoresApp.textoPrimario, fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        helperText: widget.ayuda,
        helperMaxLines: 2,
        suffixText: widget.sufijo,
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        helperStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
          fontSize: 11,
        ),
        suffixStyle: const TextStyle(color: ColoresApp.textoSecundario),
        filled: true,
        fillColor: ColoresApp.fondo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.bordeControl),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.bordeControl),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.acento, width: 1.4),
        ),
      ),
    );
  }
}
