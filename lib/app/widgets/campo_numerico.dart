import 'dart:async';

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
  final Duration retraso;
  final double? anchoMaximo;

  const CampoNumerico({
    super.key,
    required this.etiqueta,
    required this.valorInicial,
    required this.alCambiar,
    this.ayuda,
    this.sufijo,
    this.habilitado = true,
    this.retraso = const Duration(milliseconds: 300),
    this.anchoMaximo,
  });

  @override
  State<CampoNumerico> createState() => _CampoNumericoState();
}

class _CampoNumericoState extends State<CampoNumerico> {
  late final TextEditingController _controlador;
  late final FocusNode _foco;
  Timer? _temporizador;
  double? _valorPendiente;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(
      text: formatearNumero(widget.valorInicial),
    );
    _foco = FocusNode()..addListener(_alCambiarFoco);
  }

  @override
  void didUpdateWidget(covariant CampoNumerico oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.habilitado) {
      _temporizador?.cancel();
      _temporizador = null;
      _valorPendiente = null;
    }
    if (!_foco.hasFocus && widget.valorInicial != oldWidget.valorInicial) {
      _controlador.text = formatearNumero(widget.valorInicial);
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controlador.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _alCambiarFoco() {
    if (!_foco.hasFocus) _aplicarPendiente();
  }

  void _alEscribir(String texto) {
    _temporizador?.cancel();
    final normalizado = texto.replaceAll(',', '.').trim();
    final valor = double.tryParse(normalizado);
    if (valor == null) {
      if (_valorPendiente != null) {
        _valorPendiente = null;
        setState(() {});
      }
      return;
    }
    _valorPendiente = valor;
    if (widget.retraso == Duration.zero) {
      _aplicarPendiente();
      return;
    }
    setState(() {});
    _temporizador = Timer(widget.retraso, _aplicarPendiente);
  }

  void _aplicarPendiente() {
    _temporizador?.cancel();
    _temporizador = null;
    final valor = _valorPendiente;
    _valorPendiente = null;
    if (valor == null) {
      if (mounted) setState(() {});
      return;
    }
    if (valor != widget.valorInicial) widget.alCambiar(valor);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final campo = TextField(
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
      onSubmitted: (_) => _aplicarPendiente(),
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: AppColores.textoPrincipal, fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        helperText: widget.ayuda,
        helperMaxLines: 2,
        suffixText: widget.sufijo,
        suffixIcon: _valorPendiente == null
            ? null
            : const Padding(
                padding: EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: AppColores.primario,
                  ),
                ),
              ),
        labelStyle: const TextStyle(color: AppColores.textoSecundario),
        helperStyle: const TextStyle(
          color: AppColores.textoSecundario,
          fontSize: 11,
        ),
        suffixStyle: const TextStyle(color: AppColores.textoSecundario),
        filled: true,
        fillColor: AppColores.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColores.bordeControl),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColores.bordeControl),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColores.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColores.primario, width: 2),
        ),
      ),
    );

    final anchoMaximo = widget.anchoMaximo;
    if (anchoMaximo == null) return campo;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: campo,
    );
  }
}
