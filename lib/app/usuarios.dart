import 'dart:convert';

import 'package:flutter/services.dart';

/// Un usuario de demostración leído de `assets/config/usuarios.json`.
class UsuarioDemo {
  final String usuario;
  final String clave;
  final String nombre;
  final String rol;
  final String iniciales;

  const UsuarioDemo({
    required this.usuario,
    required this.clave,
    required this.nombre,
    required this.rol,
    required this.iniciales,
  });

  factory UsuarioDemo.fromJson(Map<String, dynamic> json) {
    return UsuarioDemo(
      usuario: json['usuario'] as String,
      clave: json['clave'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String,
      iniciales: json['iniciales'] as String,
    );
  }
}

/// Repositorio de usuarios del acceso de demostración.
///
/// Este login NO protege nada: es un sitio estático público sin servidor, así
/// que las credenciales viajan dentro de la app y cualquiera puede leerlas.
/// Solo sirve para simular el flujo de acceso y mostrar el perfil.
class RepositorioUsuarios {
  final bool pistaDemo;
  final List<UsuarioDemo> usuarios;

  const RepositorioUsuarios({required this.pistaDemo, required this.usuarios});

  factory RepositorioUsuarios.fromJson(Map<String, dynamic> json) {
    final crudos = (json['usuarios'] as List<dynamic>? ?? const []);
    return RepositorioUsuarios(
      pistaDemo: json['pista_demo'] as bool? ?? false,
      usuarios: [
        for (final crudo in crudos)
          UsuarioDemo.fromJson(crudo as Map<String, dynamic>),
      ],
    );
  }

  static Future<RepositorioUsuarios> cargar() async {
    final texto = await rootBundle.loadString('assets/config/usuarios.json');
    return RepositorioUsuarios.fromJson(
      jsonDecode(texto) as Map<String, dynamic>,
    );
  }

  /// Devuelve el usuario si las credenciales coinciden; `null` en caso
  /// contrario. Nunca se informa cuál de los dos campos falló.
  UsuarioDemo? autenticar(String usuario, String clave) {
    for (final candidato in usuarios) {
      if (candidato.usuario == usuario && candidato.clave == clave) {
        return candidato;
      }
    }
    return null;
  }

  /// Primer usuario, usado para mostrar la pista de demostración.
  UsuarioDemo? get usuarioPista => usuarios.isEmpty ? null : usuarios.first;
}
