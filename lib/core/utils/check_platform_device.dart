import 'dart:io';

checkPlatformDevice() {
  if (Platform.isAndroid) {
    return "Android";
  } else if (Platform.isIOS) {
    return "ios";
  } else if (Platform.isWindows) {
    return "Window";
  } else if (Platform.isMacOS) {
    return "MacOS";
  } else {
    return "None device";
  }
}
