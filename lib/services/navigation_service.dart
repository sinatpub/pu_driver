import 'package:flutter/material.dart';

/// Holds the root navigator key GetMaterialApp is built with (`app/root_main.dart`),
/// so non-widget code (services, socket listeners) can reach it. Actual
/// navigation goes through the named routes in `routes/` (F-06) —
/// this class no longer wraps push/pop itself.
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigationService? _instance;

  factory NavigationService() => _instance ??= NavigationService._();

  NavigationService._();
}
