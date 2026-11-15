import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/sesion.dart';
import '../../app/tema.dart';
import '../../app/usuarios.dart';
import 'motivo_login.dart';

/// Pantalla de acceso de demostración.
///
/// No es seguridad real: es un sitio estático público sin servidor, así que
/// las credenciales viajan dentro de la app y cualquiera puede leerlas. Solo
/// simula el flujo de acceso y permite mostrar el perfil del usuario.
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _usuario = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  final FocusNode _focoClave = FocusNode();
  bool _mostrarClave = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    _focoClave.dispose();
    super.dispose();
  }

  void _ingresar() {
    final usuarios = context.read<RepositorioUsuarios>();
    final sesion = context.read<Sesion>();
    final usuario = _usuario.text.trim();
    final clave = _clave.text;

    if (usuario.isEmpty || clave.isEmpty) {
      setState(
        () => _error = 'Ingresa tu usuario y tu contraseña para continuar.',
      );
      return;
    }

    final encontrado = usuarios.autenticar(usuario, clave);
    if (encontrado == null) {
      setState(
        () => _error =
            'Las credenciales no coinciden. Revisa e inténtalo de nuevo.',
      );
      return;
    }

    setState(() => _error = null);
    sesion.iniciarSesion(encontrado);
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.read<RepositorioUsuarios>();

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final esAncho = restricciones.maxWidth >= 900;
          final marca = _PanelMarca(compacto: !esAncho);
          final formulario = _PanelFormulario(
            usuario: _usuario,
            clave: _clave,
            focoClave: _focoClave,
            mostrarClave: _mostrarClave,
            error: _error,
            pista: usuarios.pistaDemo ? usuarios.usuarioPista : null,
            alAlternarClave: () =>
                setState(() => _mostrarClave = !_mostrarClave),
            alIngresar: _ingresar,
          );

          if (esAncho) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 45, child: marca),
                Expanded(flex: 55, child: formulario),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [marca, formulario],
            ),
          );
        },
      ),
    );
  }
}

class _PanelMarca extends StatelessWidget {
  final bool compacto;

  const _PanelMarca({required this.compacto});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColores.primario,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compacto ? 24 : 48,
            compacto ? 28 : 40,
            compacto ? 24 : 48,
            compacto ? 28 : 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Wordmark(compacto: compacto),
              const SizedBox(height: 14),
              const Text(
                'Infraestructura cloud para el comercio local',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColores.sobrePrimario,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              SizedBox(height: compacto ? 18 : 26),
              SizedBox(
                height: compacto ? 120 : 180,
                width: double.infinity,
                child: const MotivoLogin(),
              ),
              SizedBox(height: compacto ? 18 : 26),
              const _TarjetaDescripcion(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final bool compacto;

  const _Wordmark({required this.compacto});

  @override
  Widget build(BuildContext context) {
    final tamano = compacto ? 56.0 : 68.0;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'NMiko',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: tamano,
                fontWeight: FontWeight.w800,
                color: AppColores.sobrePrimario,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
            TextSpan(
              text: '   S.A.C.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: tamano * 0.30,
                fontWeight: FontWeight.w300,
                color: AppColores.sobrePrimario,
                letterSpacing: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDescripcion extends StatelessWidget {
  const _TarjetaDescripcion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NMiko S.A.C. es una startup de Huancayo, Junín, que brinda '
            'alojamiento web, infraestructura cloud y soporte de servidores a '
            'bodegas, minimarkets y negocios de comercio minorista de la '
            'región. TI-Saturation Predictor es su herramienta para anticipar '
            'cuándo se saturan sus servidores y planificar el escalado antes '
            'de que el sistema caiga.',
            style: TextStyle(
              color: AppColores.textoPrincipal,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          _Vineta('Modela el tráfico con ecuaciones diferenciales'),
          SizedBox(height: 10),
          _Vineta('Predice el colapso de la Capa Web y la Base de Datos'),
          SizedBox(height: 10),
          _Vineta('Calcula la Ventana de Acción para reaccionar'),
        ],
      ),
    );
  }
}

class _Vineta extends StatelessWidget {
  final String texto;

  const _Vineta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 18,
          color: AppColores.primarioOscuro,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelFormulario extends StatelessWidget {
  final TextEditingController usuario;
  final TextEditingController clave;
  final FocusNode focoClave;
  final bool mostrarClave;
  final String? error;
  final UsuarioDemo? pista;
  final VoidCallback alAlternarClave;
  final VoidCallback alIngresar;

  const _PanelFormulario({
    required this.usuario,
    required this.clave,
    required this.focoClave,
    required this.mostrarClave,
    required this.error,
    required this.pista,
    required this.alAlternarClave,
    required this.alIngresar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColores.fondo,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                builder: (context, valor, child) => Opacity(
                  opacity: valor,
                  child: Transform.translate(
                    offset: Offset(0, (1 - valor) * 16),
                    child: child,
                  ),
                ),
                child: _TarjetaLogin(
                  usuario: usuario,
                  clave: clave,
                  focoClave: focoClave,
                  mostrarClave: mostrarClave,
                  error: error,
                  pista: pista,
                  alAlternarClave: alAlternarClave,
                  alIngresar: alIngresar,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaLogin extends StatelessWidget {
  final TextEditingController usuario;
  final TextEditingController clave;
  final FocusNode focoClave;
  final bool mostrarClave;
  final String? error;
  final UsuarioDemo? pista;
  final VoidCallback alAlternarClave;
  final VoidCallback alIngresar;

  const _TarjetaLogin({
    required this.usuario,
    required this.clave,
    required this.focoClave,
    required this.mostrarClave,
    required this.error,
    required this.pista,
    required this.alAlternarClave,
    required this.alIngresar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.borde),
        boxShadow: [
          BoxShadow(
            color: AppColores.textoPrincipal.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: AppColores.textoPrincipal,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'TI-Saturation Predictor · Proyecto ABR',
            style: TextStyle(color: AppColores.textoSecundario, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: usuario,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => focoClave.requestFocus(),
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: clave,
            focusNode: focoClave,
            obscureText: !mostrarClave,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => alIngresar(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: mostrarClave
                    ? 'Ocultar contraseña'
                    : 'Mostrar contraseña',
                icon: Icon(
                  mostrarClave
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: alAlternarClave,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _MensajeError(mensaje: error!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: alIngresar,
              child: const Text('Ingresar'),
            ),
          ),
          if (pista != null) ...[
            const SizedBox(height: 16),
            _PanelPista(pista: pista!),
          ],
          const SizedBox(height: 20),
          const Text(
            'Proyecto ABR · Ecuaciones Diferenciales',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColores.textoSecundario, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  final String mensaje;

  const _MensajeError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.importante.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColores.importante.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColores.importante,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColores.importante,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelPista extends StatelessWidget {
  final UsuarioDemo pista;

  const _PanelPista({required this.pista});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.panelSecundario,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColores.borde),
      ),
      child: Text(
        'Acceso de demostración: usuario ${pista.usuario} · '
        'contraseña ${pista.clave}',
        style: const TextStyle(
          color: AppColores.textoPrincipal,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
