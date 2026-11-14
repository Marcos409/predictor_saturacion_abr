import 'package:flutter/material.dart';

class ModuloApp {
  final String id;
  final String titulo;
  final String descripcion;
  final IconData icono;

  const ModuloApp({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });
}

const List<ModuloApp> modulosApp = [
  ModuloApp(
    id: 'dashboard',
    titulo: 'Dashboard',
    descripcion: 'Resumen general de la simulación',
    icono: Icons.dashboard_outlined,
  ),
  ModuloApp(
    id: 'escenarios',
    titulo: 'Escenarios',
    descripcion: 'Selección del escenario de tráfico',
    icono: Icons.layers_outlined,
  ),
  ModuloApp(
    id: 'fase1_trafico',
    titulo: 'Fase 1 · Tráfico',
    descripcion: 'Configuración del escenario de tráfico',
    icono: Icons.trending_up,
  ),
  ModuloApp(
    id: 'fase2_servidores',
    titulo: 'Fase 2 · Servidores',
    descripcion: 'Coeficientes, capacidades y reacción de TI',
    icono: Icons.dns_outlined,
  ),
  ModuloApp(
    id: 'simulacion_vivo',
    titulo: 'Simulación en vivo',
    descripcion: 'Reproducción de la saturación en tiempo real',
    icono: Icons.play_circle_outline,
  ),
  ModuloApp(
    id: 'alertas_autoscaling',
    titulo: 'Alertas y Auto-Scaling',
    descripcion: 'Umbrales, alertas y escalado automático',
    icono: Icons.notifications_active_outlined,
  ),
  ModuloApp(
    id: 'resultados',
    titulo: 'Resultados',
    descripcion: 'Tiempos de colapso y ventana de acción',
    icono: Icons.assessment_outlined,
  ),
  ModuloApp(
    id: 'matematica',
    titulo: 'Ver la matemática',
    descripcion: 'Ecuaciones, derivadas y solución',
    icono: Icons.functions,
  ),
  ModuloApp(
    id: 'verificacion_abr',
    titulo: 'Verificación ABR',
    descripcion: 'Contrasta los valores del ABR con las ecuaciones del motor',
    icono: Icons.fact_check_outlined,
  ),
  ModuloApp(
    id: 'configuracion',
    titulo: 'Configuración (JSON)',
    descripcion: 'Carga y descarga de la configuración',
    icono: Icons.settings_outlined,
  ),
];
