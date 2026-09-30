import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/core/missing_config_app.dart';

/// Lo que ve quien arranca la app sin el archivo `.env`.
void main() {
  testWidgets('nombra las variables que faltan', (tester) async {
    await tester.pumpWidget(
      const MissingConfigApp(missing: ['ROBLE_CONTRACT_ID']),
    );

    expect(find.text('Falta la configuracion'), findsOneWidget);
    expect(find.text('•  ROBLE_CONTRACT_ID'), findsOneWidget);
    expect(find.text('•  ROBLE_BASE_URL'), findsNothing);
  });

  testWidgets('dice como arrancar con el .env', (tester) async {
    await tester.pumpWidget(
      const MissingConfigApp(missing: ['ROBLE_BASE_URL']),
    );

    expect(
      find.text('flutter run --dart-define-from-file=.env'),
      findsOneWidget,
    );
  });
}
