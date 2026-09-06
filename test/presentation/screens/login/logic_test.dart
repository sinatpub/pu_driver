import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/api_exception.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/core/storage/key_storages.dart';
import 'package:tara_driver_application/features/auth/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/features/auth/data/models/phone_model.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/screens/login/logic.dart';
import 'package:tara_driver_application/presentation/screens/login/state.dart';

/// The driver app has **no password login**. Auth is
/// `POST /taxi-driver/login-phone` (phone only) → `verify-phone-otp`
/// (`04` §2). `LoginLogic` therefore takes a phone number and nothing else;
/// a `{phone, password}` payload has no code path here.
const _apiError = ApiException(type: ApiErrorType.unknown, message: 'boom');

/// Overrides the one network call so no real HTTP request is ever made. The
/// `super()` datasource is unreachable dead weight required only to satisfy
/// [AuthRepository]'s constructor — it's built with an explicit `Dio()` and
/// never touches `BaseHttpClient.dio` (a `late final` static that throws
/// unless `BaseHttpClient.init()` ran, which nothing in this test does).
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(AuthDatasource(apiClient: ApiClient(dio: Dio())));

  Result<PhoneNumberModel>? loginResult;
  int loginCalls = 0;
  String? lastPhone;

  @override
  Future<Result<PhoneNumberModel>> loginPhone(String phone) async {
    loginCalls++;
    lastPhone = phone;
    return loginResult!;
  }
}

PhoneNumberModel _otpSent({int seconds = 60}) => PhoneNumberModel(
      data: Data(seconde: seconds),
      status: true,
      message: 'OTP sent',
    );

/// Constructed directly rather than through `Get.put`, so `onInit` — and the
/// `ever` worker that navigates to the OTP screen / shows an error dialog —
/// never runs. These tests cover the logic, not the routing.
LoginLogic _logic(_FakeAuthRepository repo) => LoginLogic(repo);

/// Lets the unawaited `StorageSet.setPhoneNumber` write finish before a test
/// reads SharedPreferences back.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('validate()', () {
    test('an empty phone number is rejected as invalid', () {
      final logic = _logic(_FakeAuthRepository());

      expect(logic.validate(''), isFalse);
      expect(logic.state.isInvalidPhone.value, isTrue);
      expect(logic.state.isRequired8Digit.value, isFalse);
    });

    test('a raw 9-digit string is rejected — one short of the minimum', () {
      final logic = _logic(_FakeAuthRepository());

      expect('900000001'.length, 9);
      expect(logic.validate('900000001'), isFalse);
      // The two error flags are mutually exclusive — this is the
      // "not enough digits" branch, not the "empty" one.
      expect(logic.state.isRequired8Digit.value, isTrue);
      expect(logic.state.isInvalidPhone.value, isFalse);
    });

    test(
      'BUT the field never passes a raw string: the formatter adds spaces, '
      'so 9 digits reach validate() as 11 characters and pass',
      () {
        // `validate()` measures `phoneNumber.length`, and the text it receives
        // is what `CardNumberInputFormatter` produced — spaces included.
        // Verified on a real device 2026-09-06: typing 900000001 into the
        // login field yields "90 000 0001", passes this check, and the
        // backend accepted it and sent an OTP.
        //
        // So the "<10" rule is a *character* count, not a digit count. Any
        // 9-digit number clears it. Recorded, not fixed — changing the rule
        // is a product decision about which lengths are legal.
        final logic = _logic(_FakeAuthRepository());
        const asTypedByTheField = '90 000 0001';

        expect(asTypedByTheField.length, 11);
        expect(asTypedByTheField.replaceAll(' ', '').length, 9);
        expect(logic.validate(asTypedByTheField), isTrue);
      },
    );

    test('exactly 10 digits is the shortest accepted number', () {
      final logic = _logic(_FakeAuthRepository());

      expect(logic.validate('9000000010'), isTrue);
      expect(logic.state.isInvalidPhone.value, isFalse);
      expect(logic.state.isRequired8Digit.value, isFalse);
    });

    test('a previous failure is cleared once a valid number is entered', () {
      final logic = _logic(_FakeAuthRepository());

      logic.validate('900000001');
      expect(logic.state.isRequired8Digit.value, isTrue);

      logic.validate('9000000010');
      expect(logic.state.isRequired8Digit.value, isFalse);
      expect(logic.state.isInvalidPhone.value, isFalse);
    });
  });

  group('submit()', () {
    test('a raw 9-digit string never reaches the API — validation stops it',
        () async {
      final repo = _FakeAuthRepository();
      final logic = _logic(repo);

      await logic.submit('900000001');

      expect(repo.loginCalls, 0);
      expect(logic.state.status.value, LoginStatus.initial);
      expect(logic.state.isRequired8Digit.value, isTrue);
    });

    test('an empty phone number never reaches the API either', () async {
      final repo = _FakeAuthRepository();
      final logic = _logic(repo);

      await logic.submit('');

      expect(repo.loginCalls, 0);
      expect(logic.state.status.value, LoginStatus.initial);
    });

    test('on success: status loaded, OTP window captured, phone persisted',
        () async {
      final repo = _FakeAuthRepository()
        ..loginResult = Result.ok(_otpSent(seconds: 90));
      final logic = _logic(repo);

      await logic.submit('9000000010');

      expect(repo.loginCalls, 1);
      expect(repo.lastPhone, '9000000010');
      expect(logic.state.status.value, LoginStatus.loaded);
      expect(logic.state.phoneModel.value?.data.seconde, 90);

      // The phone is stashed for the register step, which reads it back
      // rather than being passed it (RegisterLogic.submit).
      //
      // `submit()` does NOT await this write — `StorageSet.setPhoneNumber` is
      // fire-and-forget inside `result.when`'s ok branch, so the status flips
      // to `loaded` (and the `ever` worker navigates to OTP) before the value
      // has landed. Hence the pump below. Harmless today, since the value is
      // only read back at the register step many seconds later.
      await _settle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.phoneNumber), '9000000010');
    });

    test('on API error: status fail, nothing captured, nothing persisted',
        () async {
      final repo = _FakeAuthRepository()..loginResult = Result.err(_apiError);
      final logic = _logic(repo);

      await logic.submit('9000000010');

      expect(repo.loginCalls, 1);
      expect(logic.state.status.value, LoginStatus.fail);
      expect(logic.state.phoneModel.value, isNull);

      await _settle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.phoneNumber), isNull);
    });

    test('status passes through loading before it resolves', () async {
      final repo = _FakeAuthRepository()..loginResult = Result.ok(_otpSent());
      final logic = _logic(repo);

      final seen = <LoginStatus>[];
      logic.state.status.listen(seen.add);

      await logic.submit('9000000010');
      await Future<void>.delayed(Duration.zero);

      expect(
          seen, containsAllInOrder([LoginStatus.loading, LoginStatus.loaded]));
    });
  });
}
