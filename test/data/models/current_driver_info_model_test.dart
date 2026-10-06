import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';

/// `get-current-drive-info` feeds the approval gate (`AppLogic`) and the
/// resume-a-trip redirect. The backend sends numbers as strings, strings as
/// numbers and empty relations as `[]`; none of that may cost the driver's
/// approval status, because without it the gate stays on "checking".
void main() {
  DriverApprovalStatus gateFor(Map<String, dynamic> json) =>
      approvalStatusForDriveInfo(CurrentDriverInfoModel.fromJson(json));

  test('an idle, approved driver: no ride, and the driver alone', () {
    final CurrentDriverInfoModel model = CurrentDriverInfoModel.fromJson(
      <String, dynamic>{
        'status': true,
        'message': 'success',
        'data': <String, dynamic>{
          'id': null,
          'status': null,
          'driver': <String, dynamic>{'id': 2, 'name': 'Dummy', 'status': 1},
        },
      },
    );

    expect(model.data?.id, isNull);
    expect(model.data?.driver?.status, 1);
  });

  test('numbers as strings and strings as numbers still parse', () {
    final CurrentDriverInfoModel model = CurrentDriverInfoModel.fromJson(
      <String, dynamic>{
        'status': true,
        'data': <String, dynamic>{
          'id': '31',
          'booking_code': 20260001,
          'start_latitude': 11.5564,
          'start_longitude': 104.9282,
          'start_time': '2026-10-06 09:14:00',
          'status': '2',
          'driver': <String, dynamic>{
            'id': '2',
            'gender': '0',
            'card_type': '1',
            'card_number': 123456789,
            'status': '1',
            'vehicle': <String, dynamic>{
              'id': '5',
              'type_vehicle_id': '1',
              'vehicle_price': '0.30',
              'year_of_manufacture': '2020',
              'engine_power': 125,
              'max_passenger': '2',
              'plate_number': 1234,
              'vehicle_image': <dynamic>[
                <String, dynamic>{'id': '9', 'file_size': 20480},
                'not an object',
              ],
            },
            'last_location': <String, dynamic>{
              'latitude': 11.5564,
              'longitude': '104.9282',
            },
          },
          'payment': <String, dynamic>{
            'id': '7',
            'amount': 1.5,
            'distance': 3,
            'status': '1',
          },
        },
      },
    );

    final DataDriverInfo data = model.data!;
    expect(data.id, 31);
    expect(data.bookingCode, '20260001');
    expect(data.startLatitude, '11.5564');
    expect(data.startTime, DateTime(2026, 10, 6, 9, 14));
    expect(data.status, 2);
    expect(data.driver?.status, 1);
    expect(data.driver?.cardNumber, '123456789');
    expect(data.driver?.vehicle?.plateNumber, '1234');
    expect(data.driver?.vehicle?.yearOfManufacture, 2020);
    expect(data.driver?.vehicle?.enginePower, '125');
    expect(data.driver?.vehicle?.vehicleImage, hasLength(1));
    expect(data.driver?.vehicle?.vehicleImage?.single.fileSize, '20480');
    expect(data.driver?.lastLocation?.latitude, '11.5564');
    expect(data.payment?.amount, '1.5');
    expect(data.payment?.distance, '3');
  });

  test('the price per km keeps its decimals (DD-54)', () {
    final CurrentDriverInfoModel model = CurrentDriverInfoModel.fromJson(
      <String, dynamic>{
        'data': <String, dynamic>{
          'driver': <String, dynamic>{
            'status': 1,
            'vehicle': <String, dynamic>{'vehicle_price': '0.30'},
          },
        },
      },
    );

    expect(model.data?.driver?.vehicle?.pricrVehicle, 0.3);
  });

  test('an empty relation written as [] is no object, not a crash', () {
    final CurrentDriverInfoModel model = CurrentDriverInfoModel.fromJson(
      <String, dynamic>{
        'data': <String, dynamic>{
          'passenger': <dynamic>[],
          'payment': <dynamic>[],
          'driver': <String, dynamic>{
            'status': 1,
            'vehicle': <dynamic>[],
            'last_location': <dynamic>[],
          },
        },
      },
    );

    expect(model.data?.passenger, isNull);
    expect(model.data?.payment, isNull);
    expect(model.data?.driver?.vehicle, isNull);
    expect(model.data?.driver?.status, 1);
  });

  group('the approval gate reads the status however it is written', () {
    Map<String, dynamic> withStatus(Object? status) => <String, dynamic>{
          'data': <String, dynamic>{
            'driver': <String, dynamic>{'status': status},
          },
        };

    test('approved', () {
      expect(gateFor(withStatus(1)), DriverApprovalStatus.approved);
      expect(gateFor(withStatus('1')), DriverApprovalStatus.approved);
    });

    test('pending and rejected', () {
      expect(gateFor(withStatus('0')), DriverApprovalStatus.pending);
      expect(gateFor(withStatus(2)), DriverApprovalStatus.rejected);
    });

    // The real answer for a driver with no trip, 2026-10-06.
    test('"data": null is a driver free to work: the gate opens', () {
      expect(
        gateFor(<String, dynamic>{
          'data': null,
          'status': true,
          'message': 'Success',
        }),
        DriverApprovalStatus.approved,
      );
    });

    test('no driver, or a driver with no status, opens it too', () {
      expect(gateFor(withStatus(null)), DriverApprovalStatus.approved);
      expect(
        gateFor(<String, dynamic>{'data': <dynamic>[]}),
        DriverApprovalStatus.approved,
      );
      expect(
        gateFor(<String, dynamic>{
          'data': <String, dynamic>{'id': 31, 'status': 2},
        }),
        DriverApprovalStatus.approved,
      );
    });

    test('a status the app does not know keeps the gate shut', () {
      expect(gateFor(withStatus(7)), DriverApprovalStatus.unknown);
    });
  });
}
