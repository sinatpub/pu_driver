import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:tara_driver_application/core/storages/get_storages.dart';
import 'package:tara_driver_application/core/storages/set_storages.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/data/datasources/set_status_api.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:tara_driver_application/core/helper/local_notification_helper.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Taxi {
  Taxi._internal();
  static Taxi? _singleton = Taxi._internal();

  static Taxi get shared {
    _singleton ??= Taxi._internal();
    return _singleton!;
  }

  // Channels and APIs
  static const MethodChannel settingsChannel =
      MethodChannel('com.tara_driver_application/settings');
  final SetDriverStatusApi statusApi = SetDriverStatusApi();

  // Properties
  Driver? driver;
  Location location = Location();
  PermissionStatus locationPermissionStatus = PermissionStatus.granted;
  LocationData? driverLocation;
  LatLng? currentLocation;
  LatLng? passengerLocation;

  Timer? _locationUpdateTimer;
  bool isDriverActive = true;
  int? driverStatus;

  double maxAccuracy = 1000, maxSpeed = 40, maxBestAccuracy = 80;

  // Markers
  Marker? driverMarker;
  Marker? passengerMarker;

  Future<void> init() async {
    requestNotificationPermission();
  }

  Future<void> requestNotificationPermission() async {
    if (await permission.Permission.notification.isDenied) {
      await permission.Permission.notification.request();
    }
  }

  Future<void> checkDriverAvailability() async {
    try {
      var response = await statusApi.getStatusDriver();
      if (response.data != null) {
        isDriverActive = response.data?.isAvailable == 1;
        await StorageSet.setDriverServicePref(isDriverActive);
      } else {
        isDriverActive = false;
      }
    } catch (e) {
      tlog("Driver Status: $e");
    }
  }

  Future<void> notifyBooking(
      {required String title, String? description, bool isSound = true}) async {
    try {
      await NotificationLocal.notificationBooking(
          channel: NotificationLocal.channel,
          plugin: NotificationLocal.notifications,
          title: title,
          useCustomSound: isSound,
          description: description);
      tlog('Notification triggered', level: LogLevel.debug);
    } catch (e) {
      tlog('Error triggering notification: $e', level: LogLevel.error);
    }
  }

  // Last known position

  // * Total Distance
  double totalDistance = 0.0;
  geoLocator.Position? lastPosition;

  // * Simulate Tracking Distance
  void simulateTrackingDistance() {
    getRealTimePassengerLocation()
        .listen((geoLocator.Position currentLocation) async {
      if (lastPosition != null) {
        // Calculate the distance between last and current positions
        double distance = await trackDistance(lastPosition, currentLocation);
        if (distance > 0) {
          totalDistance += distance;
        }

        Logger().e('Distance for this update: $distance meters');
        Logger().e('Total Distance: ${totalDistance / 1000} km');
      }

      lastPosition = currentLocation;
    });
  }

  // * Update Real time Location in Google Map
  Stream<geoLocator.Position> getRealTimePassengerLocation() {
    return geoLocator.Geolocator.getPositionStream(
        locationSettings: const geoLocator.LocationSettings(
      accuracy: geoLocator.LocationAccuracy.high,
      distanceFilter: 10,
    ));
  }

  // * Function to Track Distance
  Future<double> trackDistance(geoLocator.Position? lastPosition,
      geoLocator.Position currentPosition) async {
    if (lastPosition != null) {
      // Calculate the distance between last and current positions
      return geoLocator.Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
    }
    return 0.0; // Return 0 if lastPosition is null
  }
}
