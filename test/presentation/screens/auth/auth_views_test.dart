import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/auth/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/features/auth/data/models/phone_model.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/screens/login/logic.dart';
import 'package:tara_driver_application/presentation/screens/login/state.dart';
import 'package:tara_driver_application/presentation/screens/login/view.dart';
import 'package:tara_driver_application/presentation/screens/otp/view.dart';
import 'package:tara_driver_application/presentation/screens/register/view.dart';
import 'package:tara_driver_application/presentation/screens/register/widgets/photo_slot.dart';
import 'package:tara_driver_application/presentation/screens/splash_screen/view.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign S4 — the auth screens (`03 S01–S04`, `DD-23`, `DD-24`).
///
/// The validation rules themselves are pinned by `login/logic_test.dart`.
/// Here: the redesigned login view still shows the right inline error for
/// each rule and never calls the API for an invalid number; the OTP boxes
/// auto-submit on the 4th digit; register keeps its loose enable rule.
/// Picker sheets, the camera and navigation are device-verified.
class _NeverCalledAuthRepository extends AuthRepository {
  _NeverCalledAuthRepository()
      : super(AuthDatasource(apiClient: ApiClient(dio: Dio())));

  int calls = 0;

  @override
  Future<Result<PhoneNumberModel>> loginPhone(String phone) {
    calls++;
    throw StateError('an invalid number must not reach the API');
  }
}

void main() {
  group('LoginPage', () {
    late _NeverCalledAuthRepository repo;
    late LoginLogic logic;

    setUp(() {
      repo = _NeverCalledAuthRepository();
      logic = Get.put(LoginLogic(repo));
    });
    tearDown(Get.reset);

    Future<void> pump(WidgetTester t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(localizedHostPage(const LoginPage()));
      await t.pumpAndSettle();
    }

    testWidgets('empty number shows the phone error, no request',
        (WidgetTester t) async {
      await pump(t);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();

      expect(find.text('Please check your phone number'), findsOneWidget);
      expect(repo.calls, 0);
    });

    testWidgets('a short number shows the digit error, no request',
        (WidgetTester t) async {
      await pump(t);
      // "1234567" is formatted to "12 345 67" — 9 characters, under the
      // `< 10` rule that counts the formatted text.
      await t.enterText(find.byType(TextField), '1234567');
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();

      expect(logic.phoneController.text, '12 345 67');
      expect(find.text('Phone Number must be 8 digits up'), findsOneWidget);
      expect(repo.calls, 0);
    });

    testWidgets('submitting disables the field and spins the button',
        (WidgetTester t) async {
      await pump(t);
      logic.state.status.value = LoginStatus.loading;
      await t.pump();

      expect(t.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(t.widget<TButton>(find.byType(TButton)).loading, isTrue);
    });

    testWidgets('language segment is inline, no flag sheet',
        (WidgetTester t) async {
      await pump(t);
      expect(find.byType(TSegmented), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('OTP', () {
    testWidgets('auto-submits on the 4th digit', (WidgetTester t) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      final List<String> completed = <String>[];

      await t.pumpWidget(
        localizedHost(
          OtpInput(
            controller: controller,
            focusNode: focus,
            onCompleted: completed.add,
          ),
        ),
      );
      // Pinput's cursor blinks forever, so pump frames instead of settling.
      await t.pump(const Duration(milliseconds: 500));

      await t.enterText(find.byType(EditableText), '123');
      await t.pump();
      expect(completed, isEmpty);
      await t.enterText(find.byType(EditableText), '1234');
      await t.pump();
      expect(completed, <String>['1234']);
    });

    testWidgets('countdown pill until resend is enabled',
        (WidgetTester t) async {
      int resends = 0;
      Widget row({required bool canResend}) => localizedHost(
            OtpResendRow(
              secondsRemaining: 42,
              canResend: canResend,
              onResend: () => resends++,
            ),
          );

      await t.pumpWidget(row(canResend: false));
      await t.pumpAndSettle();
      expect(find.text('42s'), findsOneWidget);
      expect(find.byType(TButton), findsNothing);

      await t.pumpWidget(row(canResend: true));
      await t.pumpAndSettle();
      expect(find.text('42s'), findsNothing);
      await t.tap(find.text('Resend CODE'));
      expect(resends, 1);
    });

    testWidgets('shows the number the code was sent to',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(const OtpSentTo(phoneNumber: '900000001')),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining('+855 900000001', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Enter the 4-digit code sent to',
            findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('Register', () {
    test('submit is enabled unless name AND plate are both empty', () {
      expect(RegisterPage.canSubmit('', ''), isFalse);
      expect(RegisterPage.canSubmit('Sok', ''), isTrue);
      expect(RegisterPage.canSubmit('', '2B-4521'), isTrue);
      expect(RegisterPage.canSubmit('Sok', '2B-4521'), isTrue);
      // Not the prototype's stricter rule: one character is enough.
      expect(RegisterPage.canSubmit('S', ''), isTrue);
    });

    testWidgets('an empty slot picks, an attached slot can be cleared',
        (WidgetTester t) async {
      int picks = 0;
      int clears = 0;
      Widget slot(File? image) => localizedHost(
            SizedBox(
              width: 180,
              child: PhotoSlot(
                title: 'Driver license',
                icon: 'assets/icon/svg/driver_license_icon.svg',
                image: image,
                onPick: () => picks++,
                onClear: () => clears++,
              ),
            ),
          );

      await t.pumpWidget(slot(null));
      await t.pumpAndSettle();
      expect(find.text('Driver license'), findsOneWidget);
      expect(find.byType(TIconButton), findsNothing);
      await t.tap(find.byType(PhotoSlot));
      expect(picks, 1);

      await t.pumpWidget(slot(File('assets/image/png/Tara2.png')));
      await t.pump();
      expect(find.text('Driver license'), findsNothing);
      await t.tap(find.byType(TIconButton));
      expect(clears, 1);
      expect(picks, 1);
    });
  });

  testWidgets('SplashMark has the wordmark and no Skip',
      (WidgetTester t) async {
    await t.pumpWidget(localizedHost(const SplashMark()));
    await t.pumpAndSettle();
    expect(find.text('TARA DRIVER'), findsOneWidget);
    expect(find.textContaining('Skip'), findsNothing);
  });
}
