import 'package:geocoding/geocoding.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/mock/mock_fixtures.dart';
import 'package:tara_driver_application/mock/mock_mode.dart';

Future<String> getAddressFromLatLng(double latitude, double longitude) async {
  // QA mock mode: the simulated trip's landmarks have fixed names, so the
  // same address shows on every emulator, with or without Play Services.
  if (MockMode.isActive) {
    final name = MockPlaces.nameNear(LatLng(latitude, longitude));
    if (name != null) return name;
  }
  try {
    await setLocaleIdentifier("km");
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      //tlog("PlaceMarker: $placemarks");
      String address = '';
      address += place.name != null ? "${place.name}, " : '';
      address += place.street != null ? "${place.street}, " : '';
      address += place.subLocality != null ? "${place.subLocality}, " : '';
      address += place.locality != null ? "${place.locality}, " : '';
      address += place.postalCode != null ? "${place.postalCode}, " : '';
      address += place.country != null ? "${place.country}" : '';
      return address.trim().replaceAll(RegExp(r',\s*$'), '');
    } else {
      return "ADDRESS_NOT_FOUND".tr();
    }
  } catch (e) {
    print("Error: $e");
    return "ADDRESS_NOT_FOUND".tr();
  }
}
