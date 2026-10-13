import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pu_taxi_driver/core/utils/app_constant.dart';
import 'package:pu_taxi_driver/core/utils/pretty_logger.dart';
import 'package:pu_taxi_driver/mock/mock_mode.dart';
import 'package:pu_taxi_driver/services/session_service.dart';

/// The Android service that runs while the driver is online (DD-58), seen
/// from Dart. The service itself is `OnlineService.kt`.
///
/// It keeps the app's process, its socket and its GPS alive while the screen
/// is off or another app is in front, behind a permanent "You're online"
/// notification. When the driver clears the app from the recent apps, the
/// service tells the backend the driver is offline, unless a trip is running
/// ([setOnTrip]).
///
/// Android only. Elsewhere, and in tests, every call does nothing.
class OnlineService with WidgetsBindingObserver {
  OnlineService({
    MethodChannel? channel,
    bool? isAndroid,
    Future<String?> Function()? readToken,
    String? Function()? offlineUrl,
    String Function(String key)? text,
  })  : _channel = channel ?? const MethodChannel(channelName),
        _isAndroid = isAndroid ?? Platform.isAndroid,
        _readToken = readToken ?? (() => SessionService.instance.getToken()),
        _offlineUrl = offlineUrl ?? _defaultOfflineUrl,
        _text = text ?? ((String key) => key.tr());

  static final OnlineService instance = OnlineService();

  static const String channelName = 'pu_taxi_driver/online_service';

  final MethodChannel _channel;
  final bool _isAndroid;
  final Future<String?> Function() _readToken;
  final String? Function() _offlineUrl;
  final String Function(String key) _text;

  /// The driver is online, so the service should be running.
  bool _wanted = false;
  bool _observing = false;

  /// The mock backend has no server to tell.
  static String? _defaultOfflineUrl() => MockMode.isActive
      ? null
      : '${AppConstant.baseUrlApi}/taxi-driver/set-status';

  /// Call when the driver goes online. Safe to call again: the running
  /// service takes the new text and token.
  Future<void> start() async {
    _wanted = true;
    if (!_isAndroid) return;
    _observe();
    final Object? started = await _invoke('start', <String, Object?>{
      'title': _text('YOU_ARE_ONLINE'),
      'text': _text('ONLINE_SUB'),
      'offlineUrl': _offlineUrl(),
      'token': await _readToken(),
    });
    if (started == false) {
      tlog('OnlineService not started: no location permission');
    }
  }

  /// Call when the driver goes offline or the session ends.
  Future<void> stop() async {
    _wanted = false;
    if (!_isAndroid) return;
    await _invoke('stop');
  }

  /// During a trip, clearing the app does not put the driver offline.
  Future<void> setOnTrip(bool onTrip) async {
    if (!_isAndroid) return;
    await _invoke('setOnTrip', onTrip);
  }

  /// Android does not start a service for an app that is not in front. If
  /// the driver went online at such a moment, start it when they are back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wanted) unawaited(start());
  }

  void _observe() {
    if (_observing) return;
    _observing = true;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<Object?> _invoke(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (e) {
      tlog('OnlineService.$method refused: ${e.code} ${e.message}');
    } on MissingPluginException {
      tlog('OnlineService.$method: no native side');
    }
    return null;
  }
}
