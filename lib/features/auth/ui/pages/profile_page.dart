import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/auth/ui/widgets/save_account_sheet.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/profiles/ui/pages/profile_args.dart';
import 'package:f_roble_market/routes/app_routes.dart';

class ProfilePage extends GetView<SessionViewModel> {
  const ProfilePage({super.key});

  /// Ofrece convertir la sesion de invitado en una cuenta.
  ///
  /// Si el correo ya tiene cuenta, Roble no fusiona nada: lo unico honesto es
  /// decirlo y ofrecer entrar, avisando de que lo del invitado se queda atras.
  Future<void> _saveAccount(BuildContext context) async {
    final seguidas = Get.isRegistered<FollowsViewModel>()
        ? Get.find<FollowsViewModel>().ids.length
        : 0;
    // Antes de abrir la hoja, porque es ella quien decide si pinta el boton.
    await controller.loadProviders();
    if (!context.mounted) return;

    final eleccion = await showModalBottomSheet<SaveAccountChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveAccountSheet(
        followedCount: seguidas,
        initialName: controller.guestName.value,
        googleEnabled: controller.googleEnabled.value,
      ),
    );
    if (eleccion == null) return;

    final listo = switch (eleccion) {
      SaveAccountWithGoogle() => await controller.upgradeWithGoogle(),
      SaveAccountData(:final name, :final email, :final password,
              :final confirmation) =>
        await controller.upgrade(
          name: name,
          email: email,
          password: password,
          confirmation: confirmation,
        ),
    };
    // Con Google el choque es otro —esa cuenta ya es de alguien— y el mensaje
    // del repositorio ya lo explica; no hay nada que ofrecer aqui.
    if (listo ||
        eleccion is SaveAccountWithGoogle ||
        controller.lastErrorCode != AuthFailure.emailTaken) {
      return;
    }
    if (!context.mounted) return;

    final entrar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Ese correo ya tiene cuenta'),
        content: const Text(
          'Puedes entrar con ella, pero lo que guardaste como invitado se '
          'queda en esta sesion: no se pasa a la otra cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Usar otro correo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Entrar con esa cuenta'),
          ),
        ],
      ),
    );
    if (entrar ?? false) await Get.toNamed(AppRoutes.login);
  }

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
              // La direccion de un invitado es inventada y no existe: en su
              // lugar va lo unico cierto, que esta a medio camino.
              child: Text(
                controller.isGuest ? 'Estas como invitado' : user.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            if (controller.isGuest) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guarda tu cuenta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sin correo ni contrasena, lo que sigues vive solo en '
                        'este telefono. Con cuenta tambien puedes publicar, '
                        'preguntar y chatear.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: controller.busy.value
                            ? null
                            : () => _saveAccount(context),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar mi cuenta'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // El mismo perfil que ve cualquiera: historial y calificaciones.
            // Verse como te ven es lo que hace util tener reputacion.
            FilledButton.tonalIcon(
              onPressed: () => Get.toNamed(
                AppRoutes.userProfile,
                arguments: ProfileArgs(userId: user.userId, name: user.name),
              ),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Mi perfil publico y calificaciones'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            // A un invitado no se le ofrece cerrar sesion: no tiene con que
            // volver a entrar, asi que seria borrar su cuenta sin decirlo.
            if (!controller.isGuest)
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
