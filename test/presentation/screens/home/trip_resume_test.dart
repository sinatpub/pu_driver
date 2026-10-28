import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/contracts/booking_status.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:pu_taxi_driver/presentation/screens/home/trip_resume.dart';

/// Audit D-6, D-7 — reopening a trip from `get-current-drive-info`.
DataDriverInfo _trip(Map<String, dynamic> overrides) =>
    DataDriverInfo.fromJson(<String, dynamic>{
      'id': 41,
      'booking_code': '7788',
      'start_latitude': '11.55',
      'start_longitude': '104.92',
      'end_latitude': '11.57',
      'end_longitude': '104.93',
      'status': BookingStatus.accepted,
      'passenger': <String, dynamic>{
        'id': 9,
        'name': 'Sokha',
        'phone': '012345678',
        'last_location': <String, dynamic>{
          'latitude': '11.551',
          'longitude': '104.921',
        },
      },
      'driver': <String, dynamic>{
        'vehicle': <String, dynamic>{'type_vehicle_id': 2},
        'last_location': <String, dynamic>{
          'latitude': '11.54',
          'longitude': '104.91',
        },
      },
      ...overrides,
    });

void main() {
  group('resumeStage', () {
    test('an accepted, unfinished trip reopens at its stage', () {
      expect(resumeStage(BookingStatus.accepted), TripStage.enRouteToPickup);
      expect(resumeStage(BookingStatus.arrived), TripStage.waitingAtPickup);
      expect(resumeStage(BookingStatus.startRide), TripStage.inProgress);
    });

    test('anything else stays on Home', () {
      for (final int? status in <int?>[
        null,
        BookingStatus.request,
        BookingStatus.completed,
        BookingStatus.completedAlt,
        BookingStatus.cancel,
        BookingStatus.pendingPayment,
        99,
      ]) {
        expect(resumeStage(status), isNull, reason: 'status $status');
      }
    });
  });

  group('resumeBookingArgs', () {
    test('a whole trip gives the screen everything it had before', () {
      final args =
          resumeBookingArgs(_trip(const {}), TripStage.waitingAtPickup)!;

      expect(args.bookingId, 41);
      expect(args.bookingCode, 7788);
      expect(args.passengerId, 9);
      expect(args.processStepBook, 3);
      expect(args.latPassenger, 11.551);
      expect(args.lngPassenger, 104.921);
      expect(args.latDriver, 11.54);
      expect(args.desLatPassenger, 11.57);
      expect(args.typeVehicleId, 2);
      expect(args.namePassanger, 'Sokha');
    });

    test('no booking code, id or passenger: nothing to reopen', () {
      expect(resumeBookingArgs(_trip({'booking_code': null}),
          TripStage.enRouteToPickup), isNull);
      expect(resumeBookingArgs(_trip({'id': null}), TripStage.enRouteToPickup),
          isNull);
      expect(resumeBookingArgs(_trip({'passenger': null}),
          TripStage.enRouteToPickup), isNull);
    });

    test('the parts that used to throw now fall back', () {
      final args = resumeBookingArgs(
        _trip(<String, dynamic>{
          'driver': null,
          'end_latitude': null,
          'end_longitude': null,
          'passenger': <String, dynamic>{'id': 9},
        }),
        TripStage.inProgress,
      )!;

      // The pickup comes from the booking when the passenger has no fix.
      expect(args.latPassenger, 11.55);
      expect(args.lngPassenger, 104.92);
      expect(args.latDriver, isNull);
      expect(args.desLatPassenger, isNull);
      expect(args.typeVehicleId, 0);
      expect(args.pricrVehicle, 0);
      expect(args.namePassanger, '');
      expect(args.startTime, '');
    });

    test('no pickup anywhere: nothing to reopen', () {
      expect(
        resumeBookingArgs(
          _trip(<String, dynamic>{
            'start_latitude': null,
            'start_longitude': null,
            'passenger': <String, dynamic>{'id': 9},
          }),
          TripStage.enRouteToPickup,
        ),
        isNull,
      );
    });
  });
}
