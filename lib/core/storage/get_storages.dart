import 'dart:convert';

import 'package:pu_taxi_driver/core/storage/key_storages.dart';
import 'package:pu_taxi_driver/core/utils/pretty_logger.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageGet {
  static Future<String?> getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var phonePreg = prefs.getString(StorageKeys.phoneNumber);
    tlog("get pref phone number $phonePreg");
    return phonePreg;
  }

  static Future<bool?> getDriverServicePref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.driverService);
  }

  static Future<RegisterModel?> getDriverData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? driverJson = prefs.getString(StorageKeys.registerData);
    if (driverJson != null) {
      Map<String, dynamic> driverMap = jsonDecode(driverJson);

      tlog("Get Storage Driver: $driverMap");
      return RegisterModel.fromJson(driverMap);
    }
    return null;
  }

  static Future<LatLng?> getSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');

    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }
    return null;
  }

  /// DD-37: when the driver arrived for [bookingId]; null when none was
  /// saved, or it was saved for another booking.
  static Future<DateTime?> getArrivedAt(int bookingId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? parts =
        prefs.getString(StorageKeys.arrivedAt)?.split('|');
    if (parts == null || parts.length != 2) return null;
    if (parts[0] != '$bookingId') return null;
    final int? ms = int.tryParse(parts[1]);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// What [StorageSet.setTripDistance] saved for [bookingId]; null when
  /// nothing was saved, it was saved for another booking, or it cannot be
  /// read.
  static Future<({double meters, LatLng lastPoint})?> getTripDistance(
    int bookingId,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? parts =
        prefs.getString(StorageKeys.tripDistance)?.split('|');
    if (parts == null || parts.length != 4) return null;
    if (parts[0] != '$bookingId') return null;
    final double? meters = double.tryParse(parts[1]);
    final double? latitude = double.tryParse(parts[2]);
    final double? longitude = double.tryParse(parts[3]);
    if (meters == null || meters < 0 || latitude == null || longitude == null) {
      return null;
    }
    return (meters: meters, lastPoint: LatLng(latitude, longitude));
  }

  ////// FCM TOKEN
  static Future<String?> getFcmTokenLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var fcmPref = prefs.getString(StorageKeys.fcmTokenData);
    tlog("get pref FCM TOKEN $fcmPref");
    return fcmPref;
  }
}
