import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

String convertTimeString(String input) {
  final hourRegex = RegExp(r'(\d+)\s*hour[s]?', caseSensitive: false);
  final minRegex = RegExp(r'(\d+)\s*min[s]?', caseSensitive: false);
  final secRegex = RegExp(r'(\d+)\s*secon[s]?',caseSensitive: false);

  final hourMatch = hourRegex.firstMatch(input);
  final minMatch = minRegex.firstMatch(input);
  final secMatch = secRegex.firstMatch(input);

  String hours = hourMatch != null ? hourMatch.group(1)! : '0';
  String minutes = minMatch != null ? minMatch.group(1)! : '0';
  String seconds = secMatch != null ? secMatch.group(1)! : '0';

  return '${hours == '0'?"":"$hours h"} ${minutes == '0'?"":"$minutes m"} ${hours == '0'|| minutes == '0'?"$seconds s" :""}';
}


String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  final h = twoDigits(d.inHours);
  final m = twoDigits(d.inMinutes.remainder(60));
  final s = twoDigits(d.inSeconds.remainder(60));

  return "$h:$m:$s";

  // if(h == "00" && m == "00"){
  //    return "$s second";
  // }
  // else if(h == "00"){
  //   return "$m:$s second";
  // }
  // else{
  //    return "$h:$m:$s sec";
  // }
}

Duration parseTime(String time) {
  final parts = time.split(":").map(int.parse).toList();
  return Duration(
    hours: parts[0],
    minutes: parts[1],
    seconds: parts[2],
  );
}

String formatDateTime(String input) {
  final inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  final dateTime = inputFormat.parse(input);

  final outputFormat = DateFormat("EEE/dd/MMM/yyyy hh:mm a");
  return outputFormat.format(dateTime);
}

String formatToTwoDecimalPlaces(String input) {
  double value = double.tryParse(input) ?? 0.0;
  String formatted = NumberFormat("#,##0").format(value);
  return formatted;
}


Duration getDurationFromDistance(double distanceMeters, double speedKmh) {
  if (speedKmh <= 0) return Duration.zero;

  // convert speed to m/s
  final speedMs = speedKmh * 1000 / 3600;

  // time in seconds
  final seconds = distanceMeters / speedMs;

  return Duration(seconds: seconds.round());
}


String convertSecondsToHoursMinutes(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    return '${hours}h ${minutes}m';
  }

String typeVehicle(int typeVehicleId){
  return typeVehicleId == 1?"Rickshaw":typeVehicleId == 2?"Classis Car":typeVehicleId == 3?"Mini Van":typeVehicleId == 4?"SUV":"Alphard VIP";
}

int calculateDuration(String startTime){
  DateTime parsedDate = DateTime.parse(startTime);
  DateTime now = DateTime.now();
  Duration difference = now.difference(parsedDate);
  int seconds = difference.inSeconds;
  return seconds;
}

String convertMaterToKm(double meters) {
  int km = (meters ~/ 1000);      // whole kilometers
  int m = (meters % 1000).round(); 
  return "$km ${"km".tr()}:$m ${"m".tr()}";
}

String convertKmToKmM(double kmValue) {
  int km = kmValue.floor();                 // whole kilometers
  int m = ((kmValue - km) * 1000).round();  // remaining meters
  return "$km ${"km".tr()}:$m ${"m".tr()}";
}



String formatDistanceWithUnits(String input, BuildContext context) {
  final String translate = context.locale.toString();
  final match = RegExp(r'^([0-9.]+)\s*(.*)$').firstMatch(input);
  if (match == null) return input;

  double number = double.tryParse(match.group(1) ?? '') ?? 0.0;
  String unit = match.group(2)?.toLowerCase() ?? '';

  return '${number.toStringAsFixed(2)} ${unit=="km"?translate == "km"?"គ.ម":unit :translate == "km"?"ម":unit}';
}

  // Future<String> getDrivingDistance(
  //     LatLng driver, LatLng destination, String apiKey) async {
  //   final url =
  //       "https://maps.googleapis.com/maps/api/directions/json?origin=${driver.latitude},${driver.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey";

  //   final response = await get(Uri.parse(url));
  //   final data = jsonDecode(response.body);

  //   if (data["status"] == "OK") {
  //     var distance = data["routes"][0]["legs"][0]["distance"]["text"];
  //     var duration = data["routes"][0]["legs"][0]["duration"]["text"];
  //     print("Driving Distance: $distance");
  //     print("Estimated Time: $duration");
  //   } else {
  //     print("Error fetching distance: ${data['status']}");
  //   }
  // }
Future<void> requestPermissionLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled) {
        return;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      }
      return;
    } catch (e) {
      return;
    } finally {
    }
  }