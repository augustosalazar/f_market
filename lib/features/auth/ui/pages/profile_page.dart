import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/routes/app_routes.dart';

class ProfilePage extends GetView<SessionViewModel> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Obx(() {
        final user = controller.user.value;
        if (user == null) {
          return EmptyState(
            icon: Icons.person_outline,
            title: 'No has entrado',
            message: 'El catalogo es publico, pero lo demas necesita cuenta.',
            action: FilledButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              child: const Text('Entrar'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(
                  user.initials,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Center(
              child: Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesion'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        );
      }),
    );
  }
}
