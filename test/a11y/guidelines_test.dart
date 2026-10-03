import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/state.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart'
    hide Color;
import 'package:tara_driver_application/presentation/screens/login/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/datasource/profile_datasource.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/repository/profile_repository.dart';
import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';
import 'package:tara_driver_application/presentation/screens/announcement/widgets/news_card.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/ride_request_bottom_pop_widget.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/view.dart';
import 'package:tara_driver_application/presentation/screens/drawer/state.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/approval_gate.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/driver_drawer.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/online_status_pill.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_card_widget.dart';
import 'package:tara_driver_application/presentation/screens/home/state.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/driver_status_card.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/location_state_view.dart';
import 'package:tara_driver_application/presentation/screens/invite/scan_view.dart';
import 'package:tara_driver_application/presentation/screens/invite/widgets/invite_code_field.dart';
import 'package:tara_driver_application/presentation/screens/invite/widgets/invite_widgets.dart';
import 'package:tara_driver_application/presentation/screens/login/logic.dart';
import 'package:tara_driver_application/presentation/screens/login/view.dart';
import 'package:tara_driver_application/presentation/screens/otp/logic.dart';
import 'package:tara_driver_application/presentation/screens/otp/view.dart';
import 'package:tara_driver_application/presentation/screens/profile/logic.dart';
import 'package:tara_driver_application/presentation/screens/register/logic.dart';
import 'package:tara_driver_application/presentation/screens/register/view.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/screens/wallet/widgets/wallet_widgets.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/view.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../helpers/localized_host.dart';

/// UX-redesign P3 — accessibility on the redesigned screens (`02 §1.2, §13`).
///
/// Every redesigned screen or component that can be pumped without a live
/// backend or a map platform view is run against Flutter's own guidelines:
/// - `androidTapTargetGuideline` — nothing tappable under 48×48;
/// - `labeledTapTargetGuideline` — every tappable thing announces a label;
/// - `textContrastGuideline` — rendered text meets WCAG AA;
/// and, separately, rendered at text scale 1.3 (the app's clamp ceiling) in
/// both locales, where any overflow fails the test.
///
/// Not covered here (device, Q2): a TalkBack/VoiceOver walk through the live
/// trip flow — the map, socket events and route changes need the real app.
AuthRepository _auth() =>
    AuthRepository(AuthDatasource(apiClient: ApiClient(dio: Dio())));

class _Vehicles extends GetVehicalRemoteDataSource {
  @override
  Future<VehicalTypeEntities> getAllVehicalApi() async => VehicalTypeEntities(
        data: <SingleVehical>[
          SingleVehical(
            id: 1,
            name: 'Tuk-Tuk',
            price: 0,
            minimumFare: 0,
            image: null,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ],
        color: const [],
        message: '',
        status: true,
      );
}

DataHistory _trip() => DataHistory.fromJson(<String, dynamic>{
      'id': 1,
      'start_latitude': '11.5',
      'start_longitude': '104.9',
      'end_latitude': '11.6',
      'end_longitude': '104.9',
      'start_time': '2026-09-12 09:30:00',
      'start_address': 'St. 271, Phnom Penh',
      'end_address': 'Sisowath Quay',
      'status': 4,
      'status_name': 'completed',
      'passenger': <String, dynamic>{'name': 'Mey Lin'},
      'payment': <String, dynamic>{
        'invoice_id': 7712,
        'distance': '3.5 km',
        'duration': '14 mins',
        'amount': '7600',
        'payment_method': 'Cash',
      },
    });

Widget _sheet(int processType, {bool hasDestination = true}) => Stack(
      children: <Widget>[
        ModelBottomSheetNewRequestWidget(
          bookingId: 1,
          bookingCode: 48213,
          passengerId: 2,
          processType: processType,
          profilePassanger: '',
          namePassanger: 'Sok Dara',
          phonePassanger: '090000001',
          // DD-35–DD-37: a long geocoded pickup, and every figure the
          // compact stages can show, so their wrapping is checked too.
          passegerLocationName: 'No. 12, Street 271, Sangkat Tuol Tumpung '
              'Ti Muoy, Chamkar Mon, Phnom Penh, 12306, Cambodia',
          whereToGoLocationName: 'Independence Monument',
          distandTotal: 3.5,
          totalFee: '7600',
          onTap: () {},
          onCancel: () {},
          duration: '00:12:40',
          distance: '3.20 km',
          fare: '7,600',
          pickupEta: '12 min',
          pickupDistance: '4.8 km',
          tripDistance: '12.4 km',
          tripFare: '24,600',
          waitingSince: DateTime.now().subtract(
            const Duration(minutes: 12, seconds: 34),
          ),
          hasDestination: hasDestination,
          tripEta: '18 min',
          tripLeft: '5.8 km',
          tripProgress: 0.35,
        ),
      ],
    );

/// The surfaces under test. `page: true` hosts a whole `Scaffold`.
final Map<String, (Widget Function(), bool)> _surfaces =
    <String, (Widget Function(), bool)>{
  'login': (() => const LoginPage(), true),
  'otp': (() => const OtpPage(), true),
  'register': (() => const RegisterPage(), true),
  'drawer': (
    () => Scaffold(
          body: DriverDrawer(activeTab: DrawerTab.home, onSelect: (_) {}),
        ),
    true
  ),
  'trip request': (() => Scaffold(body: _sheet(1)), true),
  'trip pickup': (() => Scaffold(body: _sheet(2)), true),
  'trip at pickup': (() => Scaffold(body: _sheet(3)), true),
  'trip in progress': (() => Scaffold(body: _sheet(4)), true),
  'trip in progress, no destination': (
    () => Scaffold(body: _sheet(4, hasDestination: false)),
    true
  ),
  'home status + location': (
    () => Column(
          children: <Widget>[
            const DriverStatusCardView(
              isOnline: true,
              title: "You're online",
              message: 'Receiving requests',
              badgeLabel: 'ONLINE',
            ),
            LocationStateView(
              status: LocationLoadStatus.permissionDenied,
              searchingLabel: 'Finding your location…',
              deniedTitle: 'Location permission is off',
              deniedMessage: 'Taarraa needs your location.',
              failedTitle: "Couldn't get your location",
              openSettingsLabel: 'Open settings',
              onOpenSettings: () {},
            ),
          ],
        ),
    false
  ),
  'online pill': (
    () => OnlineStatusPillView(isOnline: false, label: 'OFFLINE', onTap: () {}),
    false
  ),
  'approval gate': (
    () => const Scaffold(
          body: Stack(
            children: <Widget>[
              ApprovalGateView(
                status: DriverApprovalStatus.rejected,
                title: 'Application not approved',
                message: 'Please re-submit your documents.',
                actionLabel: 'Contact support',
              ),
            ],
          ),
        ),
    true
  ),
  'payment receipt': (
    () => const Column(
          children: <Widget>[
            const PaymentHeader(bookingCode: '48213'),
            const PaymentHero(
              method: 'Cash',
              amount: '៛7,600',
              distance: '3.5 km',
              duration: '14:20',
              time: '09:30',
            ),
            const PaymentRoute(
              passengerName: 'Mey Lin',
              startAddress: 'St. 271, Phnom Penh',
              endAddress: 'Sisowath Quay',
            ),
          ],
        ),
    false
  ),
  'history detail': (
    () => TripDetailBody(
          trip: MapHistoryDetailArgs(
            typeVehicleId: 2,
            cost: '129,100',
            distand: '13.1 km',
            duration: '1:08:24',
            latStart: 11.55,
            lngStart: 104.92,
            latEnd: 11.57,
            lngEnd: 104.93,
            invoiceId: '7712',
            passengerName: 'Sreymom Chanthavy Sokunthea',
            startAddress: 'No. 12, Street 271, Sangkat Tuol Tumpung Ti Muoy, '
                'Chamkar Mon, Phnom Penh, 12306, Cambodia',
            endAddress: 'Phnom Penh International Airport, Pou Senchey',
            paymentMethod: 'Cash',
            tripTime: DateTime(2026, 9, 12, 9, 30),
          ),
          canCallPassenger: true,
          onCallPassenger: () {},
          onContactSupport: () {},
        ),
    false
  ),
  'history + wallet + news': (
    () => Column(
          children: <Widget>[
            TTabs(
                labels: const <String>['Completed', 'Cancelled'],
                index: 0,
                onChanged: (_) {}),
            HistoryCardWidget(item: _trip(), canOpenDetail: true),
            Row(
              children: <Widget>[
                TChip(label: 'All', selected: true, onTap: () {}),
                TChip(label: 'Commission', selected: false, onTap: () {}),
              ],
            ),
            const WalletBalanceCard(
              label: 'Balance',
              amount: '៛1,285,400',
              note: 'Platform commission: 10% of each trip',
            ),
            WalletDebtCard(
              title: 'You owe ៛5,000',
              message: 'Unpaid commission from cash trips. Top up to clear it.',
              hint: 'You have ៛5,160 in invite rewards. Transfer it to pay '
                  'this.',
              actionLabel: 'Transfer to balance',
              onAction: () {},
            ),
            const TransactionRow(
              title: 'Referral reward',
              kind: WalletTxKind.referralReward,
              direction: WalletTxDirection.moneyIn,
              amount: '+៛1,100,000',
              time: '09:14',
              status: 'Pending',
            ),
            NewsCard(
                title: 'Holiday hours',
                body: 'Closed Monday.',
                date: '2026-09-01',
                unread: true,
                onTap: () {}),
            const ContactHeader(
              title: 'PU Taxi support',
              blurb: 'Feel free to reach out to us if you have any questions, '
                  'feedback, or issues.',
            ),
            ContactGroup(
              children: <Widget>[
                PhoneRow(
                    carrier: 'Cellcard', number: '012 285 048', onCall: () {}),
                ContactInfoRow(
                  icon: DsIcons.home,
                  overline: 'Office · open in maps',
                  value: '#74, Street 192, Sangkat Teuk Laok 3, Toul Kork '
                      'District, Phnom Penh',
                  onTap: () {},
                ),
              ],
            ),
            ContactRow(
                icon: DsIcons.phone,
                label: 'Smart: +855 70 427 213',
                onTap: () {}),
          ],
        ),
    false
  ),
  // DD-45: the invite QR sheet, the rewards and people screens, and the
  // sign-up invite code — with the longest figures they are likely to hold.
  'invite': (
    () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: InviteFab(semanticLabel: 'My QR', onPressed: () {}),
            ),
            InviteQrCard(
              data: 'https://putaxi.example/i/PU7K2MABCDEF',
              code: 'PU7K2MABCDEF',
              codeLabel: 'Invite code',
              copyLabel: 'Copy code',
              qrLabel: 'Your invite QR code',
              qrSize: 120,
              onCopy: () {},
            ),
            const InviteRules(
              driverRule:
                  'A driver joins: you get 1% of each top-up they make.',
              passengerRule: 'A passenger joins: you get 10% of our commission '
                  'on each trip they take.',
            ),
            InviteSummaryCard(
              title: 'Invite rewards',
              summary: '៛1,285,400 earned · 128 invited',
              onTap: () {},
            ),
          ],
        ),
    false
  ),
  'invite rewards': (
    () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RewardBalanceCard(
              label: 'Invite rewards',
              amount: '៛1,285,400',
              caption: 'Not in your balance yet · 128 invited',
              transferLabel: 'Transfer to balance',
              onTransfer: () {},
              onTap: () {},
              figures: const <(String, String)>[
                ('Total earned', '៛1,285,400'),
                ('Transferred to balance', '៛1,100,000'),
              ],
            ),
            const RewardSplitCard(
              driversLabel: 'From drivers',
              driversAmount: '៛1,100,000',
              passengersLabel: 'From passengers',
              passengersAmount: '៛185,400',
            ),
            TransferAmountBody(
              availableText: 'Reward balance: ៛1,285,400',
              amountLabel: 'Amount',
              symbol: '៛',
              allLabel: 'All',
              allValue: '1285400',
              wholeUnits: true,
              parse: (String text) => num.tryParse(text),
              errorFor: (_) => null,
              linesFor: (_) => const <String>[
                '៛5,000 pays what you owe. ៛160 goes to your balance.',
                'Balance after: ៛1,285,400',
                'Rewards left: ៛1,280,240',
              ],
              confirmLabelFor: (_) => 'Transfer ៛1,285,400',
              warning: 'This cannot be moved back.',
              cancelLabel: 'Cancel',
              onConfirm: (_) {},
              onCancel: () {},
            ),
            const InviteDayHeader(label: 'Yesterday'),
            const RewardTile(
              name: 'Sokha Vann Chanthou Rithy',
              caption: 'Top-up ៛1,000,000 · 09:14',
              amount: '+៛10,000',
              icon: DsIcons.car,
            ),
            const RewardTile(
              name: 'Transferred to balance',
              caption: '12:00',
              amount: '−៛1,100,000',
              icon: DsIcons.wallet,
              moneyIn: false,
            ),
            const InviteeTile(
              name: 'Chanthou Ly Sreymom',
              caption: 'Passenger · Joined 12 Sep',
              earned: '+៛185,400',
            ),
            const InviteeTile(
              name: 'Vuthy Nhem',
              caption: 'Driver · Joined 30 Sep',
              earned: 'No rewards yet',
              hasEarned: false,
            ),
            InviteCodeField(
              controller: TextEditingController(text: 'SOKHA88'),
              status: InviteCodeStatus.invalid,
              label: 'Invite code (optional)',
              hint: 'Type or scan a code',
              scanLabel: 'Scan invite QR',
              errorText:
                  'Code not recognised. Check it, or clear it to continue.',
              onChanged: (_) {},
              onScan: () {},
            ),
            const ScanOverlay(
              hint: 'This is not a PU Taxi invite QR',
              isWarning: true,
            ),
          ],
        ),
    false
  ),
  'dialog + app bar': (
    () => Scaffold(
          appBar: const TAppBar(title: 'Announcements'),
          body: TDialog(
            title: 'Cancel request?',
            message: 'The passenger is waiting. Cancel this request?',
            actions: <Widget>[
              TButton(label: 'Stay', size: TButtonSize.small, onPressed: () {}),
              TButton(
                label: 'Yes, cancel',
                variant: TButtonVariant.destructiveOutline,
                size: TButtonSize.small,
                onPressed: () {},
              ),
            ],
          ),
        ),
    true
  ),
};

void _registerControllers() {
  Get.put(LoginLogic(_auth()));
  Get.put(OtpLogic(_auth(),
      phoneNumberModel: null, phoneNumber: '900000001', onResend: () {}));
  Get.put(RegisterLogic(_auth()));
  Get.put(VehicleController(_Vehicles()));
  Get.put(ProfileLogic(
      ProfileRepository(ProfileDatasource(apiClient: ApiClient(dio: Dio())))));
}

Future<void> _pump(
  WidgetTester t,
  (Widget Function(), bool) surface, {
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  double width = 390,
}) async {
  t.view.physicalSize = Size(width * 3, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final (Widget Function() build, bool page) = surface;
  Widget scaled(Widget child) => Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      );
  await t.pumpWidget(
    page
        ? localizedHostPage(scaled(build()), locale: locale)
        : localizedHost(scaled(build()), locale: locale),
  );
  // Pinput's cursor and the pulse dots never settle: pump frames.
  for (int i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(_registerControllers);
  tearDown(() {
    Get.find<OtpLogic>().onClose();
    Get.reset();
  });

  for (final MapEntry<String, (Widget Function(), bool)> s
      in _surfaces.entries) {
    testWidgets('${s.key}: 48 px targets, labels, contrast',
        (WidgetTester t) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await _pump(t, s.value);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(t, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final Locale l in const <Locale>[Locale('en'), Locale('km')]) {
      testWidgets(
          '${s.key}: nothing clips at text scale 1.3 (${l.languageCode}, 320 px)',
          (WidgetTester t) async {
        await _pump(t, s.value, locale: l, textScale: 1.3, width: 320);
        expect(t.takeException(), isNull);
      });
    }
  }

  test('no text style under 12 px in the type scale', () {
    final String tokens = File('lib/core/theme/tokens.dart').readAsStringSync();
    for (final RegExpMatch m
        in RegExp(r': _style\((\d+),').allMatches(tokens)) {
      expect(int.parse(m.group(1)!), greaterThanOrEqualTo(12));
    }
    for (final File f in Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))) {
      for (final RegExpMatch m in RegExp(r'fontSize: (\d+(\.\d+)?)')
          .allMatches(f.readAsStringSync())) {
        expect(double.parse(m.group(1)!), greaterThanOrEqualTo(12),
            reason: f.path);
      }
    }
  });
}
