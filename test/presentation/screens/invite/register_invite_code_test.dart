import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/api_exception.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/datasource/referral_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/repository/referral_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/widgets/invite_code_field.dart';
import 'package:pu_taxi_driver/presentation/screens/login/data/datasource/auth_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/register/binding.dart';
import 'package:pu_taxi_driver/presentation/screens/register/logic.dart';
import 'package:pu_taxi_driver/presentation/screens/register/state.dart';

/// DD-45 — the invite code on the sign-up form. It can only be given here,
/// so a wrong code must stop the form rather than be dropped.
class _Referral extends ReferralRepository {
  _Referral() : super(ReferralDatasource(apiClient: ApiClient(dio: Dio())));

  final List<String> asked = <String>[];
  Result<InviteCodeCheck> Function(String code) answer = (String code) =>
      Result<InviteCodeCheck>.ok(
        InviteCodeCheck(valid: code == 'SOKHA88', inviterName: 'Sokha Vann'),
      );

  @override
  Future<Result<InviteCodeCheck>> checkCode(String code) async {
    asked.add(code);
    return answer(code);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Referral referral;
  late RegisterLogic logic;

  setUp(() {
    referral = _Referral();
    logic = RegisterLogic(
      AuthRepository(AuthDatasource(apiClient: ApiClient(dio: Dio()))),
      referral: referral,
    );
  });

  test('no code: nothing to check, the form may go on', () async {
    expect(await logic.verifyInviteCode(), isTrue);
    expect(referral.asked, isEmpty);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.idle);
  });

  test('a real code: valid, with the inviter\'s name', () async {
    logic.inviteCodeController.text = 'SOKHA88';

    expect(await logic.verifyInviteCode(), isTrue);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.valid);
    expect(logic.state.inviterName.value, 'Sokha Vann');
  });

  test('an unknown code: invalid, and the form is stopped', () async {
    logic.inviteCodeController.text = 'NOPE99';

    expect(await logic.verifyInviteCode(), isFalse);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.invalid);
    expect(logic.state.inviterName.value, isNull);
  });

  test('a code that cannot be one is invalid without asking the server',
      () async {
    logic.inviteCodeController.text = 'AB';

    expect(await logic.verifyInviteCode(), isFalse);
    expect(referral.asked, isEmpty);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.invalid);
  });

  test('a failed check is "failed", not "invalid"', () async {
    referral.answer = (_) => Result<InviteCodeCheck>.err(
          const ApiException(type: ApiErrorType.connection, message: 'offline'),
        );
    logic.inviteCodeController.text = 'SOKHA88';

    expect(await logic.verifyInviteCode(), isFalse);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.failed);
  });

  test('a valid code is not asked about twice', () async {
    logic.inviteCodeController.text = 'SOKHA88';
    await logic.verifyInviteCode();
    await logic.verifyInviteCode();

    expect(referral.asked, <String>['SOKHA88']);
  });

  test('a scanned code fills the field and is checked at once', () async {
    await logic.applyScannedCode('SOKHA88');

    expect(logic.inviteCodeController.text, 'SOKHA88');
    expect(logic.state.inviteStatus.value, InviteCodeStatus.valid);
  });

  // testWidgets, for its fake clock: the check waits for typing to pause.
  testWidgets(
      'typing checks once the typing pauses, and an edit clears the answer',
      (WidgetTester t) async {
    logic.inviteCodeController.text = 'SOKH';
    logic.onInviteCodeChanged('SOKH');
    logic.inviteCodeController.text = 'SOKHA88';
    logic.onInviteCodeChanged('SOKHA88');
    await t.pump(RegisterLogic.inviteCheckDelay);
    await t.pump();

    expect(referral.asked, <String>['SOKHA88']);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.valid);

    logic.inviteCodeController.text = 'SOKHA8';
    logic.onInviteCodeChanged('SOKHA8');
    expect(logic.state.inviteStatus.value, InviteCodeStatus.idle);
    expect(logic.state.inviterName.value, isNull);
    await t.pump(RegisterLogic.inviteCheckDelay);
  });

  // The binding once looked up `ReferralRepository?` — a type nothing
  // registers — and the sign-up screen died on open (seen on the emulator).
  test('RegisterBinding can build the logic', () {
    addTearDown(Get.reset);
    // The real datasources need the app's Dio; registered first, these win.
    Get.put(AuthDatasource(apiClient: ApiClient(dio: Dio())));
    Get.put(ReferralDatasource(apiClient: ApiClient(dio: Dio())));
    RegisterBinding().dependencies();

    expect(Get.find<RegisterLogic>(), isA<RegisterLogic>());
  });

  test('a wrong code stops submit before anything is sent', () async {
    logic.inviteCodeController.text = 'NOPE99';

    await logic.submit();

    expect(logic.state.status.value, RegisterStatus.initial);
    expect(logic.state.inviteStatus.value, InviteCodeStatus.invalid);
  });
}
