import 'dart:convert';

import 'package:pu_taxi_driver/core/storage/key_storages.dart';
import 'package:pu_taxi_driver/core/utils/pretty_logger.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSet {
  static Future<void> setPhoneNumber(String phoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.phoneNumber, phoneNumber);
    tlog("phone stored in pref $phoneNumber");
  }

  static Future<void> setDriverServicePref(bool isAvailable) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.driverService, isAvailable);
  }

  /// DD-37: keeps the at-pickup waiting timer across an app restart.
  static Future<void> setArrivedAt(int bookingId, DateTime at) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        StorageKeys.arrivedAt, '$bookingId|${at.millisecondsSinceEpoch}');
  }

  /// Keeps the trip meter across an app restart: the metres driven so far
  /// for [bookingId], and the point they were last counted at, so the stretch
  /// covered while the app was closed can be added when it comes back.
  ///
  /// The meter used to live only in the trip screen. A restart mid-trip set
  /// it back to zero, so the driver saw the minimum fare again — and
  /// `complete-drive` was sent that short distance.
  static Future<void> setTripDistance(
    int bookingId, {
    required double meters,
    required double latitude,
    required double longitude,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.tripDistance,
      '$bookingId|$meters|$latitude|$longitude',
    );
  }

  static Future<void> saveLocation(double latitude, double longitude) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', latitude);
    await prefs.setDouble('longitude', longitude);
  }

  // static Future<void> storeOTPData(OtpReponseModel driver) async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String driverJson = jsonEncode(driver.toJson());
  //   await prefs.setString(StorageKeys.driverDate, driverJson);
  // }
  static Future<void> storeDriverData(RegisterModel registerModel) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String registerJson = jsonEncode(registerModel.toJson());
    await prefs.setString(StorageKeys.registerData, registerJson);
  }

  //// FCM TOKEN
  Future<void> setFcmToken({String? fcmToken}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("fcm_token_data", fcmToken!);
    tlog("fcmToken stored in pref $fcmToken");
  }
}
