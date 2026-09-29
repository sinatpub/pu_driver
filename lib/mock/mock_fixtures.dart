import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/mock/mock_geo.dart';

/// Static mock data: places in Phnom Penh, the driver account, the
/// passenger, vehicle types, and the shape of every JSON payload the mock
/// backend returns. Payload shapes mirror what the app's models parse
/// (`lib/data/models`, `lib/presentation/screens/*/data/models`) — string vs
/// number matters, because several call sites `double.parse(x.toString())`.
class MockPlace {
  const MockPlace(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;
  LatLng get latLng => LatLng(latitude, longitude);
}

class MockPlaces {
  MockPlaces._();

  static const watPhnom =
      MockPlace('Wat Phnom, Daun Penh, Phnom Penh', 11.5763, 104.9231);
  static const centralMarket = MockPlace(
      'Central Market (Phsar Thmei), Daun Penh, Phnom Penh', 11.5696, 104.9210);
  static const airport = MockPlace(
      'Phnom Penh International Airport, Pou Senchey, Phnom Penh',
      11.5466,
      104.8441);
  static const independenceMonument = MockPlace(
      'Independence Monument, Chamkar Mon, Phnom Penh', 11.5564, 104.9282);
  static const russianMarket = MockPlace(
      'Russian Market (Phsar Toul Tom Poung), Chamkar Mon, Phnom Penh',
      11.5439,
      104.9181);
  static const aeonMall = MockPlace(
      'AEON Mall Phnom Penh, Tonle Bassac, Phnom Penh', 11.5486, 104.9332);
  static const royalPalace =
      MockPlace('Royal Palace, Sothearos Blvd, Phnom Penh', 11.5637, 104.9311);

  /// Where the mock driver waits for requests.
  static const MockPlace driverStart = watPhnom;
  static const MockPlace pickup = centralMarket;
  static const MockPlace destination = airport;

  static const all = [
    watPhnom,
    centralMarket,
    airport,
    independenceMonument,
    russianMarket,
    aeonMall,
    royalPalace,
  ];

  /// The name of a known place within [radiusMeters] of [point], if any.
  static String? nameNear(LatLng point, {double radiusMeters = 250}) {
    for (final place in all) {
      if (distanceMeters(point, place.latLng) <= radiusMeters) {
        return place.name;
      }
    }
    return null;
  }

  /// Central Market → airport along Russian Federation Boulevard.
  static const List<LatLng> airportCorridor = [
    LatLng(11.5699, 104.9168),
    LatLng(11.5690, 104.9125),
    LatLng(11.5672, 104.9005),
    LatLng(11.5641, 104.8890),
    LatLng(11.5598, 104.8745),
    LatLng(11.5553, 104.8620),
    LatLng(11.5510, 104.8512),
    LatLng(11.5480, 104.8462),
  ];
}

/// The route the mock "Directions API" returns and the simulated GPS follows.
/// Deterministic, so the polyline on the map and the car on it always agree.
List<LatLng> mockRoute(LatLng from, LatLng to) {
  bool near(LatLng a, LatLng b) => distanceMeters(a, b) < 400;
  final List<LatLng> waypoints;
  if (near(from, MockPlaces.pickup.latLng) &&
      near(to, MockPlaces.destination.latLng)) {
    waypoints = [from, ...MockPlaces.airportCorridor, to];
  } else if (near(from, MockPlaces.destination.latLng) &&
      near(to, MockPlaces.pickup.latLng)) {
    waypoints = [from, ...MockPlaces.airportCorridor.reversed, to];
  } else {
    // An L-shaped, grid-like path: along one axis, then the other.
    waypoints = [from, LatLng(to.latitude, from.longitude), to];
  }
  return densify(waypoints);
}

class MockData {
  MockData._();

  static const String token = 'mock-token-qa-only';
  static const int driverId = 1024;
  static const int passengerId = 5001;

  /// Mock ride ids start here. The app parses ids and booking codes as
  /// integers, so a `MOCK-` prefix is impossible — a 99xxxx id is the tell.
  static const int firstRideId = 990001;

  static const int vehicleTypeId = 2; // Classic car — see `typeVehicle()`.
  static const int pricePerKm = 1500; // riel
  static const int minimumFare = 6000; // riel

  static String timestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  static Map<String, dynamic> location(LatLng p) => {
        'latitude': p.latitude.toStringAsFixed(6),
        'longitude': p.longitude.toStringAsFixed(6),
      };

  static Map<String, dynamic> vehicle() => {
        'id': 88,
        'type_vehicle_id': vehicleTypeId,
        'vehicle_price': pricePerKm,
        'model': 'Prius',
        'manufacturer': 'Toyota',
        'year_of_manufacture': 2016,
        'color': 'White',
        'plate_number': '2AB-1234',
        'engine_power': '1.8L Hybrid',
        'max_passenger': 4,
        'status': 1,
        'vehicle_image': <dynamic>[],
      };

  static Map<String, dynamic> driver({
    required int approvalCode,
    required LatLng position,
  }) =>
      {
        'id': driverId,
        'driver_id': 'DRV-$driverId',
        'name': 'Dara Sok',
        'first_name': 'Dara',
        'last_name': 'Sok',
        'email': 'dara.sok@example.com',
        'gender': 1,
        'dob': '1990-05-12',
        'country_code': '+855',
        'phone': '012345678',
        'card_type': 1,
        'card_number': '010203040',
        'card_image': '',
        'driver_license_number': 'PP-123456',
        'driver_license_expired': '2029-12-31',
        'driver_license_image': '',
        'status': approvalCode,
        'status_date': '2026-01-15 09:30:00',
        'profile_image': '',
        'role_id': 2,
        'vehicle': vehicle(),
        'last_location': location(position),
      };

  static Map<String, dynamic> passenger({LatLng? position}) => {
        'id': passengerId,
        'name': 'Sreymom Chan',
        'first_name': 'Sreymom',
        'last_name': 'Chan',
        'email': 'sreymom.chan@example.com',
        'gender': 2,
        'dob': '1996-08-03',
        'country_code': '+855',
        'phone': '098765432',
        'card_type': null,
        'card_number': null,
        'card_image': null,
        'status': 1,
        'status_date': '2025-11-02 14:10:00',
        'role_id': 3,
        'profile_image': '',
        'last_location': position == null ? null : location(position),
      };

  static List<Map<String, dynamic>> vehicleTypes() {
    const created = '2025-01-01T00:00:00.000000Z';
    Map<String, dynamic> type(int id, String name, int price, int minimum) => {
          'id': id,
          'name': name,
          'price': price,
          'minimum_fare': minimum,
          'image': null,
          'created_at': created,
          'updated_at': created,
        };
    return [
      type(1, 'Rickshaw', 1000, 4000),
      type(2, 'Classic Car', pricePerKm, minimumFare),
      type(3, 'Mini Van', 2000, 8000),
      type(4, 'SUV', 2500, 10000),
      type(5, 'Alphard VIP', 5000, 20000),
    ];
  }

  static List<Map<String, dynamic>> vehicleColors() => [
        for (final (i, name, code) in [
          (1, 'White', '#FFFFFF'),
          (2, 'Black', '#000000'),
          (3, 'Silver', '#C0C0C0'),
          (4, 'Blue', '#1E4FD8'),
        ])
          {
            'id': i,
            'name': name,
            'color_code': code,
            'created_at': null,
            'updated_at': null,
          }
      ];

  static Map<String, dynamic> version() => {
        'message': 'Success',
        'data': {
          'id': 1,
          'app_type': 1,
          // Matches HomeLogic's pinned version, so no update prompt appears.
          'release_date': '2026-04-25',
          'release_date_ios': '2026-04-25',
          'version_android': '1.1.9',
          'version_ios': '1.1.9',
          'play_store_link': '',
          'app_store_link': '',
          'features_release': '',
          'is_active': 1,
        },
      };

  static List<Map<String, dynamic>> announcements() {
    Map<String, dynamic> item(
            int id, String title, String description, String date) =>
        {
          'id': id,
          'title': title,
          'description': description,
          'release_date': date,
          'expired_date': '2026-12-31',
          'target': 2,
          'status': 1,
          'created_by': 1,
          'created_at': '$date 08:00:00',
          'updated_at': '$date 08:00:00',
          'files': <dynamic>[],
        };
    return [
      item(
          3,
          'Pchum Ben holiday bonus',
          'Complete 20 trips between 20 and 24 September and earn a 30,000 riel bonus in your wallet.',
          '2026-09-15'),
      item(
          2,
          'Airport pickup zone has moved',
          'Pickups at Phnom Penh International Airport now use the new ride-hailing bay at Gate B. Please wait there for your passenger.',
          '2026-09-02'),
      item(
          1,
          'App update 1.1.9',
          'This version improves GPS accuracy during trips and fixes a crash when collecting payment.',
          '2026-04-25'),
    ];
  }

  static Map<String, dynamic> wallet({
    required int balance,
    required List<Map<String, dynamic>> transactions,
  }) =>
      {
        'id': 77,
        'balance': balance,
        'debted': 0,
        'commission_fare': 10,
        'currency': 'KHR',
        'transactions': transactions,
      };

  static Map<String, dynamic> transaction({
    required int id,
    required String typeName,
    required int amount,
    required DateTime at,
    int? referenceId,
  }) =>
      {
        'id': id,
        'type': typeName == 'Top Up' ? 1 : 2,
        'type_name': typeName,
        'amount': amount,
        'currency': 'KHR',
        'status': 1,
        'status_name': 'Success',
        'reference_id': referenceId,
        'created_by': driverId,
        'created_at': timestamp(at),
      };
}
