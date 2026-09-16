import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/in_memory_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/data/datasources/in_memory_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/chat/data/datasources/in_memory_chat_data_source.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/listing_detail_view_model.dart';
import 'package:f_roble_market/features/notifications/data/repositories/in_memory_notification_repository.dart';
import 'package:f_roble_market/features/qa/data/datasources/in_memory_qa_data_source.dart';
import 'package:f_roble_market/features/qa/data/repositories/qa_repository.dart';

/// Seguir un carro es el gesto de quien todavia esta mirando, y exigirle una
/// cuenta es donde se pierde. Con sesion de invitado lo hace y ya, y al
/// registrarse **conserva lo suyo** porque el `userId` no cambia.
void main() {
  late DummyData data;
  late ListingRepository listings;
  late SessionViewModel session;
  late FollowsViewModel follows;

  setUp(() async {
    Get.reset();
    // `ensureLoggedIn` manda al login con navegacion sin contexto, y sin esto
    // GetX lanza en vez de devolver: lo que se prueba es que el invitado no
    // pasa la puerta, no a donde se le manda.
    Get.testMode = true;
    data = DummyData();
    listings = ListingRepository(InMemoryListingDataSource(data));
    session = SessionViewModel(AuthRepository(InMemoryAuthDataSource(data)));
    follows = Get.put(FollowsViewModel(listings, session));
  });

  tearDown(Get.reset);

  test('seguir sin cuenta abre una sesion de invitado', () async {
    expect(session.isLoggedIn, isFalse);

    final siguiendo = await follows.toggle('l_1');

    expect(siguiendo, isTrue);
    expect(session.isGuest, isTrue);
    // Tiene sesion, pero no la cuenta que exigen publicar o chatear.
    expect(session.hasAccount, isFalse);
    expect(follows.ids, contains('l_1'));
  });

  test('el invitado no cuenta como cuenta para lo que la exige', () async {
    await follows.toggle('l_1');

    // `ensureLoggedIn` es la puerta de publicar y chatear: un invitado no pasa.
    // (Sin navegacion registrada devuelve false en vez de abrir el login.)
    expect(await session.ensureLoggedIn(), isFalse);
  });

  test('al guardar la cuenta conserva lo que siguio de invitado', () async {
    await follows.toggle('l_1');
    await follows.toggle('l_3');
    final idInvitado = session.requireUser.userId;

    final listo = await session.upgrade(
      name: 'Dani Rueda',
      email: 'dani@demo.com',
      password: 'ThePassword!1',
      confirmation: 'ThePassword!1',
    );

    expect(listo, isTrue, reason: session.error.value);
    expect(session.isGuest, isFalse);
    expect(session.hasAccount, isTrue);
    // El mismo usuario, no uno nuevo: es lo que hace que no se mueva un dato.
    expect(session.requireUser.userId, idInvitado);
    expect(session.requireUser.name, 'Dani Rueda');

    // Y lo que seguia sigue siendo suyo, leido de nuevo desde el repositorio.
    final suyas = await listings.followedIds(idInvitado);
    expect(suyas, containsAll(<String>['l_1', 'l_3']));
  });

  test('un correo que ya tiene cuenta no se fusiona, y se dice', () async {
    await follows.toggle('l_1');

    final listo = await session.upgrade(
      name: 'Otra Persona',
      email: DummyData.demoEmail, // ya es de Ana
      password: 'ThePassword!1',
      confirmation: 'ThePassword!1',
    );

    expect(listo, isFalse);
    expect(session.error.value, isNotNull);
    // Sigue siendo invitado: no se toco nada.
    expect(session.isGuest, isTrue);
    expect(follows.ids, contains('l_1'));
  });

  test('una cuenta de verdad no pasa por la sesion de invitado', () async {
    await session.login(
      email: DummyData.demoEmail,
      password: DummyData.demoPassword,
    );

    expect(await session.ensureWritableSession(), isTrue);
    expect(session.isGuest, isFalse);
    expect(session.hasAccount, isTrue);
  });

  group('preguntar sin cuenta', () {
    ListingDetailViewModel detalleDe(String listingId) => ListingDetailViewModel(
      listingId: listingId,
      listings: listings,
      qa: QaRepository(InMemoryQaDataSource(data)),
      chats: ChatRepository(InMemoryChatDataSource(data)),
      dispatcher: InMemoryNotificationRepository(),
      follows: follows,
      session: session,
    );

    test('un invitado pregunta, y firma con el nombre que eligio', () async {
      final detalle = detalleDe('l_1');
      await detalle.load();

      // La pantalla pide el nombre antes de dejar preguntar; aqui se simula
      // esa respuesta, que es lo unico que la vista aporta al flujo.
      expect(session.isLoggedIn, isFalse);
      await follows.toggle('l_1'); // abre la sesion de invitado
      expect(session.needsDisplayName, isTrue);
      expect(session.setGuestName('Dani R'), isTrue);

      await detalle.ask('Sigue disponible?');

      expect(detalle.error.value, isNull);
      final mia = detalle.questions.firstWhere(
        (q) => q.text == 'Sigue disponible?',
      );
      // Ni «Invitado», que es como se llama en el servidor.
      expect(mia.askerName, 'Dani R');
      expect(session.isGuest, isTrue);
    });

    test('un nombre demasiado corto no vale como firma', () async {
      await follows.toggle('l_1');

      expect(session.setGuestName('Da'), isFalse);
      expect(session.needsDisplayName, isTrue, reason: 'se le vuelve a pedir');
      expect(session.error.value, isNotNull);
    });

    test('al guardar la cuenta, el nombre elegido deja de hacer falta', () async {
      await follows.toggle('l_1');
      session.setGuestName('Dani R');

      await session.upgrade(
        name: 'Dani Rueda',
        email: 'dani@demo.com',
        password: 'ThePassword!1',
        confirmation: 'ThePassword!1',
      );

      expect(session.guestName.value, isNull);
      // Ahora firma con el de la cuenta, que es uno solo.
      expect(session.displayName, 'Dani Rueda');
      expect(session.needsDisplayName, isFalse);
    });
  });
}
