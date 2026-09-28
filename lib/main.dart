import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:f_roble_market/core/theme/app_theme.dart';
import 'package:f_roble_market/di/app_bindings.dart';
import 'package:f_roble_market/routes/app_pages.dart';
import 'package:f_roble_market/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await prepareApp();
  runApp(const RobleMarketApp());
}

/// Lo que tiene que estar listo antes del primer frame. Aparte de `main` para
/// que las pruebas de integracion arranquen la app igual que en produccion.
Future<void> prepareApp() async {
  // Los formatos de fecha en espanol necesitan cargarse antes de usarse.
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');
}

class RobleMarketApp extends StatelessWidget {
  const RobleMarketApp({super.key, this.bindings});

  /// De donde salen los datos. Sin nada, de Roble (`AppBindings`). Las pruebas
  /// de integracion pasan `LocalBindings`: la misma app, con las fuentes de
  /// datos en memoria en vez de las del servidor.
  final Bindings? bindings;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mi carro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialBinding: bindings ?? AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
