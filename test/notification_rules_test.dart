import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/in_memory_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/data/datasources/in_memory_chat_data_source.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/chat/ui/viewmodels/chat_view_model.dart';
import 'package:f_roble_market/features/listings/data/datasources/in_memory_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/listing_detail_view_model.dart';
import 'package:f_roble_market/features/notifications/data/repositories/in_memory_notification_repository.dart';
import 'package:f_roble_market/features/qa/data/datasources/in_memory_qa_data_source.dart';
import 'package:f_roble_market/features/qa/data/repositories/qa_repository.dart';

/// Las reglas de a quien se le avisa son el corazon de los requisitos 6, 7 y
/// 8, y ahora viven en los controladores. Se prueban contra la fuente local,
/// sin Flutter: por eso los view models publican los avisos en un `RxnString`
/// en vez de llamar a `Get.snackbar`.
void main() {
  late DummyData data;
  late ListingRepository listings;
  late ChatRepository chats;
  late InMemoryNotificationRepository notifications;
  late SessionViewModel session;

  Future<SessionViewModel> sessionOf(String email) async {
    final vm = SessionViewModel(AuthRepository(InMemoryAuthDataSource(data)));
    await vm.login(email: email, password: DummyData.demoPassword);
    return vm;
  }

  ListingDetailViewModel detailOf(String listingId) => ListingDetailViewModel(
    listingId: listingId,
    listings: listings,
    qa: QaRepository(InMemoryQaDataSource(data)),
    chats: chats,
    dispatcher: notifications,
    follows: FollowsViewModel(listings, session),
    session: session,
  );

  setUp(() async {
    data = DummyData();
    // Los mismos repositorios que usa la app, con los datasources de memoria:
    // asi lo que se prueba es el codigo que corre de verdad.
    listings = ListingRepository(InMemoryListingDataSource(data));
    chats = ChatRepository(InMemoryChatDataSource(data));
    notifications = InMemoryNotificationRepository();
    session = await sessionOf('carla@demo.com');
  });

  test('preguntar avisa al vendedor y a quien sigue, nunca a quien pregunta',
      () async {
    // Ana sigue l_1 en los datos de prueba; Beto es el vendedor.
    final detail = detailOf('l_1');
    await detail.load();

    await detail.ask('Recibe permuta?');

    expect(detail.error.value, isNull);
    // Ana sigue l_1, asi que le llega por seguirla; Beto por vender. Carla,
    // que es quien pregunto, no recibe nada.
    expect(await notifications.forUser('u_beto'), hasLength(1));
    expect(await notifications.forUser('u_ana'), hasLength(1));
    expect(await notifications.forUser('u_carla'), isEmpty);
  });

  test('el vendedor no puede preguntar en su propia publicacion', () async {
    session = await sessionOf('beto@demo.com');
    final detail = detailOf('l_1');
    await detail.load();

    await detail.ask('Hola');

    expect(detail.error.value, contains('tu propia publicacion'));
    // Nadie recibe nada: la pregunta ni se llego a publicar.
    expect(await notifications.forUser('u_ana'), isEmpty);
  });

  test('cambiar el estado avisa a los seguidores, no al vendedor', () async {
    session = await sessionOf('beto@demo.com');
    final detail = detailOf('l_1');
    await detail.load();

    await detail.changeStatus(ListingStatus.reserved);

    expect(detail.listing.value?.status.name, 'reserved');
    expect(await notifications.forUser('u_ana'), hasLength(1));
    expect(await notifications.forUser('u_beto'), isEmpty);
  });

  test('abrir un chat nuevo no pisa uno sembrado', () async {
    // Los ids generados no pueden chocar con los sembrados: un `t_1` nuevo
    // sobrescribia el chat de prueba y la pantalla mostraba la publicacion
    // equivocada.
    final nuevo = await chats.openThread(listingId: 'l_3', buyerId: 'u_ana');

    expect(nuevo.id, isNot('t_1'));
    expect(nuevo.listingTitle, 'Chevrolet Onix Turbo 2023');
    expect(await chats.messagesOf('t_1'), hasLength(3));
  });

  test('un chat silenciado no genera aviso; uno activo si', () async {
    session = await sessionOf(DummyData.demoEmail);
    final chat = ChatViewModel(
      threadId: 't_1',
      chats: chats,
      dispatcher: notifications,
      session: session,
    );
    await chat.load();

    await chat.send('Sigue disponible?');
    expect(await notifications.forUser('u_beto'), hasLength(1));

    await chat.toggleMuted();
    await chat.send('Otro mensaje');
    expect(await notifications.forUser('u_beto'), hasLength(1));
  });
}
