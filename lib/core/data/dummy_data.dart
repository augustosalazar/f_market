import 'dart:async';

import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/auth/domain/models/app_user.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/qa/domain/models/question.dart';

/// La fuente de datos local de la fase 1: todo vive en memoria y se pierde al
/// cerrar la app. Existe para poder construir y probar la UI completa antes de
/// conectar Roble; los repositorios de Roble la reemplazaran sin que la UI ni
/// los casos de uso cambien.
///
/// Las fotos son las ilustraciones de `assets/cars/`: hacen las veces de lo
/// que subiria un vendedor. La ultima publicacion va a proposito sin fotos,
/// para poder ver el relleno de color de `CarPhoto`.
class DummyData {
  DummyData() {
    _seed();
  }

  final List<AppUser> users = [];
  final Map<String, String> passwords = {};
  final List<CarListing> listings = [];
  final List<Question> questions = [];
  final List<ChatThread> threads = [];
  final Map<String, List<ChatMessage>> messages = {};
  final Map<String, Set<String>> followers = {};
  /// Bandeja por usuario: la notificacion es de quien la recibe.
  final Map<String, List<AppNotification>> notifications = {};

  final _notificationEvents =
      StreamController<(String, AppNotification)>.broadcast();
  Stream<(String, AppNotification)> get notificationEvents =>
      _notificationEvents.stream;

  AppUser? session;

  // Arranca por encima de los ids sembrados a mano (`l_1`, `t_1`, `m_3`...):
  // si volviera a emitirlos, una fila nueva pisaria una de prueba.
  var _counter = 100;
  String nextId(String prefix) => '${prefix}_${++_counter}';

  void emit(String userId, AppNotification notification) {
    notifications.putIfAbsent(userId, () => []).insert(0, notification);
    _notificationEvents.add((userId, notification));
  }

  /// El usuario con el que arranca la demo: `ana@demo.com` / `123456`.
  static const demoEmail = 'ana@demo.com';
  static const demoPassword = '123456';

  void _seed() {
    final ana = AppUser(
      userId: 'u_ana',
      name: 'Ana Torres',
      email: demoEmail,
    );
    final beto = AppUser(
      userId: 'u_beto',
      name: 'Beto Ramirez',
      email: 'beto@demo.com',
    );
    final carla = AppUser(
      userId: 'u_carla',
      name: 'Carla Mendez',
      email: 'carla@demo.com',
    );
    users.addAll([ana, beto, carla]);
    passwords.addAll({
      ana.email: demoPassword,
      beto.email: demoPassword,
      carla.email: demoPassword,
    });

    final now = DateTime.now();
    listings.addAll([
      CarListing(
        id: 'l_1',
        sellerId: beto.userId,
        sellerName: beto.name,
        brand: 'Mazda',
        model: '3 Grand Touring',
        year: 2021,
        price: 78500000,
        mileageKm: 42000,
        fuel: FuelType.gasoline,
        transmission: TransmissionType.automatic,
        city: 'Barranquilla',
        description:
            'Unico dueno, mantenimientos en concesionario, llantas nuevas. '
            'Sin choques ni reparaciones de latoneria.',
        images: const [
          'assets/cars/mazda3_0.png',
          'assets/cars/mazda3_1.png',
          'assets/cars/mazda3_2.png',
        ],
        status: ListingStatus.available,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      CarListing(
        id: 'l_2',
        sellerId: carla.userId,
        sellerName: carla.name,
        brand: 'Renault',
        model: 'Duster Intens',
        year: 2019,
        price: 56900000,
        mileageKm: 88500,
        fuel: FuelType.gasoline,
        transmission: TransmissionType.manual,
        city: 'Bogota',
        description:
            'Camioneta familiar, ideal para carretera. Soat y tecnomecanica '
            'al dia hasta diciembre.',
        images: const ['assets/cars/duster_0.png', 'assets/cars/duster_1.png'],
        status: ListingStatus.reserved,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      CarListing(
        id: 'l_3',
        sellerId: beto.userId,
        sellerName: beto.name,
        brand: 'Chevrolet',
        model: 'Onix Turbo',
        year: 2023,
        price: 64200000,
        mileageKm: 15300,
        fuel: FuelType.gasoline,
        transmission: TransmissionType.automatic,
        city: 'Medellin',
        description: 'Practicamente nuevo, aun con garantia de fabrica.',
        images: const ['assets/cars/onix_0.png'],
        status: ListingStatus.available,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CarListing(
        id: 'l_4',
        sellerId: ana.userId,
        sellerName: ana.name,
        brand: 'Toyota',
        model: 'Corolla Cross Hybrid',
        year: 2022,
        price: 132000000,
        mileageKm: 31000,
        fuel: FuelType.hybrid,
        transmission: TransmissionType.automatic,
        city: 'Barranquilla',
        description:
            'Hibrida, consumo real de 20 km/galon en ciudad. Recibo carro de '
            'menor valor.',
        images: const ['assets/cars/corolla_0.png', 'assets/cars/corolla_1.png'],
        status: ListingStatus.available,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      CarListing(
        id: 'l_5',
        sellerId: carla.userId,
        sellerName: carla.name,
        brand: 'Kia',
        model: 'Picanto',
        year: 2018,
        price: 38000000,
        mileageKm: 96000,
        fuel: FuelType.gasoline,
        transmission: TransmissionType.manual,
        city: 'Cali',
        description: 'Economico y facil de parquear. Motor y caja perfectos.',
        images: const ['assets/cars/picanto_0.png', 'assets/cars/picanto_1.png'],
        status: ListingStatus.sold,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      CarListing(
        id: 'l_6',
        sellerId: beto.userId,
        sellerName: beto.name,
        brand: 'Nissan',
        model: 'Versa Sense',
        year: 2020,
        price: 52400000,
        mileageKm: 61000,
        fuel: FuelType.gasoline,
        transmission: TransmissionType.automatic,
        city: 'Cartagena',
        description:
            'Publicacion sin fotos todavia: sirve para ver como se ve una '
            'tarjeta cuando el vendedor aun no ha subido ninguna.',
        images: const [],
        status: ListingStatus.available,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ]);

    questions.addAll([
      Question(
        id: 'q_1',
        listingId: 'l_1',
        askerId: ana.userId,
        askerName: ana.name,
        text: 'Hola, se puede ver en Barranquilla el fin de semana?',
        createdAt: now.subtract(const Duration(hours: 30)),
        answer: Answer(
          responderId: beto.userId,
          responderName: beto.name,
          text: 'Claro, el sabado en la manana. Te escribo por chat privado.',
          createdAt: now.subtract(const Duration(hours: 27)),
        ),
      ),
      Question(
        id: 'q_2',
        listingId: 'l_1',
        askerId: carla.userId,
        askerName: carla.name,
        text: 'Acepta parte de pago con una moto?',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Question(
        id: 'q_3',
        listingId: 'l_2',
        askerId: ana.userId,
        askerName: ana.name,
        text: 'Cuantos duenos ha tenido?',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    followers['l_1'] = {ana.userId};
    followers['l_2'] = {ana.userId};

    threads.add(
      ChatThread(
        id: 't_1',
        listingId: 'l_1',
        listingTitle: 'Mazda 3 Grand Touring 2021',
        listingCover: 'assets/cars/mazda3_0.png',
        buyerId: ana.userId,
        buyerName: ana.name,
        sellerId: beto.userId,
        sellerName: beto.name,
        lastMessage: 'Perfecto, nos vemos el sabado a las 9.',
        lastMessageAt: now.subtract(const Duration(hours: 3)),
        unreadCount: 1,
        muted: false,
      ),
    );
    messages['t_1'] = [
      ChatMessage(
        id: 'm_1',
        threadId: 't_1',
        senderId: ana.userId,
        senderName: ana.name,
        text: 'Buenas, sigue disponible?',
        sentAt: now.subtract(const Duration(hours: 5)),
      ),
      ChatMessage(
        id: 'm_2',
        threadId: 't_1',
        senderId: beto.userId,
        senderName: beto.name,
        text: 'Si, disponible. Cuando quieres verlo?',
        sentAt: now.subtract(const Duration(hours: 4)),
      ),
      ChatMessage(
        id: 'm_3',
        threadId: 't_1',
        senderId: beto.userId,
        senderName: beto.name,
        text: 'Perfecto, nos vemos el sabado a las 9.',
        sentAt: now.subtract(const Duration(hours: 3)),
      ),
    ];

    notifications[ana.userId] = [
      AppNotification(
        id: 'n_1',
        kind: NotificationKind.chatMessage,
        title: beto.name,
        body: 'Perfecto, nos vemos el sabado a las 9.',
        createdAt: now.subtract(const Duration(hours: 3)),
        read: false,
        listingId: 'l_1',
        threadId: 't_1',
      ),
      AppNotification(
        id: 'n_2',
        kind: NotificationKind.answer,
        title: 'Mazda 3 Grand Touring 2021',
        body: '${beto.name} respondio: Claro, el sabado en la manana.',
        createdAt: now.subtract(const Duration(hours: 27)),
        read: false,
        listingId: 'l_1',
      ),
      AppNotification(
        id: 'n_3',
        kind: NotificationKind.statusChange,
        title: 'Renault Duster Intens 2019',
        body: 'La publicacion ahora esta reservado.',
        createdAt: now.subtract(const Duration(days: 1)),
        read: true,
        listingId: 'l_2',
      ),
    ];
  }
}
