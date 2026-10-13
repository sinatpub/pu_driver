import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/services/online_service.dart';

/// DD-58 — the Dart side of the Android service that runs while the driver
/// is online. What the native side does with these calls (the notification,
/// the offline call when the app is cleared) can only be seen on a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(OnlineService.channelName);
  late List<MethodCall> calls;
  Object? Function(MethodCall call)? answer;

  OnlineService service({bool isAndroid = true, String? offlineUrl}) =>
      OnlineService(
        channel: channel,
        isAndroid: isAndroid,
        readToken: () async => 'a-token',
        offlineUrl: () => offlineUrl,
        text: (String key) => 'text of $key',
      );

  setUp(() {
    calls = <MethodCall>[];
    answer = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return answer?.call(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('going online starts the service with what it needs', () async {
    await service(offlineUrl: 'https://api.test/taxi-driver/set-status')
        .start();

    expect(calls.single.method, 'start');
    expect(calls.single.arguments, <String, Object?>{
      'title': 'text of YOU_ARE_ONLINE',
      'text': 'text of ONLINE_SUB',
      'offlineUrl': 'https://api.test/taxi-driver/set-status',
      'token': 'a-token',
    });
  });

  test('going offline stops it', () async {
    final OnlineService s = service();
    await s.start();
    await s.stop();

    expect(calls.map((MethodCall c) => c.method), <String>['start', 'stop']);
  });

  test('a trip is reported, so clearing the app does not end it', () async {
    final OnlineService s = service();
    await s.setOnTrip(true);
    await s.setOnTrip(false);

    expect(
      calls.map((MethodCall c) => '${c.method} ${c.arguments}'),
      <String>['setOnTrip true', 'setOnTrip false'],
    );
  });

  test('not on Android: nothing is called', () async {
    final OnlineService s = service(isAndroid: false);
    await s.start();
    await s.setOnTrip(true);
    await s.stop();

    expect(calls, isEmpty);
  });

  test('back in front while online: the service is started again', () async {
    final OnlineService s = service();
    await s.start();
    calls.clear();

    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(calls.single.method, 'start');
  });

  test('back in front while offline: it is not started', () async {
    final OnlineService s = service();
    await s.start();
    await s.stop();
    calls.clear();

    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(calls, isEmpty);
  });

  test('a refusal from Android is not an error for the driver', () async {
    answer = (_) => throw PlatformException(code: 'not_started');

    await expectLater(service().start(), completes);
  });
}
