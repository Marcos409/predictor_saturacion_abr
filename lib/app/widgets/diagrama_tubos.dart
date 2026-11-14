import 'package:flutter/material.dart';

import '../../core/models/flujos_tubos.dart';
import '../../core/models/sistema.dart';
import '../formato.dart';
import '../tema.dart';
import 'campo_numerico.dart';

class DatosDiagramaTubos {
  final ConfiguracionSistema sistema;
  final double tiempo;
  final double x;
  final double y;
  final double entradaExterna;
  final double capacidadA;
  final double capacidadB;
  final double umbralAlerta;
  final bool capaWebCaida;
  final bool baseDatosCaida;
  final bool mostrarNotaTeorica;

  const DatosDiagramaTubos({
    required this.sistema,
    required this.tiempo,
    required this.x,
    required this.y,
    required this.entradaExterna,
    required this.capacidadA,
    required this.capacidadB,
    required this.umbralAlerta,
    this.capaWebCaida = false,
    this.baseDatosCaida = false,
    this.mostrarNotaTeorica = false,
  });
}

class DiagramaTubos extends StatelessWidget {
  final DatosDiagramaTubos datos;
  final bool editable;
  final void Function(String clave, double valor)? alCambiarCaudal;
  final void Function(String clave, double valor)? alCambiarVolumen;
  final bool mostrarTabla;

  const DiagramaTubos({
    super.key,
    required this.datos,
    this.editable = false,
    this.alCambiarCaudal,
    this.alCambiarVolumen,
    this.mostrarTabla = true,
  });

  @override
  Widget build(BuildContext context) {
    final flujos = FlujosTubos.calcular(
      sistema: datos.sistema,
      x: datos.x,
      y: datos.y,
      entradaExterna: datos.entradaExterna,
    );
    final caudales = datos.sistema.tanques.caudales;
    final maximo = flujos.flujoMaximo;
    final esDerivado = datos.sistema.tanques.modoCoeficientes == 'derivado';

    _Tubo tubo({
      required String nombre,
      required String? clave,
      required double? caudal,
      required double? flujo,
      required _Direccion direccion,
    }) {
      return _Tubo(
        nombre: nombre,
        clave: clave,
        caudal: caudal,
        flujo: flujo ?? 0,
        hayDesglose: flujos.hayDesglose,
        grosor: _grosor(flujo ?? 0, maximo),
        direccion: direccion,
        editable: editable && esDerivado,
        alCambiar: alCambiarCaudal,
      );
    }

    final entradaTubo = _Tubo(
      nombre: 'Entrada externa · c1·v1(t)',
      clave: null,
      caudal: null,
      flujo: datos.entradaExterna,
      hayDesglose: true,
      grosor: _grosor(datos.entradaExterna, maximo),
      direccion: _Direccion.abajo,
      editable: false,
      alCambiar: null,
      textoEntrada: 'c1·v1(t) = ${formatearNumero(datos.entradaExterna)}',
    );

    final tuboAB = tubo(
      nombre: 'A → B · consultas',
      clave: 'A_a_B',
      caudal: caudales.aAB,
      flujo: flujos.aAB,
      direccion: _Direccion.derecha,
    );
    final tuboBAA = tubo(
      nombre: 'B → A · caché (retorno)',
      clave: 'B_a_A',
      caudal: caudales.bAA,
      flujo: flujos.bAA,
      direccion: _Direccion.izquierda,
    );
    final tuboASalida = tubo(
      nombre: 'A · salida (rate limiting)',
      clave: 'A_salida',
      caudal: caudales.aSalida,
      flujo: flujos.aSalida,
      direccion: _Direccion.abajo,
    );
    final tuboBSalida = tubo(
      nombre: 'B · salida',
      clave: 'B_salida',
      caudal: caudales.bSalida,
      flujo: flujos.bSalida,
      direccion: _Direccion.abajo,
    );

    final tanqueA = _NodoTanque(
      titulo: 'Tanque A',
      subtitulo: 'Capa Web · x(t)',
      nivel: datos.x,
      capacidad: datos.capacidadA,
      umbral: datos.umbralAlerta,
      etiquetaVolumen: 'volumen_A',
      volumen: datos.sistema.tanques.volumenA,
      caido: datos.capaWebCaida,
      mostrarNotaTeorica: datos.mostrarNotaTeorica,
      editable: editable && esDerivado,
      alCambiarVolumen: alCambiarVolumen,
    );
    final tanqueB = _NodoTanque(
      titulo: 'Tanque B',
      subtitulo: 'Base de Datos · y(t)',
      nivel: datos.y,
      capacidad: datos.capacidadB,
      umbral: datos.umbralAlerta,
      etiquetaVolumen: 'volumen_B',
      volumen: datos.sistema.tanques.volumenB,
      caido: datos.baseDatosCaida,
      mostrarNotaTeorica: datos.mostrarNotaTeorica,
      editable: editable && esDerivado,
      alCambiarVolumen: alCambiarVolumen,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instante t = ${formatearNumero(datos.tiempo)} min '
          '· ${esDerivado ? 'modo derivado (desglose por tubo)' : 'modo directo (solo balance neto)'}',
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, restricciones) {
            if (restricciones.maxWidth >= 660) {
              return _DiagramaHorizontal(
                entrada: entradaTubo,
                tanqueA: tanqueA,
                tanqueB: tanqueB,
                tuboAB: tuboAB,
                tuboBAA: tuboBAA,
                tuboASalida: tuboASalida,
                tuboBSalida: tuboBSalida,
              );
            }
            return _DiagramaVertical(
              entrada: entradaTubo,
              tanqueA: tanqueA,
              tanqueB: tanqueB,
              tuboAB: tuboAB,
              tuboBAA: tuboBAA,
              tuboASalida: tuboASalida,
              tuboBSalida: tuboBSalida,
            );
          },
        ),
        if (mostrarTabla) ...[
          const SizedBox(height: 18),
          _TablaEntraSale(flujos: flujos),
        ],
      ],
    );
  }

  double _grosor(double flujo, double maximo) {
    if (maximo <= 1e-9) return 2;
    return 2 + 8 * (flujo.abs() / maximo).clamp(0.0, 1.0);
  }
}

class _DiagramaHorizontal extends StatelessWidget {
  final Widget entrada;
  final Widget tanqueA;
  final Widget tanqueB;
  final Widget tuboAB;
  final Widget tuboBAA;
  final Widget tuboASalida;
  final Widget tuboBSalida;

  const _DiagramaHorizontal({
    required this.entrada,
    required this.tanqueA,
    required this.tanqueB,
    required this.tuboAB,
    required this.tuboBAA,
    required this.tuboASalida,
    required this.tuboBSalida,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: entrada),
            const SizedBox(width: 190),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tanqueA),
            SizedBox(
              width: 190,
              child: Column(
                children: [tuboAB, const SizedBox(height: 16), tuboBAA],
              ),
            ),
            Expanded(child: tanqueB),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tuboASalida),
            const SizedBox(width: 190),
            Expanded(child: tuboBSalida),
          ],
        ),
      ],
    );
  }
}

class _DiagramaVertical extends StatelessWidget {
  final Widget entrada;
  final Widget tanqueA;
  final Widget tanqueB;
  final Widget tuboAB;
  final Widget tuboBAA;
  final Widget tuboASalida;
  final Widget tuboBSalida;

  const _DiagramaVertical({
    required this.entrada,
    required this.tanqueA,
    required this.tanqueB,
    required this.tuboAB,
    required this.tuboBAA,
    required this.tuboASalida,
    required this.tuboBSalida,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        entrada,
        const SizedBox(height: 12),
        tanqueA,
        const SizedBox(height: 12),
        tuboAB,
        const SizedBox(height: 12),
        tuboBAA,
        const SizedBox(height: 12),
        tuboASalida,
        const SizedBox(height: 12),
        tanqueB,
        const SizedBox(height: 12),
        tuboBSalida,
      ],
    );
  }
}

enum _Direccion { derecha, izquierda, abajo }

class _NodoTanque extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final double nivel;
  final double capacidad;
  final double umbral;
  final String etiquetaVolumen;
  final double volumen;
  final bool caido;
  final bool mostrarNotaTeorica;
  final bool editable;
  final void Function(String clave, double valor)? alCambiarVolumen;

  const _NodoTanque({
    required this.titulo,
    required this.subtitulo,
    required this.nivel,
    required this.capacidad,
    required this.umbral,
    required this.etiquetaVolumen,
    required this.volumen,
    required this.caido,
    required this.mostrarNotaTeorica,
    required this.editable,
    required this.alCambiarVolumen,
  });

  @override
  Widget build(BuildContext context) {
    final fraccionReal = capacidad <= 0 ? 0.0 : nivel / capacidad;
    final fraccion = fraccionReal.clamp(0.0, 1.0);
    final porcentaje = fraccionReal <= 0 ? 0.0 : fraccionReal * 100;
    final desborde = capacidad > 0 && nivel > capacidad;
    final estado = caido
        ? 'CAÍDO'
        : capacidad > 0 && nivel >= capacidad
        ? 'Crítico'
        : capacidad > 0 && nivel >= umbral * capacidad
        ? 'Aviso'
        : 'Normal';
    final colorEstado = caido || desborde
        ? ColoresApp.alerta
        : switch (estado) {
            'Crítico' => ColoresApp.alerta,
            'Aviso' => ColoresApp.aviso,
            _ => ColoresApp.ok,
          };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorEstado.withValues(alpha: 0.7),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatearNumero(nivel),
            style: TextStyle(
              color: caido || desborde
                  ? ColoresApp.alerta
                  : ColoresApp.textoPrimario,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: fraccion,
              backgroundColor: ColoresApp.panel,
              color: colorEstado,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Límite crítico: ${formatearNumero(capacidad)}',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 11,
            ),
          ),
          if (desborde)
            Text(
              'Desborde: ${formatearNumero(porcentaje, decimales: 0)} %',
              style: const TextStyle(
                color: ColoresApp.alerta,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (mostrarNotaTeorica && caido)
            const Text(
              'datos teóricos: el servidor ya estaría caído',
              style: TextStyle(
                color: ColoresApp.alerta,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 8),
          if (editable && alCambiarVolumen != null)
            CampoNumerico(
              etiqueta: etiquetaVolumen,
              valorInicial: volumen,
              alCambiar: (valor) => alCambiarVolumen!(etiquetaVolumen, valor),
            )
          else
            Text(
              '$etiquetaVolumen = ${formatearNumero(volumen)}',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tubo extends StatelessWidget {
  final String nombre;
  final String? clave;
  final double? caudal;
  final double flujo;
  final bool hayDesglose;
  final double grosor;
  final _Direccion direccion;
  final bool editable;
  final void Function(String clave, double valor)? alCambiar;
  final String? textoEntrada;

  const _Tubo({
    required this.nombre,
    required this.clave,
    required this.caudal,
    required this.flujo,
    required this.hayDesglose,
    required this.grosor,
    required this.direccion,
    required this.editable,
    required this.alCambiar,
    this.textoEntrada,
  });

  @override
  Widget build(BuildContext context) {
    final color = flujo.abs() > 1e-9
        ? ColoresApp.acento
        : ColoresApp.textoSecundario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          width: double.infinity,
          child: _Flecha(direccion: direccion, grosor: grosor, color: color),
        ),
        const SizedBox(height: 6),
        _valor(context),
      ],
    );
  }

  Widget _valor(BuildContext context) {
    if (textoEntrada != null) {
      return Text(
        textoEntrada!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 11),
      );
    }
    if (editable && alCambiar != null && clave != null) {
      return CampoNumerico(
        etiqueta: 'caudal · $clave',
        valorInicial: caudal ?? 0,
        alCambiar: (valor) => alCambiar!(clave!, valor),
      );
    }
    if (!hayDesglose) {
      return Text(
        'caudal ${formatearNumero(caudal ?? 0)} (referencia)',
        textAlign: TextAlign.center,
        style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 11),
      );
    }
    return Text(
      'caudal ${formatearNumero(caudal ?? 0)} · flujo ${formatearNumero(flujo)}',
      textAlign: TextAlign.center,
      style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 11),
    );
  }
}

class _Flecha extends StatelessWidget {
  final _Direccion direccion;
  final double grosor;
  final Color color;

  const _Flecha({
    required this.direccion,
    required this.grosor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _PintorFlecha(
          direccion: direccion,
          grosor: grosor,
          color: color,
        ),
      ),
    );
  }
}

class _PintorFlecha extends CustomPainter {
  final _Direccion direccion;
  final double grosor;
  final Color color;

  const _PintorFlecha({
    required this.direccion,
    required this.grosor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final trazo = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final relleno = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const cabeza = 12.0;

    switch (direccion) {
      case _Direccion.derecha:
        final y = size.height / 2;
        canvas.drawLine(Offset(0, y), Offset(size.width - cabeza, y), trazo);
        _cabeza(
          canvas,
          Offset(size.width, y),
          const Offset(-1, 0),
          cabeza,
          relleno,
        );
      case _Direccion.izquierda:
        final y = size.height / 2;
        canvas.drawLine(Offset(size.width, y), Offset(cabeza, y), trazo);
        _cabeza(canvas, Offset(0, y), const Offset(1, 0), cabeza, relleno);
      case _Direccion.abajo:
        final x = size.width / 2;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height - cabeza), trazo);
        _cabeza(
          canvas,
          Offset(x, size.height),
          const Offset(0, -1),
          cabeza,
          relleno,
        );
    }
  }

  void _cabeza(
    Canvas canvas,
    Offset punta,
    Offset direccion,
    double tamano,
    Paint pintura,
  ) {
    final perpendicular = Offset(-direccion.dy, direccion.dx);
    final base = punta + direccion * tamano;
    final camino = Path()
      ..moveTo(punta.dx, punta.dy)
      ..lineTo(
        base.dx + perpendicular.dx * tamano * 0.5,
        base.dy + perpendicular.dy * tamano * 0.5,
      )
      ..lineTo(
        base.dx - perpendicular.dx * tamano * 0.5,
        base.dy - perpendicular.dy * tamano * 0.5,
      )
      ..close();
    canvas.drawPath(camino, pintura);
  }

  @override
  bool shouldRepaint(covariant _PintorFlecha oldDelegate) {
    return oldDelegate.direccion != direccion ||
        oldDelegate.grosor != grosor ||
        oldDelegate.color != color;
  }
}

class _TablaEntraSale extends StatelessWidget {
  final FlujosTubos flujos;

  const _TablaEntraSale({required this.flujos});

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      _TarjetaBalance(
        titulo: 'Capa Web (A)',
        derivada: "x'(t)",
        entrada: flujos.entradaTotalA,
        salida: flujos.salidaTotalA,
        balance: flujos.balanceA,
        hayDesglose: flujos.hayDesglose,
        color: ColoresApp.acento,
      ),
      _TarjetaBalance(
        titulo: 'Base de Datos (B)',
        derivada: "y'(t)",
        entrada: flujos.entradaTotalB,
        salida: flujos.salidaTotalB,
        balance: flujos.balanceB,
        hayDesglose: flujos.hayDesglose,
        color: ColoresApp.aviso,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Entra / Sale por tanque',
          style: TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!flujos.hayDesglose) ...[
          const SizedBox(height: 6),
          const Text(
            'Modo directo: no hay caudales de tubo, así que solo se muestra el '
            'balance neto de cada tanque.',
            style: TextStyle(
              color: ColoresApp.aviso,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, restricciones) {
            if (restricciones.maxWidth >= 560) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tarjetas[0]),
                  const SizedBox(width: 14),
                  Expanded(child: tarjetas[1]),
                ],
              );
            }
            return Column(
              children: [tarjetas[0], const SizedBox(height: 12), tarjetas[1]],
            );
          },
        ),
      ],
    );
  }
}

class _TarjetaBalance extends StatelessWidget {
  final String titulo;
  final String derivada;
  final double entrada;
  final double salida;
  final double balance;
  final bool hayDesglose;
  final Color color;

  const _TarjetaBalance({
    required this.titulo,
    required this.derivada,
    required this.entrada,
    required this.salida,
    required this.balance,
    required this.hayDesglose,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresApp.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (hayDesglose) ...[
            _fila('Entrada total', formatearNumero(entrada)),
            _fila('Salida total', formatearNumero(salida)),
          ],
          _fila(
            "Balance neto · $derivada",
            formatearNumero(balance),
            destacado: true,
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(
                color: destacado
                    ? ColoresApp.textoPrimario
                    : ColoresApp.textoSecundario,
                fontSize: 12,
                fontWeight: destacado ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: destacado
                  ? ColoresApp.textoPrimario
                  : ColoresApp.textoSecundario,
              fontSize: destacado ? 13 : 12,
              fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
