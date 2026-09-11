import 'dart:async';

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

  StreamSubscription<ChatMessage>? _incoming;

  String get myId => session.requireUser.userId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _incoming?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      await chats.markRead(threadId);
      thread.value = await chats.threadById(threadId);
      messages.assignAll(await chats.messagesOf(threadId));
      _listen();
    } finally {
      loading.value = false;
    }
  }

  /// Escucha los mensajes que lleguen de ahora en adelante. Se lee primero y
  /// se escucha despues: el tiempo real no reenvia lo que ya estaba.
  void _listen() {
    _incoming?.cancel();
    _incoming = chats.watchMessages(threadId).listen(
      (incoming) {
        if (!_append(incoming)) return;
        if (incoming.senderId != myId) chats.markRead(threadId);
      },
      // Un hilo sin mensajes todavia no tiene coleccion en el arbol, y
      // suscribirse a una que no existe se rechaza. Deja de escuchar sin
      // romper la pantalla; al primer envio se vuelve a intentar.
      onError: (Object _) {
        _incoming?.cancel();
        _incoming = null;
      },
    );
  }

  /// Pinta un mensaje una sola vez.
  ///
  /// El mismo mensaje llega por dos caminos: el eco del socket y la respuesta
  /// de `send`. La clave la pone el servidor al escribirlo, asi que en ambos
  /// es la misma y basta con mirarla. Devuelve si lo anadio.
  bool _append(ChatMessage incoming) {
    if (messages.any((m) => m.id == incoming.id)) return false;
    messages.add(incoming);
    return true;
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
      // Puede que el eco ya lo haya pintado: `send` no vuelve hasta actualizar
      // tambien la cabecera del hilo, y en esa espera el socket se adelanta.
      _append(sent);
      // Si la suscripcion se cayo por no existir la coleccion, ahora ya existe.
      if (_incoming == null) _listen();

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
