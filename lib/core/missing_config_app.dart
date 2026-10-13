import 'package:flutter/material.dart';

/// Lo que se ve cuando la app arranca sin el archivo `.env`.
///
/// Es una app aparte, minima, a proposito: sin configuracion no se puede crear
/// el cliente de Roble, y todo lo demas depende de el.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key, required this.missing});

  /// Los nombres de las variables que faltan.
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Falta la configuracion',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'La app no sabe a que servidor de Roble conectarse. Estos '
                'valores salen del archivo .env y no llegaron:',
              ),
              const SizedBox(height: 12),
              for (final name in missing)
                Text('•  $name', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 24),
              const Text('Para arreglarlo:'),
              const SizedBox(height: 8),
              const Text('1. Copia .env.example como .env y llena los valores.'),
              const Text('2. Arranca la app con:'),
              const SizedBox(height: 8),
              const SelectableText(
                'flutter run --dart-define-from-file=.env',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
