import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/state.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart'
    hide Color;
import 'package:tara_driver_application/presentation/screens/login/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/screens/history/data/models/history_driver_info_model.dart'
    hide Vehicle;
import 'package:tara_driver_application/presentation/screens/profile/data/datasource/profile_datasource.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/models/profile_model.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/repository/profile_repository.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';
import 'package:tara_driver_application/presentation/screens/announcement/widgets/news_card.dart';
import 'package:tara_driver_application/presentation/screens/announcement_detail/view.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/ride_request_bottom_pop_widget.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_header.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/view.dart';
import 'package:tara_driver_application/presentation/screens/drawer/state.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/approval_gate.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/driver_drawer.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/online_status_pill.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_card_widget.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/view.dart';
import 'package:tara_driver_application/presentation/screens/home/state.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/driver_status_card.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/location_state_view.dart';
import 'package:tara_driver_application/presentation/screens/login/logic.dart';
import 'package:tara_driver_application/presentation/screens/login/view.dart';
import 'package:tara_driver_application/presentation/screens/otp/logic.dart';
import 'package:tara_driver_application/presentation/screens/otp/view.dart';
import 'package:tara_driver_application/presentation/screens/profile/logic.dart';
import 'package:tara_driver_application/presentation/screens/profile/state.dart';
import 'package:tara_driver_application/presentation/screens/register/logic.dart';
import 'package:tara_driver_application/presentation/screens/register/view.dart';
import 'package:tara_driver_application/presentation/screens/splash_screen/view.dart';
import 'package:tara_driver_application/presentation/screens/term_condition/view.dart';
import 'package:tara_driver_application/presentation/screens/wallet/widgets/wallet_widgets.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/widge_update.dart';

import '../helpers/localized_host.dart';

/// UX-redesign Q1 — render every redesigned surface to disk.
///
/// Unlike the accessibility suite (which only guarantees tap targets and
/// contrast), this harness *produces* the Q1 evidence: a real-Khmer-font PNG
/// and a machine-readable geometry dump for each surface at both the regular
/// (390 px) and legacy narrow (320 px) widths, in English and Khmer.
///
/// The geometry dump is the text-level form of the render: it records the text
/// styles, corner radii, fill colours, paddings and control sizes in play, so
/// spacing/radius/type/colour checks can run without pixel-peeping.
const String _outRoot = 'docs/qa/q1';

typedef _SurfaceDef = ({
  String name,
  Widget Function() build,
  bool page,
});

Future<void> _loadRealFonts() async {
  final List<String> fonts = <String>[
    'fonts/KantumruyPro-Regular.ttf',
    'fonts/KantumruyPro-SemiBold.ttf',
    'fonts/KantumruyPro-VariableFont_wght.ttf',
  ];
  for (final String asset in fonts) {
    final ByteData data = await rootBundle.load(asset);
    final FontLoader loader = FontLoader('KantumruyPro')
      ..addFont(Future<ByteData>.value(data));
    await loader.load();
  }
}

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

DataHistory _trip({int status = 4, String statusName = 'completed'}) =>
    DataHistory.fromJson(<String, dynamic>{
      'id': 1,
      'start_latitude': '11.5',
      'start_longitude': '104.9',
      'end_latitude': '11.6',
      'end_longitude': '104.9',
      'start_time': '2026-09-12 09:30:00',
      'start_address': 'St. 271, Phnom Penh',
      'end_address': 'Sisowath Quay',
      'status': status,
      'status_name': statusName,
      'passenger': <String, dynamic>{'name': 'Mey Lin'},
      'payment': <String, dynamic>{
        'invoice_id': 7712,
        'distance': '3.5 km',
        'duration': '14 mins',
        'amount': '7600',
        'payment_method': 'Cash',
      },
    });

Widget _sheet(int processType) => Stack(
      children: <Widget>[
        ModelBottomSheetNewRequestWidget(
          bookingId: 1,
          bookingCode: 48213,
          passengerId: 2,
          processType: processType,
          profilePassanger: '',
          namePassanger: 'Sok Dara',
          phonePassanger: '090000001',
          passegerLocationName: 'St. 271, Phnom Penh',
          whereToGoLocationName: 'Independence Monument',
          distandTotal: 3.5,
          totalFee: '7600',
          onTap: () {},
          onCancel: () {},
          duration: '00:12:40',
          distance: '3.20 km',
          fare: '7,600',
        ),
      ],
    );

/// The shell's app bar, assembled from [DrawerScreen]'s own widgets so the
/// render is a faithful capture of the shipped strip (menu, wordmark, bell,
/// availability pill + hairline divider).
Widget _shellAppBar() {
  return Builder(
    builder: (BuildContext context) {
      final TaarraaColors c = context.colors;
      final List<Widget> actions = <Widget>[
        const TIconButton(
          icon: DsIcons.bell,
          semanticLabel: '',
          filled: false,
          onPressed: null,
        ),
        const SizedBox(width: Insets.s8),
        const OnlineStatusPillView(
            isOnline: true, label: 'ONLINE', onTap: _noop),
        const SizedBox(width: Insets.s12),
      ];
      return Scaffold(
        backgroundColor: c.bgPage,
        appBar: AppBar(
          toolbarHeight: 64,
          backgroundColor: c.bgSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: Insets.s8,
          leadingWidth: Sizes.touchTarget + Insets.s16,
          leading: const Padding(
            padding: EdgeInsets.only(left: Insets.s8),
            child: TIconButton(
              icon: DsIcons.menu,
              semanticLabel: '',
              filled: false,
              onPressed: null,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppConstant.titleApp,
                style: context.texts.subtitle
                    .copyWith(color: c.textPrimary, letterSpacing: 1.5),
              ),
              Text(
                'DRIVER · តារា',
                style: context.texts.micro
                    .copyWith(color: c.brandText, letterSpacing: 1),
              ),
            ],
          ),
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: c.borderDivider),
          ),
        ),
        body: const SizedBox.shrink(),
      );
    },
  );
}

/// The cover-all surface list — the union of everything renderable without a
/// live backend or a map platform view (which [history detail] flags below).
final List<_SurfaceDef> _surfaces = <_SurfaceDef>[
  (name: 'S01 splash', build: _splash, page: true),
  (name: 'S02 login', build: () => const LoginPage(), page: true),
  (name: 'S03 otp', build: () => const OtpPage(), page: true),
  (name: 'S04 register', build: () => const RegisterPage(), page: true),
  (name: 'S05 shell app bar', build: _shellAppBar, page: true),
  (
    name: 'S05 drawer',
    build: () => Scaffold(
          body: DriverDrawer(activeTab: DrawerTab.home, onSelect: (_) {}),
        ),
    page: true
  ),
  (
    name: 'S05 approval unknown',
    build: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ApprovalGateView(
                  status: DriverApprovalStatus.unknown,
                  title: 'Checking approval',
                  message: 'Please wait.',
                  actionLabel: 'Try again',
                ),
              ),
            ],
          ),
        ),
    page: true
  ),
  (
    name: 'S05 approval pending',
    build: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ApprovalGateView(
                  status: DriverApprovalStatus.pending,
                  title: 'Waiting for approval',
                  message: 'Please wait.',
                  actionLabel: 'Contact support',
                ),
              ),
            ],
          ),
        ),
    page: true
  ),
  (
    name: 'S05 approval rejected',
    build: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ApprovalGateView(
                  status: DriverApprovalStatus.rejected,
                  title: 'Application not approved',
                  message: 'Please re-submit your documents.',
                  actionLabel: 'Contact support',
                ),
              ),
            ],
          ),
        ),
    page: true
  ),
  (
    name: 'S05 offline banner',
    build: () => TBanner(message: 'NO_INTERNET_RECONNECTING'.tr()),
    page: false
  ),
  (
    name: 'S06 status online',
    build: () => const DriverStatusCardView(
          isOnline: true,
          title: "You're online",
          message: 'Receiving requests',
          badgeLabel: 'ONLINE',
        ),
    page: false
  ),
  (
    name: 'S06 status offline',
    build: () => const DriverStatusCardView(
          isOnline: false,
          title: 'You are offline',
          message: 'Offline, no requests',
          badgeLabel: 'OFFLINE',
        ),
    page: false
  ),
  (
    name: 'S06 location searching',
    build: () => LocationStateView(
          status: LocationLoadStatus.inProgress,
          searchingLabel: 'Finding your location…',
          deniedTitle: 'Location permission is off',
          deniedMessage: 'Taarraa needs your location.',
          failedTitle: "Couldn't get your location",
          openSettingsLabel: 'Open settings',
          onOpenSettings: () {},
        ),
    page: false
  ),
  (
    name: 'S06 location denied',
    build: () => LocationStateView(
          status: LocationLoadStatus.permissionDenied,
          searchingLabel: 'Finding your location…',
          deniedTitle: 'Location permission is off',
          deniedMessage: 'Taarraa needs your location.',
          failedTitle: "Couldn't get your location",
          openSettingsLabel: 'Open settings',
          onOpenSettings: () {},
        ),
    page: false
  ),
  (
    name: 'S06 location failed',
    build: () => LocationStateView(
          status: LocationLoadStatus.failure,
          searchingLabel: 'Finding your location…',
          deniedTitle: 'Location permission is off',
          deniedMessage: 'Taarraa needs your location.',
          failedTitle: "Couldn't get your location",
          openSettingsLabel: 'Open settings',
          onOpenSettings: () {},
        ),
    page: false
  ),
  (name: 'S06 force update', build: () => const WidgetUpdate(), page: false),
  (
    name: 'S06 resume',
    build: () => const TDialog(
          title: 'Resuming your trip…',
          top: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
    page: true
  ),
  (
    name: 'S07 header request',
    build: () => const TripHeader(
          stage: TripStage.requestReceived,
          title: 'New request',
          bookingCode: 48213,
        ),
    page: false
  ),
  (
    name: 'S07 header pickup',
    build: () => const TripHeader(
          stage: TripStage.enRouteToPickup,
          title: 'Going to pickup',
          bookingCode: 48213,
        ),
    page: false
  ),
  (
    name: 'S07 header waiting',
    build: () => const TripHeader(
          stage: TripStage.waitingAtPickup,
          title: 'Waiting at pickup',
          bookingCode: 48213,
        ),
    page: false
  ),
  (
    name: 'S07 header on trip',
    build: () => const TripHeader(
          stage: TripStage.inProgress,
          title: 'On trip',
          bookingCode: 48213,
        ),
    page: false
  ),
  // Bottom sheets need a bounded full-screen host (like the a11y test), not
  // the scrollable `localizedHost` — they lay out with `Expanded`.
  (name: 'S07 request', build: () => Scaffold(body: _sheet(1)), page: true),
  (name: 'S07 pickup', build: () => Scaffold(body: _sheet(2)), page: true),
  (
    name: 'S07 at pickup',
    build: () => Scaffold(body: _sheet(3)),
    page: true
  ),
  (name: 'S07 on trip', build: () => Scaffold(body: _sheet(4)), page: true),
  (
    name: 'S08 receipt',
    build: () => Column(
          children: <Widget>[
            ReceiptCard(
              passengerName: 'Mey Lin',
              method: 'Cash',
              distance: '3.50 km',
              duration: '14:20',
              dateTime: 'Sat/12/Sep/2026 09:30 AM',
              startAddress: 'St. 271, Phnom Penh',
              endAddress: 'Sisowath Quay',
            ),
            TotalBox(amount: '៛7,600'),
          ],
        ),
    page: false
  ),
  (
    name: 'S09 history tabs',
    build: () => Column(
          children: <Widget>[
            TTabs(
                labels: const <String>['Completed', 'Cancelled'],
                index: 0,
                onChanged: (_) {}),
            HistoryCardWidget(item: _trip(), canOpenDetail: true),
            HistoryCardWidget(
                item: _trip(status: 5, statusName: 'cancel'),
                canOpenDetail: false),
          ],
        ),
    page: false
  ),
  (
    name: 'S10 history detail card',
    build: () => const TripDetailCard(
          distance: '3.5 km',
          duration: '14 mins',
          amount: '៛7,600',
        ),
    page: false
  ),
  (
    name: 'S11 wallet',
    build: () => Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: WalletBalanceCard(
                    label: 'MY_WALLET'.tr(),
                    amount: '25.00 \$',
                    tone: WalletBalanceTone.wallet,
                  ),
                ),
                const SizedBox(width: Insets.s8),
                Expanded(
                  child: WalletBalanceCard(
                    label: 'COMMISSION_FARE'.tr(),
                    amount: '7,600 ៛',
                    tone: WalletBalanceTone.commission,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.s24),
            const TransactionRow(
                typeName: 'Top up', amount: '25.00 \$', date: '2026-09-12'),
          ],
        ),
    page: false
  ),
  (
    name: 'S12 news unread',
    build: () => NewsCard(
          title: 'Holiday hours',
          body: 'Closed Monday.',
          date: '2026-09-01',
          unread: true,
          onTap: () {},
        ),
    page: false
  ),
  (
    name: 'S12 news read',
    build: () => NewsCard(
          title: 'Holiday hours',
          body: 'Closed Monday.',
          date: '2026-09-01',
          unread: false,
          onTap: () {},
        ),
    page: false
  ),
  (
    name: 'S13 announcement detail',
    build: () => const AnnouncementDetailBody(
          title: 'Holiday hours',
          date: '2026-09-01',
          body: 'All Taarraa offices across Phnom Penh and Siem Reap are '
              'closed for the national holiday. On-call support continues '
              'through the driver line as usual.',
          imageUrls: <String>[],
        ),
    page: false
  ),
  (
    name: 'S14 terms',
    build: () => Column(
          children: <Widget>[
            TermRow(
              number: 1,
              text: 'Drivers must keep the vehicle clean and roadworthy at '
                  'all times.',
            ),
            const SizedBox(height: Insets.s8),
            TermRow(
              number: 2,
              text: 'Passenger drop-off removes the ride from the ledger.',
            ),
          ],
        ),
    page: false
  ),
  (
    name: 'S15 contact',
    build: () => Column(
          children: <Widget>[
            ContactRow(
                icon: DsIcons.phone,
                label: 'Smart: +855 70 427 213',
                onTap: () {}),
            ContactRow(
                icon: DsIcons.mail,
                label: 'Cellcard: +855 97 000 000',
                onTap: () {}),
          ],
        ),
    page: false
  ),
];

Widget _splash() => const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: SplashMark()),
    );

void _noop() {}

void _registerControllers() {
  Get.put(LoginLogic(_auth()));
  Get.put(OtpLogic(_auth(),
      phoneNumberModel: null, phoneNumber: '900000001', onResend: () {}));
  Get.put(RegisterLogic(_auth()));
  Get.put(VehicleController(_Vehicles()));
  Get.put(ProfileLogic(
      ProfileRepository(ProfileDatasource(apiClient: ApiClient(dio: Dio())))));

  // Present it the way the shell would after a successful fetch: a loaded
  // profile so the drawer/profile header render their real copy.
  final ProfileLogic profile = Get.find<ProfileLogic>();
  profile.state.status.value = ProfileStatus.loaded;
  profile.state.profile.value = ProfileModel(
    data: Data(
      id: 1,
      driverId: '4',
      name: 'Mey Lin',
      phone: '090000001',
      vehicle: Vehicle(id: 1, typeVehicleId: 1, plateNumber: 'PHN 2B 1111'),
    ),
  );
}

Future<void> _paint(
  WidgetTester t,
  _SurfaceDef surface, {
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  t.view.physicalSize = Size(width * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);

  final Widget host = surface.page
      ? localizedHostPage(surface.build(), locale: locale)
      : localizedHost(surface.build(), locale: locale);
  await t.pumpWidget(host);
  // Pinput's cursor and the pulse dots never settle: pump frames.
  for (int i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(_loadRealFonts);
  setUp(_registerControllers);
  tearDown(Get.reset);

  for (final _SurfaceDef surface in _surfaces) {
    testWidgets('Q1 render: ${surface.name}',
        (WidgetTester t) async {
      for (final Locale l in const <Locale>[Locale('en'), Locale('km')]) {
        for (final double w in const <double>[390, 320]) {
          Directory('$_outRoot/renders').createSync(recursive: true);
          Directory('$_outRoot/geometry').createSync(recursive: true);

          await _paint(t, surface, locale: l, width: w);
          expect(t.takeException(), isNull,
              reason:
                  '${surface.name} overflowed at ${w}px (${l.languageCode})');

          final String safe = surface.name
              .replaceAll(RegExp('[^a-z0-9]+'), '_')
              .replaceAll(RegExp('^_|_\$'), '');
          await _capturePng(t, '${safe}__${l.languageCode}__${w.toInt()}');
          await _dumpGeometry(
              t, safe, l.languageCode, w.toInt(), surface.name);
        }
      }
    });
  }
}

Future<void> _capturePng(WidgetTester t, String key) async {
  final RenderRepaintBoundary boundary =
      t.renderObject(find.byType(RepaintBoundary).first)
          as RenderRepaintBoundary;
  final ui.Image? image =
      await t.runAsync<ui.Image>(() => boundary.toImage(pixelRatio: 3));
  final ByteData? bytes = await t.runAsync<ByteData?>(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  File('$_outRoot/renders/$key.png')
      .writeAsBytesSync(bytes!.buffer.asUint8List());
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

/// Collects the geometry in play on the current frame: text styles, radii,
/// fills, paddings and control sizes — the text-level form of the render.
Future<void> _dumpGeometry(
  WidgetTester t,
  String key,
  String lang,
  int width,
  String surface,
) async {
  final Set<String> fonts = <String>{};
  final Set<String> radii = <String>{};
  final Set<String> fills = <String>{};
  final Set<String> borders = <String>{};
  final Set<String> paddings = <String>{};
  final List<Map<String, Object>> controls = <Map<String, Object>>[];

  for (final Element e in t.allElements) {
    final Widget w = e.widget;
    if (w is Text) {
      final TextStyle s = w.style ??
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
      final String txt = w.data ?? w.textSpan?.toPlainText() ?? '';
      fonts.add(_encodeTextStyle(s, txt));
    } else if (w is DecoratedBox && w.decoration is BoxDecoration) {
      _encodeBox(w.decoration as BoxDecoration, radii, fills, borders);
    } else if (w is Container &&
        w.decoration is BoxDecoration &&
        e.renderObject is RenderBox &&
        (e.renderObject! as RenderBox).hasSize) {
      _encodeBox(w.decoration as BoxDecoration, radii, fills, borders);
    } else if (w is Padding) {
      final EdgeInsets ev = w.padding.resolve(TextDirection.ltr);
      paddings
          .add('${ev.left.truncate()},${ev.top.truncate()},${ev.right.truncate()},${ev.bottom.truncate()}');
    }
    if (w is TButton || w is TIconButton) {
      final RenderBox? r = e.renderObject! as RenderBox?;
      if (r != null && r.hasSize) {
        controls.add(<String, Object>{
          'type': w.runtimeType.toString(),
          'w': r.size.width.truncate(),
          'h': r.size.height.truncate(),
        });
      }
    }
  }

  final Map<String, Object?> geo = <String, Object?>{
    'surface': surface,
    'key': key,
    'locale': lang,
    'width': width,
    'textStyles': fonts.toList(growable: false)..sort(),
    'radii': radii.toList(growable: false)..sort(),
    'fills': fills.toList(growable: false)..sort(),
    'borders': borders.toList(growable: false)..sort(),
    'paddings': paddings.toList(growable: false)..sort(),
    'controls': controls,
  };
  File('$_outRoot/geometry/${key}__${lang}__${width}.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(geo));
}

String _encodeTextStyle(TextStyle s, String text) {
  final String feature = (s.fontFeatures ?? const <FontFeature>[]).isEmpty
      ? ''
      : ' [${(s.fontFeatures ?? const <FontFeature>[]).join(',')}]';
  final Color? c = s.color;
  final String color = c == null ? 'inherit' : _hex(c);
  final String plain = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final String sample = plain.length <= 24 ? plain : '${plain.substring(0, 24)}…';
  return '${s.fontSize}px/${s.fontWeight?.value ?? 400} $color '
      '${s.fontFamily ?? 'unknown'} '
      '$sample$feature';
}

void _encodeBox(
  BoxDecoration b,
  Set<String> radii,
  Set<String> fills,
  Set<String> borders,
) {
  final Color? f = b.color;
  if (f != null) fills.add(_hex(f));
  final BorderRadiusGeometry? br = b.borderRadius;
  if (br != null) {
    final BorderRadius rb = br.resolve(TextDirection.ltr);
    radii.add([
      rb.topLeft.x,
      rb.topRight.x,
      rb.bottomRight.x,
      rb.bottomLeft.x,
    ].map((double v) => v.truncate()).join(','));
  }
  if (b.border != null) {
    borders.add(
        '${b.border!.top.width.truncate()}px ${_hex(b.border!.top.color)}');
  }
}