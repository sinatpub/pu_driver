import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/app/logic.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/api_exception.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/data/models/set_status_model.dart';
import 'package:pu_taxi_driver/presentation/screens/home/data/datasource/home_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/home/data/repository/home_repository.dart';
import 'package:pu_taxi_driver/services/session_service.dart';

/// DD-53 — the app puts the driver online by itself, once per sign-in, when
/// the account may work, the server's status has been read and the phone
/// has a GPS fix. It stays off only for an error or a blocked account.
class _Server extends HomeRepository {
  _Server() : super(HomeDatasource(apiClient: ApiClient(dio: Dio())));

  /// `driver.status` in `get-current-drive-info`; null is the real answer
  /// for a driver with no trip (`"data": null`).
  int? driverStatus;
  bool driveInfoFails = false;

  /// What the server holds for `is_available`.
  int available = 0;

  /// `set-status` is refused with this message.
  String? refusal;

  final List<int> setStatusCalls = <int>[];

  @override
  Future<Result<CurrentDriverInfoModel>> getCurrentDriveInfo() async {
    if (driveInfoFails) {
      return Result<CurrentDriverInfoModel>.err(const ApiException(
          type: ApiErrorType.connection, message: 'offline'));
    }
    return Result<CurrentDriverInfoModel>.ok(
      CurrentDriverInfoModel.fromJson(<String, dynamic>{
        'status': true,
        'data': driverStatus == null
            ? null
            : <String, dynamic>{
                'driver': <String, dynamic>{'status': driverStatus},
              },
      }),
    );
  }

  @override
  Future<Result<SetDriverStatusModel>> getStatus() async =>
      Result<SetDriverStatusModel>.ok(_status());

  @override
  Future<Result<SetDriverStatusModel>> setStatus(int status) async {
    setStatusCalls.add(status);
    final String? refused = refusal;
    if (refused != null) {
      return Result<SetDriverStatusModel>.err(
          ApiException(type: ApiErrorType.forbidden, message: refused));
    }
    available = status;
    return Result<SetDriverStatusModel>.ok(_status());
  }

  SetDriverStatusModel _status() =>
      SetDriverStatusModel.fromJson(<String, dynamic>{
        'status': true,
        'data': <String, dynamic>{'is_available': available},
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Server server;
  late AppLogic app;
  late List<String> messages;
  late int busyShown;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    server = _Server();
    messages = <String>[];
    busyShown = 0;
    app = AppLogic(
      server,
      showMessage: messages.add,
      showBusy: () => busyShown++,
      hideBusy: () {},
    )..onInit();
  });

  /// What a normal launch does, in the order the app does it.
  Future<void> launch({bool location = true}) async {
    await app.fetchCurrentDriveInfo();
    await app.checkStatus();
    app.setLocationReady(location);
    await pumpEventQueue();
  }

  test('an approved driver with a location goes online without a tap',
      () async {
    await launch();

    expect(app.state.isOnline.value, isTrue);
    expect(server.setStatusCalls, <int>[1]);
    // Quietly: no overlay over the home, and nothing to tell.
    expect(busyShown, 0);
    expect(messages, isEmpty);
  });

  test('the order the three answers arrive in does not matter', () async {
    app.setLocationReady(true);
    await pumpEventQueue();
    expect(server.setStatusCalls, isEmpty);

    await app.checkStatus();
    await pumpEventQueue();
    expect(server.setStatusCalls, isEmpty);

    await app.fetchCurrentDriveInfo();
    await pumpEventQueue();
    expect(server.setStatusCalls, <int>[1]);
  });

  test('a driver the server still has online is left as they are', () async {
    server.available = 1;
    await launch();

    expect(app.state.isOnline.value, isTrue);
    expect(server.setStatusCalls, isEmpty);
  });

  group('stays offline', () {
    test('while there is no location', () async {
      await launch(location: false);

      expect(app.state.isOnline.value, isFalse);
      expect(server.setStatusCalls, isEmpty);

      // …and goes online when the fix arrives.
      app.setLocationReady(true);
      await pumpEventQueue();
      expect(app.state.isOnline.value, isTrue);
    });

    test('when the account check failed', () async {
      server.driveInfoFails = true;
      await launch();

      expect(app.state.approvalCheckFailed.value, isTrue);
      expect(server.setStatusCalls, isEmpty);

      // "Please try again" works, and then the driver is put online.
      server.driveInfoFails = false;
      await app.fetchCurrentDriveInfo();
      await pumpEventQueue();
      expect(app.state.isOnline.value, isTrue);
    });

    test('when the account is waiting for approval, until it is approved',
        () async {
      server.driverStatus = 0;
      await launch();
      expect(server.setStatusCalls, isEmpty);

      // "Check again" after the admin approved.
      server.driverStatus = 1;
      await app.fetchCurrentDriveInfo();
      await pumpEventQueue();
      expect(app.state.isOnline.value, isTrue);
    });

    test('when the account is not approved', () async {
      server.driverStatus = 2;
      await launch();

      expect(app.state.approvalStatus.value, DriverApprovalStatus.rejected);
      expect(server.setStatusCalls, isEmpty);
    });

    test('when the server refuses: said once, and not tried again', () async {
      server.refusal = 'Your account is not approved yet.';
      await launch();

      expect(app.state.isOnline.value, isFalse);
      expect(messages, <String>['Your account is not approved yet.']);

      app.setLocationReady(false);
      app.setLocationReady(true);
      await pumpEventQueue();
      expect(server.setStatusCalls, <int>[1]);
    });
  });

  group('the pill is the driver\'s', () {
    test('a driver who turns off is not turned back on', () async {
      await launch();
      await app.toggle(false);
      expect(app.state.isOnline.value, isFalse);

      // The home is rebuilt (after a trip, a language switch): the location
      // reports again, and the status is read again.
      app.setLocationReady(false);
      app.setLocationReady(true);
      await app.fetchCurrentDriveInfo();
      await pumpEventQueue();

      expect(app.state.isOnline.value, isFalse);
      expect(server.setStatusCalls, <int>[1, 0]);
    });

    test('a tap shows the overlay; going online by itself does not', () async {
      await launch();
      expect(busyShown, 0);

      await app.toggle(false);
      expect(busyShown, 1);
    });

    test('a tap that fails says why and falls back', () async {
      await launch();
      server.refusal = 'No connection';
      await app.toggle(false);

      expect(app.state.isOnline.value, isTrue);
      expect(messages, <String>['No connection']);
    });

    test('a driver who is not approved cannot tap their way online', () async {
      server.driverStatus = 0;
      await launch();
      await app.toggle(true);

      expect(server.setStatusCalls, isEmpty);
    });
  });

  test('after a sign-out the next driver starts clean, and goes online too',
      () async {
    await launch();
    await app.toggle(false);

    await SessionService.instance.clear();
    server.available = 0;
    await launch();

    expect(app.state.isOnline.value, isTrue);
    expect(server.setStatusCalls, <int>[1, 0, 1]);
  });

  test('a sign-out forgets the last driver\'s approval until it is checked',
      () async {
    await launch();
    expect(app.isApproved, isTrue);

    await SessionService.instance.clear();
    server.driveInfoFails = true;
    await app.fetchCurrentDriveInfo();

    expect(app.isApproved, isFalse);
    expect(app.state.isOnline.value, isFalse);
  });
}
