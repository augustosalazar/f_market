import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// Restaura la sesion guardada antes de decidir que se muestra. Al conectar
/// Roble, aqui es donde ira `db.restoreSession()`.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Get.find<SessionViewModel>().restore();
    // El catalogo es publico: se entra igual haya sesion o no.
    await Get.offNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64),
            SizedBox(height: 16),
            Text('Roble Market'),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
