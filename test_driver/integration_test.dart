import 'package:integration_test/integration_test_driver.dart';

/// Puente entre `flutter drive` y las pruebas de `integration_test/`. Solo hace
/// falta para correrlas en Chrome; en macOS o un emulador basta `flutter test`.
Future<void> main() => integrationDriver();
