import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/in_memory_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/data/datasources/in_memory_chat_data_source.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/chat/ui/viewmodels/chat_view_model.dart';
import 'package:f_roble_market/features/notifications/data/repositories/in_memory_notification_repository.dart';

/// Un mensaje propio llega dos veces: por el eco del socket y por lo que
/// devuelve `send`. Como la clave la pone el servidor, en ambos casos es la
/// misma, y la burbuja tiene que pintarse una sola vez.
void main() {
  late DummyData data;
  late ChatRepository chats;
  late SessionViewModel session;
  late ChatViewModel chat;

  setUp(() async {
    data = DummyData();
    chats = ChatRepository(InMemoryChatDataSource(data));
    session = SessionViewModel(AuthRepository(InMemoryAuthDataSource(data)));
    await session.login(
      email: DummyData.demoEmail,
      password: DummyData.demoPassword,
    );

    final threads = await chats.threadsOf(session.requireUser.userId);
    chat = ChatViewModel(
      threadId: threads.first.id,
      chats: chats,
      dispatcher: InMemoryNotificationRepository(),
      session: session,
    );
    await chat.load();
  });

  tearDown(() => chat.onClose());

  test('enviar un mensaje lo pinta una sola vez', () async {
    final antes = chat.messages.length;

    await chat.send('Sigue disponible?');
    // El eco viaja por el socket: se le da tiempo a llegar despues del envio.
    await Future.delayed(const Duration(milliseconds: 300));

    expect(chat.error.value, isNull);
    expect(chat.messages.length, antes + 1);
    expect(
      chat.messages.where((m) => m.text == 'Sigue disponible?').length,
      1,
      reason: 'la burbuja propia no debe duplicarse',
    );
    // Y lo que quedo en pantalla es lo mismo que hay guardado: al salir y
    // volver a entrar no cambia nada.
    final guardados = await chats.messagesOf(chat.threadId);
    expect(chat.messages.map((m) => m.id), guardados.map((m) => m.id));
  });
}
