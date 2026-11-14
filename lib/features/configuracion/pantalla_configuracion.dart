import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/configuracion_archivo.dart';
import '../../app/estado_aplicacion.dart';
import '../../app/formato.dart';
import '../../app/tema.dart';
import '../../app/widgets/encabezado_pantalla.dart';
import '../../app/widgets/panel_seccion.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  bool _procesando = false;
  String? _mensaje;
  bool _esError = false;

  Future<void> _cargarJson() async {
    setState(() {
      _procesando = true;
      _mensaje = null;
    });

    try {
      final archivo = await FilePicker.pickFile(
        dialogTitle: 'Selecciona la configuración JSON',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (archivo == null) {
        if (!mounted) return;
        setState(() => _mensaje = 'Carga cancelada.');
        return;
      }

      final bytes = await archivo.readAsBytes();
      final contenido = utf8.decode(bytes);
      final configuracion = ConfiguracionArchivo.desdeJson(contenido);
      if (!mounted) return;

      context.read<EstadoAplicacion>().reemplazarConfiguracion(
        sistema: configuracion.sistema,
        escenarios: configuracion.escenarios,
        solucionAnalitica: configuracion.solucionAnalitica,
      );
      if (!mounted) return;
      setState(() {
        _esError = false;
        _mensaje =
            'Configuración cargada desde "${archivo.name}". '
            'Se reinició la simulación con los nuevos valores.';
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _esError = true;
        _mensaje = 'No se pudo cargar el archivo: ${error.message}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _esError = true;
        _mensaje = 'No se pudo leer el archivo: $error';
      });
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _descargarJson() async {
    setState(() {
      _procesando = true;
      _mensaje = null;
    });

    try {
      final estado = context.read<EstadoAplicacion>();
      final archivo = ConfiguracionArchivo(
        sistema: estado.sistema,
        escenarios: estado.configuracionEscenarios,
        solucionAnalitica: estado.solucionAnalitica,
      );
      await FilePicker.saveFile(
        dialogTitle: 'Guardar configuración actual',
        fileName: 'configuracion_ti_saturacion.json',
        bytes: Uint8List.fromList(utf8.encode(archivo.serializar())),
        mimeType: 'application/json',
      );
      if (!mounted) return;
      setState(() {
        _esError = false;
        _mensaje =
            'Descarga iniciada con la configuración actual. '
            'Revisa la carpeta de descargas del navegador.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _esError = true;
        _mensaje = 'No se pudo descargar la configuración: $error';
      });
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _restaurarCasoBase() async {
    setState(() {
      _procesando = true;
      _mensaje = null;
    });

    try {
      await context.read<EstadoAplicacion>().restaurarCasoBase();
      if (!mounted) return;
      setState(() {
        _esError = false;
        _mensaje =
            'Caso base restaurado. La simulación volvió a los valores originales.';
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _esError = true;
        _mensaje = 'No se pudo restaurar el caso base: ${error.message}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _esError = true;
        _mensaje = 'No se pudo restaurar el caso base: $error';
      });
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<EstadoAplicacion>();
    final sistema = estado.sistema;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoPantalla(
              titulo: 'Configuración (JSON)',
              descripcion:
                  'Carga, descarga o restaura los parámetros del modelo y los escenarios.',
            ),
            const SizedBox(height: 24),
            if (estado.error != null) ...[
              _Aviso(mensaje: estado.error!, esError: true),
              const SizedBox(height: 16),
            ],
            PanelSeccion(
              titulo: 'Acciones',
              subtitulo:
                  'La carga reemplaza la configuración completa. Un archivo inválido no modifica el estado actual.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _procesando ? null : _cargarJson,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Cargar JSON'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _procesando ? null : _descargarJson,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Descargar configuración actual'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _procesando ? null : _restaurarCasoBase,
                        icon: const Icon(Icons.restore_outlined, size: 18),
                        label: const Text('Restaurar caso base'),
                      ),
                      if (_procesando)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  if (_mensaje != null) ...[
                    const SizedBox(height: 16),
                    _Aviso(mensaje: _mensaje!, esError: _esError),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, restricciones) {
                final resumen = PanelSeccion(
                  titulo: 'Configuración activa',
                  subtitulo:
                      'Estos son los valores que se exportan al descargar.',
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 16,
                    children: [
                      _Dato(
                        etiqueta: 'Unidad de tiempo',
                        valor: sistema.unidadTiempo,
                      ),
                      _Dato(
                        etiqueta: 'Escenarios',
                        valor: '${estado.escenarios.length}',
                      ),
                      _Dato(
                        etiqueta: 'Escenario activo',
                        valor: estado.escenarioActivo.nombre,
                      ),
                      _Dato(
                        etiqueta: 'Paso de simulación',
                        valor:
                            '${formatearNumero(sistema.simulacion.paso)} min',
                      ),
                      _Dato(
                        etiqueta: 'Horizonte',
                        valor:
                            '${formatearNumero(sistema.simulacion.tiempoFinal, decimales: 0)} min',
                      ),
                      _Dato(
                        etiqueta: 'Umbral de aviso',
                        valor:
                            '${formatearNumero(sistema.umbralAlerta * 100, decimales: 0)} %',
                      ),
                    ],
                  ),
                );
                final formato = PanelSeccion(
                  titulo: 'Formato del archivo',
                  subtitulo: 'Un único JSON con tres secciones obligatorias.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SeccionRequerida(
                        nombre: 'sistema',
                        descripcion:
                            'Coeficientes, capacidades, condiciones iniciales, simulación, Auto-Scaling, verificación y semáforo.',
                      ),
                      const SizedBox(height: 10),
                      const _SeccionRequerida(
                        nombre: 'escenarios',
                        descripcion:
                            'Lista de escenarios de tráfico con sus parámetros y la expresión v1(t).',
                      ),
                      const SizedBox(height: 10),
                      const _SeccionRequerida(
                        nombre: 'soluciones',
                        descripcion:
                            'Expresiones analíticas x(t) e y(t) usadas por la verificación cruzada.',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Descarga la configuración actual para obtener un archivo de ejemplo completo. '
                        'Si falta una sección o un campo, se indica el nombre exacto sin alterar la configuración vigente.',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario.withValues(
                            alpha: 0.9,
                          ),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
                if (restricciones.maxWidth >= 860) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: resumen),
                      const SizedBox(width: 20),
                      Expanded(child: formato),
                    ],
                  );
                }
                return Column(
                  children: [resumen, const SizedBox(height: 20), formato],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String mensaje;
  final bool esError;

  const _Aviso({required this.mensaje, required this.esError});

  @override
  Widget build(BuildContext context) {
    final color = esError ? ColoresApp.alerta : ColoresApp.ok;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            color: ColoresApp.textoPrimario,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SeccionRequerida extends StatelessWidget {
  final String nombre;
  final String descripcion;

  const _SeccionRequerida({required this.nombre, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColoresApp.acento.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            nombre,
            style: const TextStyle(
              color: ColoresApp.acento,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            descripcion,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
