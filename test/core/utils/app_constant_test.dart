import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';

void main() {
  test(
    'baseUrlApi/socketBasedUrl default to prod when no --dart-define is passed (F-07)',
    () {
      expect(AppConstant.baseUrlApi, 'https://api.tara-taxi.com');
      expect(AppConstant.socketBasedUrl, 'https://socket.tara-taxi.com');
    },
  );
}
