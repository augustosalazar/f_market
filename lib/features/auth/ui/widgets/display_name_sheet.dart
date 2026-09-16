import 'package:flutter/material.dart';

/// Pide a un invitado con que nombre quiere firmar lo que escriba.
///
/// Se pregunta **una sola vez y justo antes de la primera pregunta**, no al
/// entrar: pedir datos a quien todavia esta mirando es lo que hace que se
/// vaya. Aqui ya decidio escribir, y el nombre tiene un porque visible.
class DisplayNameSheet extends StatefulWidget {
  const DisplayNameSheet({super.key});

  @override
  State<DisplayNameSheet> createState() => _DisplayNameSheetState();
}

class _DisplayNameSheetState extends State<DisplayNameSheet> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _listo() {
    final limpio = _name.text.trim();
    if (limpio.length < 3) {
      setState(() => _error = 'Al menos 3 caracteres.');
      return;
    }
    Navigator.of(context).pop(limpio);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
          Text('Como te llamamos?', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Tu pregunta se publica con este nombre, y el vendedor lo vera al '
            'responderte. No hace falta cuenta.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _listo(),
            decoration: InputDecoration(
              labelText: 'Tu nombre',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _listo,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Seguir'),
          ),
        ],
      ),
    );
  }
}
