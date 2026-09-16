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
  // Los formatos de fecha en espanol necesitan cargarse antes de usarse.
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');
  runApp(const RobleMarketApp());
}

class RobleMarketApp extends StatelessWidget {
  const RobleMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mi carro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
