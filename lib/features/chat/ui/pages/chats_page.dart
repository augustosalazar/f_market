import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/core/widgets/car_photo.dart';
import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/ui/viewmodels/chats_view_model.dart';
import 'package:f_roble_market/routes/app_routes.dart';

class ChatsPage extends GetView<ChatsViewModel> {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Obx(() {
        if (!session.isLoggedIn) {
          return EmptyState(
            icon: Icons.forum_outlined,
            title: 'Entra para chatear',
            message: 'Los chats privados son entre comprador y vendedor.',
            action: FilledButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              child: const Text('Entrar'),
            ),
          );
        }
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.threads.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Sin chats todavia',
            message: 'Abre una publicacion y escribele al vendedor.',
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            itemCount: controller.threads.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final thread = controller.threads[index];
              final myId = session.requireUser.userId;
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CarPhoto(source: thread.listingCover),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(thread.otherName(myId))),
                    if (thread.muted)
                      const Icon(Icons.notifications_off_outlined, size: 16),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.listingTitle,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      thread.lastMessage.isEmpty
                          ? 'Sin mensajes'
                          : thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.relative(thread.lastMessageAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (thread.unreadCount > 0) ...[
                      const SizedBox(height: 4),
                      Badge(label: Text('${thread.unreadCount}')),
                    ],
                  ],
                ),
                onTap: () async {
                  await Get.toNamed(AppRoutes.chat, arguments: thread.id);
                  controller.load();
                },
              );
            },
          ),
        );
      }),
    );
  }
}
