/// El backend falso: las mismas filas que devolveria Roble, en memoria.
///
/// Guarda **filas**, no entidades, y esa es la gracia: los datasources en
/// memoria devuelven lo mismo que los de Roble, asi que el repositorio —que es
/// uno solo— hace el mismo trabajo en los dos casos. Cuando guardaba entidades,
/// la version local del repositorio tenia que repetir la logica de la de Roble
/// y las pruebas ejercitaban la copia en vez del codigo de verdad.
///
/// Se pierde al cerrar la app. Existe para trabajar en la UI sin servidor y
/// para que las pruebas no necesiten red.
class DummyData {
  DummyData() {
    _seed();
  }

  /// Filas de `user_system`, con lo poco que la app mira de ellas.
  final users = <Map<String, dynamic>>[];
  final passwords = <String, String>{};

  final listings = <Map<String, dynamic>>[];
  final questions = <Map<String, dynamic>>[];
  final follows = <Map<String, dynamic>>[];
  final threads = <Map<String, dynamic>>[];

  /// El catalogo precargado de vehiculos. En Roble lo siembra el proyecto y la
  /// app solo lo lee; aqui se siembra igual, para que el formulario y el
  /// filtro se comporten como con servidor.
  final brands = <Map<String, dynamic>>[];
  final models = <Map<String, dynamic>>[];

  /// Calificaciones entre las dos partes de una venta.
  final ratings = <Map<String, dynamic>>[];

  /// El arbol JSON: `threadId -> {clave: mensaje}`. Las claves van ordenadas
  /// por tiempo, como las que genera el servidor.
  final messages = <String, Map<String, dynamic>>{};

  /// Quien tiene la sesion abierta, o `null`.
  Map<String, dynamic>? session;

  // Arranca por encima de los ids sembrados a mano: si volviera a emitirlos,
  // una fila nueva pisaria una de prueba.
  var _counter = 100;
  String nextId(String prefix) => '${prefix}_${++_counter}';

  /// La cuenta con la que arranca la demo.
  static const demoEmail = 'ana@demo.com';
  static const demoPassword = '123456';

  String _hace(Duration d) =>
      DateTime.now().subtract(d).toUtc().toIso8601String();

  void _seed() {
    users.addAll([
      {'userId': 'u_ana', 'name': 'Ana Torres', 'email': demoEmail},
      {'userId': 'u_beto', 'name': 'Beto Ramirez', 'email': 'beto@demo.com'},
      {'userId': 'u_carla', 'name': 'Carla Mendez', 'email': 'carla@demo.com'},
    ]);
    for (final user in users) {
      passwords[user['email'] as String] = demoPassword;
    }

    listings.addAll([
      {
        '_id': 'l_1',
        'seller_id': 'u_beto',
        'seller_name': 'Beto Ramirez',
        'brand': 'Mazda',
        'model': '3 Grand Touring',
        'year': 2021,
        'price': 78500000,
        'mileage_km': 42000,
        'fuel': 'gasoline',
        'transmission': 'automatic',
        'city': 'Barranquilla',
        'description':
            'Unico dueno, mantenimientos en concesionario, llantas nuevas. '
            'Sin choques ni reparaciones de latoneria.',
        'image_1': 'assets/cars/mazda3_0.png',
        'image_2': 'assets/cars/mazda3_1.png',
        'image_3': 'assets/cars/mazda3_2.png',
        'status': 'available',
        'created_at': _hace(const Duration(days: 2)),
      },
      {
        '_id': 'l_2',
        'seller_id': 'u_carla',
        'seller_name': 'Carla Mendez',
        'brand': 'Renault',
        'model': 'Duster Intens',
        'year': 2019,
        'price': 56900000,
        'mileage_km': 88500,
        'fuel': 'gasoline',
        'transmission': 'manual',
        'city': 'Bogota',
        'description':
            'Camioneta familiar, ideal para carretera. Soat y tecnomecanica '
            'al dia hasta diciembre.',
        'image_1': 'assets/cars/duster_0.png',
        'image_2': 'assets/cars/duster_1.png',
        'status': 'reserved',
        'created_at': _hace(const Duration(days: 6)),
      },
      {
        '_id': 'l_3',
        'seller_id': 'u_beto',
        'seller_name': 'Beto Ramirez',
        'brand': 'Chevrolet',
        'model': 'Onix Turbo',
        'year': 2023,
        'price': 64200000,
        'mileage_km': 15300,
        'fuel': 'gasoline',
        'transmission': 'automatic',
        'city': 'Medellin',
        'description': 'Practicamente nuevo, aun con garantia de fabrica.',
        'image_1': 'assets/cars/onix_0.png',
        'status': 'available',
        'created_at': _hace(const Duration(days: 1)),
      },
      {
        '_id': 'l_4',
        'seller_id': 'u_ana',
        'seller_name': 'Ana Torres',
        'brand': 'Toyota',
        'model': 'Corolla Cross Hybrid',
        'year': 2022,
        'price': 132000000,
        'mileage_km': 31000,
        'fuel': 'hybrid',
        'transmission': 'automatic',
        'city': 'Barranquilla',
        'description':
            'Hibrida, consumo real de 20 km/galon en ciudad. Recibo carro de '
            'menor valor.',
        'image_1': 'assets/cars/corolla_0.png',
        'image_2': 'assets/cars/corolla_1.png',
        'status': 'available',
        'created_at': _hace(const Duration(days: 9)),
      },
      {
        '_id': 'l_5',
        'seller_id': 'u_carla',
        'seller_name': 'Carla Mendez',
        'brand': 'Kia',
        'model': 'Picanto',
        'year': 2018,
        'price': 38000000,
        'mileage_km': 96000,
        'fuel': 'gasoline',
        'transmission': 'manual',
        'city': 'Cali',
        'description': 'Economico y facil de parquear. Motor y caja perfectos.',
        'image_1': 'assets/cars/picanto_0.png',
        'image_2': 'assets/cars/picanto_1.png',
        'status': 'sold',
        'buyer_id': 'u_ana',
        'buyer_name': 'Ana Torres',
        'sold_at': _hace(const Duration(days: 12)),
        'created_at': _hace(const Duration(days: 20)),
      },
      {
        // Sin fotos a proposito: es lo que se ve mientras no haya
        // almacenamiento, y deja probar el relleno de color de `CarPhoto`.
        '_id': 'l_6',
        'seller_id': 'u_beto',
        'seller_name': 'Beto Ramirez',
        'brand': 'Nissan',
        'model': 'Versa Sense',
        'year': 2020,
        'price': 52400000,
        'mileage_km': 61000,
        'fuel': 'gasoline',
        'transmission': 'automatic',
        'city': 'Cartagena',
        'description':
            'Publicacion sin fotos: sirve para ver como se ve una tarjeta '
            'cuando el vendedor aun no ha subido ninguna.',
        'status': 'available',
        'created_at': _hace(const Duration(days: 4)),
      },
    ]);

    _seedVehicles();

    ratings.addAll([
      {
        '_id': 'r_1',
        'listing_id': 'l_5',
        'rater_id': 'u_ana',
        'rater_name': 'Ana Torres',
        'rated_id': 'u_carla',
        'rated_role': 'seller',
        'stars': 5,
        'comment': 'Todo tal como lo describio, y me ayudo con el traspaso.',
        'created_at': _hace(const Duration(days: 11)),
      },
      {
        '_id': 'r_2',
        'listing_id': 'l_5',
        'rater_id': 'u_carla',
        'rater_name': 'Carla Mendez',
        'rated_id': 'u_ana',
        'rated_role': 'buyer',
        'stars': 4,
        'comment': 'Compradora seria, aunque llego tarde a la cita.',
        'created_at': _hace(const Duration(days: 11)),
      },
    ]);

    questions.addAll([
      {
        '_id': 'q_1',
        'listing_id': 'l_1',
        'asker_id': 'u_ana',
        'asker_name': 'Ana Torres',
        'body': 'Hola, se puede ver en Barranquilla el fin de semana?',
        'created_at': _hace(const Duration(hours: 30)),
        'answer_body':
            'Claro, el sabado en la manana. Te escribo por chat privado.',
        'answer_by': 'u_beto',
        'answer_by_name': 'Beto Ramirez',
        'answered_at': _hace(const Duration(hours: 27)),
      },
      {
        '_id': 'q_2',
        'listing_id': 'l_1',
        'asker_id': 'u_carla',
        'asker_name': 'Carla Mendez',
        'body': 'Acepta parte de pago con una moto?',
        'created_at': _hace(const Duration(hours: 5)),
      },
      {
        '_id': 'q_3',
        'listing_id': 'l_2',
        'asker_id': 'u_ana',
        'asker_name': 'Ana Torres',
        'body': 'Cuantos duenos ha tenido?',
        'created_at': _hace(const Duration(days: 1)),
      },
    ]);

    follows.addAll([
      {
        '_id': 'f_1',
        'listing_id': 'l_1',
        'user_id': 'u_ana',
        'created_at': _hace(const Duration(days: 2)),
      },
      {
        '_id': 'f_2',
        'listing_id': 'l_2',
        'user_id': 'u_ana',
        'created_at': _hace(const Duration(days: 1)),
      },
    ]);

    threads.add({
      '_id': 't_1',
      'listing_id': 'l_1',
      'listing_title': 'Mazda 3 Grand Touring 2021',
      'listing_cover': 'assets/cars/mazda3_0.png',
      'buyer_id': 'u_ana',
      'buyer_name': 'Ana Torres',
      'seller_id': 'u_beto',
      'seller_name': 'Beto Ramirez',
      'created_at': _hace(const Duration(hours: 5)),
      'last_message': 'Perfecto, nos vemos el sabado a las 9.',
      'last_message_at': _hace(const Duration(hours: 3)),
      'buyer_muted': false,
      'seller_muted': false,
      'buyer_unread': 1,
      'seller_unread': 0,
    });

    messages['t_1'] = {
      'm_001': {
        'sender_id': 'u_ana',
        'sender_name': 'Ana Torres',
        'text': 'Buenas, sigue disponible?',
        'sent_at': _hace(const Duration(hours: 5)),
      },
      'm_002': {
        'sender_id': 'u_beto',
        'sender_name': 'Beto Ramirez',
        'text': 'Si, disponible. Cuando quieres verlo?',
        'sent_at': _hace(const Duration(hours: 4)),
      },
      'm_003': {
        'sender_id': 'u_beto',
        'sender_name': 'Beto Ramirez',
        'text': 'Perfecto, nos vemos el sabado a las 9.',
        'sent_at': _hace(const Duration(hours: 3)),
      },
    };
  }

  /// Un recorte del catalogo que hay en Roble: basta para que la tira de
  /// marcas se pueda arrastrar y para que cada marca tenga modelos.
  void _seedVehicles() {
    const catalogo = <String, List<String>>{
      'Chevrolet': ['Spark GT', 'Onix', 'Onix Turbo', 'Sail', 'Tracker'],
      'Renault': ['Sandero', 'Logan', 'Stepway', 'Duster Intens', 'Kwid'],
      'Mazda': ['Mazda 2', '3 Grand Touring', 'CX-3', 'CX-30', 'CX-5'],
      'Toyota': ['Corolla', 'Corolla Cross Hybrid', 'Yaris', 'RAV4', 'Hilux'],
      'Kia': ['Picanto', 'Rio', 'Sportage', 'Seltos', 'Soluto'],
      'Nissan': ['March', 'Versa Sense', 'Kicks', 'Qashqai', 'Frontier'],
      'Hyundai': ['Grand i10', 'Accent', 'Tucson', 'Creta', 'Venue'],
      'Ford': ['Fiesta', 'Focus', 'EcoSport', 'Escape', 'Ranger'],
      'Volkswagen': ['Gol', 'Polo', 'Virtus', 'T-Cross', 'Amarok'],
      'Suzuki': ['Swift', 'Baleno', 'Vitara', 'S-Cross', 'Jimny'],
    };

    var orden = 0;
    for (final entry in catalogo.entries) {
      final brandId = 'b_${orden + 1}';
      brands.add({'_id': brandId, 'name': entry.key, 'sort_order': orden, 'active': true});
      var ordenModelo = 0;
      for (final modelo in entry.value) {
        models.add({
          '_id': 'cm_${brands.length}_${ordenModelo + 1}',
          'brand_id': brandId,
          'name': modelo,
          'sort_order': ordenModelo,
          'active': true,
        });
        ordenModelo++;
      }
      orden++;
    }
  }
}
