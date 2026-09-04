import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';

/// Un chat abierto. La regla propia esta en `send`: el destinatario recibe
/// aviso salvo que el hilo este silenciado, que es el «bloqueo» del
/// requisito 8.
class ChatViewModel extends GetxController {
  ChatViewModel({
    required this.threadId,
    required this.chats,
    required this.dispatcher,
    required this.session,
  });

  final String threadId;
  final IChatRepository chats;
  final INotificationDispatcher dispatcher;
  final SessionViewModel session;

  final thread = Rxn<ChatThread>();
  final messages = <ChatMessage>[].obs;
  final loading = true.obs;
  final sending = false.obs;
  final message = RxnString();
  final error = RxnString();

  String get myId => session.requireUser.userId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      await chats.markRead(threadId);
      thread.value = await chats.threadById(threadId);
      messages.assignAll(await chats.messagesOf(threadId));
    } finally {
      loading.value = false;
    }
  }

  Future<void> send(String text) async {
    final current = thread.value;
    final body = text.trim();
    if (current == null || body.isEmpty) return;

    sending.value = true;
    try {
      final sent = await chats.send(
        threadId: current.id,
        senderId: myId,
        text: body,
      );
      messages.add(sent);

      if (!current.muted) {
        final recipient =
            myId == current.sellerId ? current.buyerId : current.sellerId;
        await dispatcher.dispatch(
          userIds: [recipient],
          kind: NotificationKind.chatMessage,
          title: session.requireUser.name,
          body: body,
          listingId: current.listingId,
          threadId: current.id,
        );
      }
    } catch (e) {
      error.value = 'No se pudo enviar el mensaje.';
    } finally {
      sending.value = false;
    }
  }

  Future<void> toggleMuted() async {
    final current = thread.value;
    if (current == null) return;
    final updated = await chats.setMuted(
      threadId: current.id,
      muted: !current.muted,
    );
    thread.value = updated;
    message.value = updated.muted
        ? 'Chat silenciado: no recibiras notificaciones de este chat.'
        : 'Chat activo: volveras a recibir notificaciones de este chat.';
  }
}
