import 'package:flutter/foundation.dart';

import 'usuarios.dart';

/// Sesión en memoria del acceso de demostración.
///
/// No usa almacenamiento persistente: al recargar la página se vuelve al
/// login. Tampoco es seguridad real, solo simula el flujo de acceso.
class Sesion extends ChangeNotifier {
  UsuarioDemo? _usuario;

  UsuarioDemo? get usuario => _usuario;

  bool get autenticado => _usuario != null;

  void iniciarSesion(UsuarioDemo usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrarSesion() {
    if (_usuario == null) return;
    _usuario = null;
    notifyListeners();
  }
}
