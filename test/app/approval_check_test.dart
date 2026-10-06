import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/app/logic.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/api_exception.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/home/data/datasource/home_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/home/data/repository/home_repository.dart';

/// DD-52 — what the home shows about the approval check comes from three
/// values on `AppState`: the status, "a check is running", and "the last
/// check gave no answer". These pin how `fetchCurrentDriveInfo` sets them.
class _ScriptedRepository extends HomeRepository {
  _ScriptedRepository()
      : super(HomeDatasource(apiClient: ApiClient(dio: Dio())));

  /// What the next call answers. Completed by the test, so the "running"
  /// state can be looked at before the answer lands.
  Completer<Result<CurrentDriverInfoModel>> next =
      Completer<Result<CurrentDriverInfoModel>>();
  int calls = 0;

  @override
  Future<Result<CurrentDriverInfoModel>> getCurrentDriveInfo() {
    calls++;
    return next.future;
  }
}

Result<CurrentDriverInfoModel> _answer(Map<String, dynamic> json) =>
    Result<CurrentDriverInfoModel>.ok(CurrentDriverInfoModel.fromJson(json));

Result<CurrentDriverInfoModel> _failure() => Result<CurrentDriverInfoModel>.err(
      const ApiException(type: ApiErrorType.connection, message: 'offline'),
    );

Map<String, dynamic> _driver(Object? status) => <String, dynamic>{
      'data': <String, dynamic>{
        'driver': <String, dynamic>{'status': status},
      },
    };

void main() {
  late _ScriptedRepository repository;
  late AppLogic app;

  setUp(() {
    repository = _ScriptedRepository();
    app = AppLogic(repository);
  });

  /// Starts a check, answers it with [result], and waits for it to finish.
  Future<void> check(Result<CurrentDriverInfoModel> result) async {
    repository.next = Completer<Result<CurrentDriverInfoModel>>();
    final Future<void> running = app.fetchCurrentDriveInfo();
    repository.next.complete(result);
    await running;
  }

  test('before any check: unknown, not running, not failed', () {
    expect(app.state.approvalStatus.value, DriverApprovalStatus.unknown);
    expect(app.state.approvalChecking.value, isFalse);
    expect(app.state.approvalCheckFailed.value, isFalse);
    expect(app.isApproved, isFalse);
  });

  test('while it runs it is "checking", and a second tap does not ask twice',
      () async {
    final Future<void> running = app.fetchCurrentDriveInfo();
    expect(app.state.approvalChecking.value, isTrue);
    expect(app.state.approvalCheckFailed.value, isFalse);

    await app.fetchCurrentDriveInfo();
    expect(repository.calls, 1);

    repository.next.complete(_answer(<String, dynamic>{'data': null}));
    await running;
    expect(app.state.approvalChecking.value, isFalse);
  });

  test('a driver with no trip ("data": null) is approved, nothing failed',
      () async {
    await check(_answer(<String, dynamic>{'data': null, 'status': true}));

    expect(app.isApproved, isTrue);
    expect(app.state.approvalCheckFailed.value, isFalse);
  });

  test('a call that fails leaves no answer: failed, and still not approved',
      () async {
    await check(_failure());

    expect(app.state.approvalStatus.value, DriverApprovalStatus.unknown);
    expect(app.state.approvalCheckFailed.value, isTrue);
    expect(app.isApproved, isFalse);
  });

  test('a retry clears "failed" while it runs, and can succeed', () async {
    await check(_failure());

    repository.next = Completer<Result<CurrentDriverInfoModel>>();
    final Future<void> running = app.fetchCurrentDriveInfo();
    expect(app.state.approvalCheckFailed.value, isFalse);
    expect(app.state.approvalChecking.value, isTrue);

    repository.next.complete(_answer(_driver(1)));
    await running;
    expect(app.isApproved, isTrue);
    expect(app.state.approvalCheckFailed.value, isFalse);
  });

  test('a status the app does not know is no answer either', () async {
    await check(_answer(_driver(7)));

    expect(app.state.approvalStatus.value, DriverApprovalStatus.unknown);
    expect(app.state.approvalCheckFailed.value, isTrue);
  });

  test('"check again" failing keeps a waiting driver on the waiting page',
      () async {
    await check(_answer(_driver(0)));
    expect(app.state.approvalStatus.value, DriverApprovalStatus.pending);

    await check(_failure());
    expect(app.state.approvalStatus.value, DriverApprovalStatus.pending);
    expect(app.state.approvalCheckFailed.value, isFalse);
  });

  test('"check again" lets a newly approved driver in', () async {
    await check(_answer(_driver(0)));
    await check(_answer(_driver(1)));

    expect(app.isApproved, isTrue);
  });
}
