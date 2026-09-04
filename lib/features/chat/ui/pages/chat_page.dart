import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/core/utils/message_listener.dart';
import 'package:f_roble_market/features/chat/ui/viewmodels/chat_view_model.dart';

/// Un chat privado. El interruptor de la barra silencia el hilo: es el
/// «bloqueo» del requisito 8.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with MessageListener<ChatPage> {
  final controller = Get.find<ChatViewModel>();
  final input = TextEditingController();
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    listenMessages(message: controller.message, error: controller.error);
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = input.text;
    if (text.trim().isEmpty) return;
    input.clear();
    await controller.send(text);
    if (!scroll.hasClients) return;
    await scroll.animateTo(
      scroll.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final thread = controller.thread.value;
          if (thread == null) return const Text('Chat');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(thread.otherName(controller.myId)),
              Text(
                thread.listingTitle,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          );
        }),
        actions: [
          Obx(() {
            final muted = controller.thread.value?.muted ?? false;
            return IconButton(
              tooltip: muted
                  ? 'Reactivar notificaciones'
                  : 'Silenciar este chat',
              onPressed: controller.toggleMuted,
              icon: Icon(
                muted
                    ? Icons.notifications_off
                    : Icons.notifications_active_outlined,
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.messages.isEmpty) {
                return const Center(
                  child: Text('Escribe el primer mensaje.'),
                );
              }
              return ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return _Bubble(
                    text: message.text,
                    time: Formatters.time(message.sentAt),
                    mine: message.senderId == controller.myId,
                  );
                },
              );
            }),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mensaje',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => IconButton.filled(
                      onPressed: controller.sending.value ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.time, required this.mine});

  final String text;
  final String time;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: mine ? const Radius.circular(4) : null,
            bottomLeft: mine ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(time, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
