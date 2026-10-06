import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/data/models/complete_driver_model.dart'
    as complete;
import 'package:pu_taxi_driver/data/models/confirm_booking_model.dart'
    as confirm;
import 'package:pu_taxi_driver/data/models/profile_model.dart' as profile;
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart'
    as history;

/// The backend writes the same value as a number in one response and as a
/// string in the next. These models read every field straight into a typed
/// one, so a single `"2"` lost the whole response: on 2026-10-06
/// `drive-arrive` failed with `type 'String' is not a subtype of type 'int?'`
/// inside `Vehicle.fromJson`, and the trip screen closed under the driver.
///
/// The vehicle below is written the way that breaks strict reading — every
/// number as a string, every string as a number.
Map<String, dynamic> _vehicle() => <String, dynamic>{
      'id': '5',
      'type_vehicle_id': '1',
      'model': 110,
      'manufacturer': 'Honda',
      'year_of_manufacture': '2020',
      'color': 'Black',
      'plate_number': 1234,
      'engine_power': 125,
      'max_passenger': '2',
      'status': '1',
      'vehicle_image': null,
    };

Map<String, dynamic> _driver() => <String, dynamic>{
      'id': '2',
      'name': 'Dummy Driver',
      'gender': '0',
      'card_type': '1',
      'status': '1',
      'vehicle': _vehicle(),
    };

void main() {
  test('confirm / arrive / start: the response that failed now parses', () {
    final confirm.ConfirmBookingModel model =
        confirm.ConfirmBookingModel.fromJson(<String, dynamic>{
      'status': true,
      'message': 'success',
      'data': <String, dynamic>{
        'id': '1',
        'booking_code': 1791280683,
        'start_latitude': 11.5259,
        'start_longitude': 104.9233,
        'status': 2,
        'driver': _driver(),
        'passenger': <String, dynamic>{'id': '3', 'name': 'Dummy Passenger'},
      },
    });

    expect(model.data?.id, 1);
    expect(model.data?.driver?.id, 2);
    expect(model.data?.driver?.vehicle?.typeVehicleId, 1);
    expect(model.data?.driver?.vehicle?.yearOfManufacture, 2020);
    expect(model.data?.driver?.vehicle?.maxPassenger, 2);
    expect(model.data?.driver?.vehicle?.plateNumber, '1234');
    expect(model.data?.passenger?.id, 3);
  });

  test('complete-drive: mixed types, and no vehicle images, still parse', () {
    final complete.CompleteDriverModel model =
        complete.CompleteDriverModel.fromJson(<String, dynamic>{
      'status': true,
      'data': <String, dynamic>{
        'id': '1',
        'booking_code': 1791280683,
        'status': '6',
        'driver': _driver(),
        'passenger': <String, dynamic>{'id': '3', 'role_id': '3'},
        'payment': <String, dynamic>{
          'id': '9',
          'invoice_id': '4',
          'ride_id': '1',
          'amount': 1.5,
          'distance': 3,
          'status': '1',
        },
      },
    });

    expect(model.data?.id, 1);
    expect(model.data?.driver?.vehicle?.vehicleImage, isEmpty);
    expect(model.data?.payment?.id, 9);
    expect(model.data?.payment?.rideId, 1);
    // Money stays as written: text in, text out, nothing rounded.
    expect(model.data?.payment?.amount, '1.5');
  });

  test('history: one odd row does not lose the page', () {
    final history.HistoryDriveInfoModel model =
        history.HistoryDriveInfoModel.fromJson(<String, dynamic>{
      'status': true,
      'current_page': '1',
      'per_page': '10',
      'total': '1',
      'data': <dynamic>[
        <String, dynamic>{
          'id': '1',
          'booking_code': 1791280683,
          'status': '7',
          'driver': _driver(),
          'passenger': <dynamic>[],
          'payment': <String, dynamic>{'id': '9', 'amount': '1.50'},
        },
      ],
    });

    expect(model.currentPage, 1);
    expect(model.total, 1);
    expect(model.data, hasLength(1));
    expect(model.data?.single.id, 1);
    expect(model.data?.single.passenger, isNull);
    expect(model.data?.single.payment?.amount, '1.50');
  });

  test('profile: the driver and the vehicle read however they are written', () {
    final profile.ProfileModel model =
        profile.ProfileModel.fromJson(<String, dynamic>{
      'status': true,
      'data': <String, dynamic>{
        'id': '2',
        'driver_id': 'DRV0001',
        'name': 'Dummy Driver',
        'gender': '0',
        'status': '1',
        'vehicle': _vehicle(),
      },
    });

    expect(model.data?.id, 2);
    expect(model.data?.driverId, 'DRV0001');
    expect(model.data?.status, 1);
    expect(model.data?.vehicle?.typeVehicleId, 1);
    expect(model.data?.vehicle?.plateNumber, '1234');
  });

  test('a response with no data at all is empty, not a crash', () {
    expect(
      confirm.ConfirmBookingModel.fromJson(<String, dynamic>{'data': null})
          .data,
      isNull,
    );
    expect(
      complete.CompleteDriverModel.fromJson(
          <String, dynamic>{'data': <dynamic>[]}).data,
      isNull,
    );
    expect(
      profile.ProfileModel.fromJson(<String, dynamic>{}).data,
      isNull,
    );
  });
}
