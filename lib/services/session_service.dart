import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/storage/token_store.dart';
import 'package:tara_driver_application/core/storage/get_storages.dart';
import 'package:tara_driver_application/services/location_service.dart';

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

  Future<void> clear() async {
    _cachedToken = null;
    await _tokenStore.clear();
  }

  Future<void> handleUnauthorized() async {
    await clear();
    LocationService.instance.stop();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<String?> _readLegacyToken() async {
    final driverData = await StorageGet.getDriverData();
    return driverData?.data?.token;
  }
}
