import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las pruebas no hablan con Roble: probar el servidor no es trabajo de esta
/// app. Corren con las fuentes de datos en memoria, sin red y sin cuenta.
///
/// Esto lo vigila en vez de confiar en que nadie se equivoque de carpeta: una
/// prueba que construye el cliente de verdad se cuela facil, y el sintoma
/// —fallos por red o por falta de `ROBLE_CONTRACT_ID`— sale lejos de la causa.
///
/// Importar `package:roble/roble.dart` **si** esta permitido: los repositorios
/// traducen las excepciones del paquete, y probar esa traduccion exige lanzar
/// una. Lanzar un `RobleApiConflictException` no sale a la red; construir un
/// `RobleApiDataBase`, si.
void main() {
  const forbidden = {
    'core/roble.dart': 'el cliente de Roble de la app',
    'datasources/roble_': 'una fuente de datos que habla con el servidor',
    'di/app_bindings.dart': 'las dependencias de produccion, que usan Roble',
    'RobleApiDataBase(': 'un cliente de Roble construido a mano',
  };

  test('ninguna prueba usa el servidor de Roble', () {
    final testFiles = [Directory('test'), Directory('integration_test')]
        .where((d) => d.existsSync())
        .expand((d) => d.listSync(recursive: true))
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        // Este archivo nombra lo prohibido para poder buscarlo.
        .where((f) => !f.path.endsWith('sin_roble_test.dart'));

    final violations = <String>[
      for (final testFile in testFiles)
        for (final MapEntry(key: pattern, value: what) in forbidden.entries)
          if (testFile.readAsStringSync().contains(pattern))
            '${testFile.path}: usa $what ($pattern). Usa las fuentes en memoria.',
    ];

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
