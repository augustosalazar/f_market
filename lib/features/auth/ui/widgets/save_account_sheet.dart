import 'package:flutter/material.dart';

/// Lo que devuelve la hoja de «guarda tu cuenta»: o los datos escritos, o la
/// decision de hacerlo con Google.
sealed class SaveAccountChoice {
  const SaveAccountChoice();
}

/// Guardar la cuenta con Google, sin escribir nada.
class SaveAccountWithGoogle extends SaveAccountChoice {
  const SaveAccountWithGoogle();
}

/// Guardar la cuenta con correo y contrasena.
class SaveAccountData extends SaveAccountChoice {
  const SaveAccountData({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmation,
  });

  final String name;
  final String email;
  final String password;
  final String confirmation;
}

/// Convierte al invitado en una cuenta.
///
/// No se llama «registrarse» a proposito: quien llega aqui ya tiene sesion y
/// cosas suyas guardadas. La promesa que hace la pantalla —que no se pierde
/// nada— es literal: Roble **muta** el usuario que ya existe, conservando su
/// id, asi que cada fila suya sigue siendo suya sin moverse.
class SaveAccountSheet extends StatefulWidget {
  const SaveAccountSheet({
    super.key,
    this.followedCount = 0,
    this.initialName,
    this.googleEnabled = false,
  });

  /// Si el proyecto tiene Google encendido. Sin el, el boton no se pinta: con
  /// Google apagado siempre fallaria.
  final bool googleEnabled;

  /// El nombre con el que ya viene firmando, si dio uno para preguntar. Que la
  /// cuenta nazca con otro nombre distinto al de sus preguntas seria raro.
  final String? initialName;

  /// Cuantas publicaciones sigue. Concreta la promesa: «no pierdes los 3
  /// carros que sigues» convence mas que «no pierdes tus datos».
  final int followedCount;

  @override
  State<SaveAccountSheet> createState() => _SaveAccountSheetState();
}

class _SaveAccountSheetState extends State<SaveAccountSheet> {
  late final _name = TextEditingController(text: widget.initialName ?? '');
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final seguidas = widget.followedCount;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guarda tu cuenta', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            seguidas == 0
                ? 'Ahora mismo estas como invitado: si pierdes este telefono, '
                      'pierdes lo que llevas.'
                : 'Conservas ${seguidas == 1 ? 'la publicacion que sigues' : 'las $seguidas publicaciones que sigues'}, '
                      'y podras entrar desde otro telefono.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          if (widget.googleEnabled) ...[
            // Primero, porque es el camino corto: no hay nada que escribir y
            // conserva lo suyo igual que el otro.
            OutlinedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(const SaveAccountWithGoogle()),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Guardar con Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o con tu correo', style: text.bodySmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tu nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contrasena'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmation,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Repite la contrasena'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              SaveAccountData(
                name: _name.text,
                email: _email.text,
                password: _password.text,
                confirmation: _confirmation.text,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Guardar mi cuenta'),
          ),
        ],
      ),
    );
  }
}
