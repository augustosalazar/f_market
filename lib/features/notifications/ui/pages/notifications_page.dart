import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/ui/viewmodels/notifications_view_model.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// La bandeja. En esta fase se llena con lo que hace la propia app; al
/// conectar Roble llegara por el canal de tiempo real y por push.
class NotificationsPage extends GetView<NotificationsViewModel> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.unreadCount == 0 ? null : controller.markAllRead,
              child: const Text('Marcar leidas'),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (!session.isLoggedIn) {
          return EmptyState(
            icon: Icons.notifications_none,
            title: 'Entra para ver tus avisos',
            message:
                'Te avisamos de preguntas, respuestas, cambios de estado y '
                'mensajes privados.',
            action: FilledButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              child: const Text('Entrar'),
            ),
          );
        }
        if (controller.items.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: 'Nada nuevo',
            message: 'Aqui apareceran tus avisos.',
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshInbox,
          child: ListView.separated(
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = controller.items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.read
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_iconOf(notification.kind), size: 20),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight:
                        notification.read ? FontWeight.w400 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(notification.body, maxLines: 2),
                trailing: Text(
                  Formatters.relative(notification.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                onTap: () {
                  controller.markRead(notification);
                  if (notification.threadId != null) {
                    Get.toNamed(AppRoutes.chat, arguments: notification.threadId);
                  } else if (notification.listingId != null) {
                    Get.toNamed(
                      AppRoutes.listingDetail,
                      arguments: notification.listingId,
                    );
                  }
                },
              );
            },
          ),
        );
      }),
    );
  }

  IconData _iconOf(NotificationKind kind) => switch (kind) {
    NotificationKind.question => Icons.help_outline,
    NotificationKind.answer => Icons.forum_outlined,
    NotificationKind.statusChange => Icons.sync_alt,
    NotificationKind.chatMessage => Icons.chat_bubble_outline,
  };
}
