import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/data/models/complete_driver_model.dart'
    as complete;
import 'package:pu_taxi_driver/data/models/confirm_booking_model.dart'
    as confirm;
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/models/wallet_model.dart'
    as wallet;
import 'package:pu_taxi_driver/presentation/screens/wallet/wallet_presentation.dart';

/// Response bodies captured from the real backend, kept as they were sent
/// (`test/fixtures/`), except the driver's phone and position, which are
/// replaced with made-up values. The models were first written against
/// guesses and a mock; these are what the backend actually says.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('POST /taxi-driver/confirm-drive-request, 2026-10-06', () {
    final Map<String, dynamic> body =
        _fixture('confirm_drive_request_2026_10_06.json');

    test('parses as the accept / arrive / start response', () {
      final confirm.ConfirmBookingModel model =
          confirm.ConfirmBookingModel.fromJson(body);
      final confirm.Data data = model.data!;

      expect(data.id, 4);
      expect(data.bookingCode, '1791298696');
      expect(data.startLatitude, '11.5259032');
      expect(data.startLongitude, '104.9233525');
      expect(data.passenger?.id, 3);
      expect(data.passenger?.name, 'Dummy Passenger');
      expect(data.driver?.id, 2);
      // The field that used to end the trip screen: a year sent as text.
      expect(data.driver?.vehicle?.yearOfManufacture, 2020);
      expect(data.driver?.vehicle?.typeVehicleId, 1);
      expect(data.driver?.vehicle?.maxPassenger, 4);
      expect(data.driver?.vehicle?.vehicleImage, isEmpty);
    });

    test('the same ride shape parses as current-drive-info and drop-off', () {
      final CurrentDriverInfoModel current =
          CurrentDriverInfoModel.fromJson(body);
      expect(current.data?.id, 4);
      expect(current.data?.status, 2);
      expect(current.data?.driver?.lastLocation?.latitude, '11.5762000');
      // The ride carries the driver's approval status: 1, approved.
      expect(
        approvalStatusForDriveInfo(current),
        DriverApprovalStatus.approved,
      );

      final complete.CompleteDriverModel done =
          complete.CompleteDriverModel.fromJson(body);
      expect(done.data?.id, 4);
      expect(done.data?.payment, isNull);
    });

    test('the price per km is read from the vehicle type (DD-54)', () {
      // The app first looked for `vehicle.vehicle_price`. The backend sends
      // `vehicle.vehicle_type.price`, as the text "0.30".
      final CurrentDriverInfoModel current =
          CurrentDriverInfoModel.fromJson(body);
      expect(current.data?.driver?.vehicle?.pricrVehicle, 0.3);
    });

    test('the wallet inside it: what the wallet screen would make of it', () {
      final Map<String, dynamic> walletJson =
          ((body['data'] as Map<String, dynamic>)['driver']
              as Map<String, dynamic>)['wallet'] as Map<String, dynamic>;
      final wallet.Data data = wallet.Data.fromJson(walletJson);

      expect(data.currency, 'KHR');
      expect(commissionRateText(data.commistionFare), '5');
      // `debted` arrives negative ("-5.00"): the driver owes ៛5.
      expect(walletDebt(data.debted), 5);
      // The type is "payment" (DD-61), and its status "pending".
      expect(
        WalletTxKind.of(data.transactions?.first.typeName?.toString()),
        WalletTxKind.payment,
      );
      expect(
        WalletTxStatus.of(data.transactions?.first.statusName?.toString()),
        WalletTxStatus.pending,
      );
    });
  });

  group('GET /taxi-driver/referral, 2026-10-20', () {
    final Map<String, dynamic> body = _fixture('referral_2026_10_20.json');

    test('parses as the invite QR and rewards response', () {
      final ReferralModel model = ReferralModel.fromJson(body);

      expect(model.code, 'A7P0VL');
      expect(model.link, 'https://putaxi.example/i/A7P0VL');
      expect(model.currency, 'KHR');
      expect(model.driverTopUpRate, 1);
      expect(model.passengerCommissionRate, 10);
      expect(model.rewardBalance, 0);
      expect(model.invitees, hasLength(1));
      expect(model.invitees.first.id, 6);
      expect(model.invitees.first.name, 'Referral Test');
      expect(model.invitees.first.image, '');
      expect(model.invitees.first.role, 'passenger');
      expect(model.invitees.first.joinedAt, '2026-10-20 18:38:02');
      expect(model.invitees.first.earned, 0);
      expect(model.rewards, isEmpty);
      expect(model.transfers, isEmpty);
    });
  });
}
