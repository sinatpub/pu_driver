import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';

/// Loads `assets/translations/<locale>.json` straight from disk.
///
/// The default `RootBundleAssetLoader` reads through the asset bundle with
/// real async I/O, which never completes inside `testWidgets`' fake-async
/// zone — every `.tr()` then falls back to its raw key and any test asserting
/// on English copy fails. Reading the file synchronously lets the load settle
/// on the first `pumpAndSettle`.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final File file = File('$path/${locale.languageCode}.json');
    return Future<Map<String, dynamic>?>.value(
      json.decode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }
}

/// A themed `MaterialApp` inside `EasyLocalization`, with the app's real
/// English (or Khmer) copy, hosting [child] in a scrollable `Scaffold` body.
/// Call `pumpAndSettle` after pumping it.
Widget localizedHost(Widget child, {Locale locale = const Locale('en')}) =>
    localizedHostPage(
      Scaffold(body: SingleChildScrollView(child: child)),
      locale: locale,
    );

/// Like [localizedHost], but for a whole page that brings its own `Scaffold`.
Widget localizedHostPage(Widget page, {Locale locale = const Locale('en')}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('en'), Locale('km')],
    path: 'assets/translations',
    assetLoader: const _FileAssetLoader(),
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    saveLocale: false,
    child: Builder(
      builder: (BuildContext context) => MaterialApp(
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        theme: AppTheme.light(khmer: locale.languageCode == 'km'),
        home: page,
      ),
    ),
  );
}
