import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/in_memory_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/data/datasources/in_memory_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/profiles/data/datasources/in_memory_rating_data_source.dart';
import 'package:f_roble_market/features/profiles/data/repositories/rating_repository.dart';
import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';
import 'package:f_roble_market/features/profiles/domain/profile_failure.dart';
import 'package:f_roble_market/features/profiles/ui/viewmodels/user_profile_view_model.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/in_memory_vehicle_catalog_data_source.dart';
import 'package:f_roble_market/features/vehicles/data/repositories/vehicle_catalog_repository.dart';

/// El historial y las calificaciones cuelgan de una sola cosa: que la venta
/// registre **quien compro**. Sin eso no hay compras que listar ni forma de
/// saber quien tiene derecho a calificar.
void main() {
  late DummyData data;
  late ListingRepository listings;
  late RatingRepository ratings;

  setUp(() {
    data = DummyData();
    listings = ListingRepository(InMemoryListingDataSource(data));
    ratings = RatingRepository(InMemoryRatingDataSource(data));
  });

  Future<SessionViewModel> sessionOf(String email) async {
    final vm = SessionViewModel(AuthRepository(InMemoryAuthDataSource(data)));
    await vm.login(email: email, password: DummyData.demoPassword);
    return vm;
  }

  group('catalogo de vehiculos', () {
    test('las marcas y sus modelos salen del catalogo precargado', () async {
      final catalogo = VehicleCatalogRepository(
        InMemoryVehicleCatalogDataSource(data),
      );

      final marcas = await catalogo.brands();
      expect(marcas, isNotEmpty);
      // Ordenadas por `sort_order`: las mas vendidas primero, que es lo que
      // hace util la tira horizontal.
      expect(marcas.first.name, 'Chevrolet');

      final modelos = await catalogo.modelsOf(marcas.first.id);
      expect(modelos.map((m) => m.name), contains('Onix Turbo'));
      // Los modelos son de esa marca y de ninguna otra.
      expect(modelos.every((m) => m.brandId == marcas.first.id), isTrue);
    });
  });

  group('venta con comprador', () {
    test('cerrarla la deja en el historial de compras del comprador', () async {
      // l_1 es de Beto; Ana se lo compra.
      await listings.markSold(
        listingId: 'l_1',
        buyerId: 'u_ana',
        buyerName: 'Ana Torres',
      );

      final compras = await listings.purchasesOf('u_ana');
      expect(compras.map((l) => l.id), contains('l_1'));
      expect(compras.first.hasRegisteredSale, isTrue);

      final deBeto = await listings.bySeller('u_beto');
      final vendida = deBeto.firstWhere((l) => l.id == 'l_1');
      expect(vendida.status, ListingStatus.sold);
      expect(vendida.buyerName, 'Ana Torres');
    });

    test('sacarla de vendido borra al comprador', () async {
      await listings.markSold(
        listingId: 'l_1',
        buyerId: 'u_ana',
        buyerName: 'Ana Torres',
      );

      await listings.changeStatus('l_1', ListingStatus.available);

      // Si no se borrara, la publicacion volveria al catalogo pero seguiria
      // contando como una compra de Ana. (l_5 sigue ahi: esa si la compro.)
      final compras = await listings.purchasesOf('u_ana');
      expect(compras.map((l) => l.id), isNot(contains('l_1')));
      expect(compras.map((l) => l.id), contains('l_5'));
    });
  });

  group('calificaciones', () {
    test('solo se puede calificar una vez la misma venta', () async {
      // l_5 ya esta vendida a Ana en los datos de prueba, y ella ya califico.
      expect(
        () => ratings.rate(
          listingId: 'l_5',
          raterId: 'u_ana',
          raterName: 'Ana Torres',
          ratedId: 'u_carla',
          ratedRole: RatedRole.seller,
          stars: 1,
          comment: 'Otra vez',
        ),
        throwsA(isA<ProfileFailure>()),
      );
    });

    test('el promedio y el historial se ven en el perfil', () async {
      final session = await sessionOf('beto@demo.com');
      final perfil = UserProfileViewModel(
        userId: 'u_carla',
        userName: 'Carla Mendez',
        listings: listings,
        ratings: ratings,
        session: session,
      );
      await perfil.load();

      expect(perfil.sold.map((l) => l.id), contains('l_5'));
      expect(perfil.average, 5.0);
      expect(perfil.received.single.raterName, 'Ana Torres');
      // Beto no le ha comprado ni vendido nada a Carla: no puede calificarla.
      expect(perfil.pending, isEmpty);
    });

    test('quien compro puede calificar, y solo esa venta', () async {
      final session = await sessionOf('beto@demo.com');
      // Ana le vende l_4 a Beto.
      await listings.markSold(
        listingId: 'l_4',
        buyerId: 'u_beto',
        buyerName: 'Beto Ramirez',
      );

      final perfil = UserProfileViewModel(
        userId: 'u_ana',
        userName: 'Ana Torres',
        listings: listings,
        ratings: ratings,
        session: session,
      );
      await perfil.load();

      final pendiente = perfil.pending.single;
      expect(pendiente.listing.id, 'l_4');
      // A Ana se la califica como vendedora: fue ella quien vendio.
      expect(pendiente.role, RatedRole.seller);

      await perfil.rate(pending: pendiente, stars: 4, comment: 'Cumplida');

      expect(perfil.error.value, isNull);
      expect(perfil.average, 4.0);
      // Y ya no queda nada por calificar: una por venta.
      expect(perfil.pending, isEmpty);
    });
  });
}
