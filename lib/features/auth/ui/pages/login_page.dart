import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// Entrar con correo y contrasena o con Google (requisito 2).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controller = Get.find<SessionViewModel>();

  // Prellenados con la cuenta de demo: en esta fase los datos son locales y
  // asi la app se puede recorrer entera sin buscar credenciales.
  final email = TextEditingController(text: DummyData.demoEmail);
  final password = TextEditingController(text: DummyData.demoPassword);

  @override
  void initState() {
    super.initState();
    controller.error.value = null;
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Entra para publicar, preguntar y chatear.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contrasena'),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final error = controller.error.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }),
          Obx(
            () => FilledButton(
              onPressed: controller.busy.value
                  ? null
                  : () async {
                      final ok = await controller.login(
                        email: email.text,
                        password: password.text,
                      );
                      if (ok) Get.back();
                    },
              child: controller.busy.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await controller.signInWithGoogle();
              if (ok) Get.back();
            },
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continuar con Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Get.toNamed(AppRoutes.register),
              child: const Text('No tengo cuenta, quiero registrarme'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Datos de prueba: ${DummyData.demoEmail} / ${DummyData.demoPassword}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
