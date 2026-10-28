import 'dart:async';

import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/routes/app_routes.dart';
import 'package:pu_taxi_driver/core/storage/token_store.dart';
import 'package:pu_taxi_driver/core/storage/get_storages.dart';
import 'package:pu_taxi_driver/core/storage/remove_storage.dart';
import 'package:pu_taxi_driver/services/location_service.dart';
import 'package:pu_taxi_driver/services/online_service.dart';
import 'package:pu_taxi_driver/services/socket_service.dart';

class SessionService {
  SessionService._(this._tokenStore);

  static SessionService? _instance;
  static SessionService get instance =>
      _instance ??= SessionService._(TokenStore());

  final TokenStore _tokenStore;
  String? _cachedToken;

  /// In-memory first; secure storage second; legacy plaintext blob last —
  /// a one-time migration bridge that moves the token into secure storage
  /// on first use post-upgrade, without touching any auth screen.
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final stored = await _tokenStore.read();
    if (stored != null) {
      _cachedToken = stored;
      return stored;
    }

    final legacy = await _readLegacyToken();
    if (legacy != null) {
      await saveToken(legacy);
      return legacy;
    }
    return null;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _tokenStore.write(token);
  }

  /// How many sessions have ended in this run of the app. App-lifetime
  /// state reads it to tell a new driver from the one before (`AppLogic`).
  int get endedSessions => _endedSessions;
  int _endedSessions = 0;

  Future<void> clear() async {
    _endedSessions++;
    _cachedToken = null;
    // DD-58: nobody is online without a session, and the service holds the
    // token that has just ended.
    unawaited(OnlineService.instance.stop());
    // Audit D-2: the socket is registered as this driver. Left open, ride
    // requests for them keep arriving on a phone that has signed out.
    DriverSocketService().disconnectSocket();
    await _tokenStore.clear();
    // The sign-in record carries the token too, and [getToken] falls back to
    // it: left in place, the very next request — or the next launch — read
    // the ended session's token back and signed the driver in again.
    await StorageRemove.removeDriverData();
  }

  /// Ends the session and returns to sign-in: for a refused token (401) and
  /// for the driver signing out (audit D-1, `AppLogic.signOut`).
  Future<void> endSession() async {
    await clear();
    LocationService.instance.stop();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> handleUnauthorized() => endSession();

  Future<String?> _readLegacyToken() async {
    final driverData = await StorageGet.getDriverData();
    return driverData?.data?.token;
  }
}
