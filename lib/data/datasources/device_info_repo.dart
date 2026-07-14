import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/core/storages/set_storages.dart';
import 'package:tara_driver_application/core/utils/app_log.dart';
import '../../core/api_service/base_api_service.dart';
import '../../core/api_service/client/telegram.dart';

abstract class IDeviceInfo {
  Future<bool> deviceCreateOrUpdate();
}

class DeviceInfoRepo extends IDeviceInfo {
  @override
  Future<bool> deviceCreateOrUpdate() async {
    var platform = Platform.isAndroid ? "android" : "ios";
    var deviceToken = await getFCMToken();
    if (deviceToken == null || deviceToken.isEmpty) return false;
    await StorageSet().setFcmToken(fcmToken: deviceToken);
    var bodyParse = {'device_token': deviceToken, "platform": platform};
    var result = await BaseApiService().onRequest(
        path: "/taxi-driver/push-device-token",
        method: "POST",
        bodyParse: bodyParse,
        onSuccess: (result) {
          return true;
        });
    String? message = "Driver - $platform :: $deviceToken";
    await sendToTelegram(message);

    return result;
  }

  getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // UUID for Android
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "";
    }
    return "";
  }

  Future<String?> getFCMToken() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    try {
      if (Platform.isIOS) {
        final apnsToken = await firebaseMessaging.getAPNSToken();
        final fcmToken = await firebaseMessaging.getToken();

        if (apnsToken != null) {
          return fcmToken;
        }
      } else if (Platform.isAndroid) {
        final fcmToken = await firebaseMessaging.getToken();
        if (fcmToken != null) {
          return fcmToken;
        }
      }
    } catch (e) {
      print(e.toString());
    }
    return "";
  }
}
