import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final controller = Get.find<SessionViewModel>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.error.value = null;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contrasena'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmation,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Repite la contrasena'),
          ),
          const SizedBox(height: 16),
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
                      final ok = await controller.register(
                        name: name.text,
                        email: email.text,
                        password: password.text,
                        confirmation: confirmation.text,
                      );
                      // Se cierran las dos rutas: registro y login.
                      if (ok) {
                        Get.back();
                        Get.back();
                      }
                    },
              child: controller.busy.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}
