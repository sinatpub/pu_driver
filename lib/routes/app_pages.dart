import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/presentation/screens/booking/binding.dart';
import 'package:tara_driver_application/presentation/screens/booking/view.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/binding.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/view.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/binding.dart';
import 'package:tara_driver_application/presentation/screens/drawer/binding.dart';
import 'package:tara_driver_application/presentation/screens/drawer/view.dart';
import 'package:tara_driver_application/presentation/screens/history/binding.dart';
import 'package:tara_driver_application/presentation/screens/home/binding.dart';
import 'package:tara_driver_application/presentation/screens/term_condition/binding.dart';
import 'package:tara_driver_application/presentation/screens/wallet/binding.dart';
import 'package:tara_driver_application/presentation/screens/login/binding.dart';
import 'package:tara_driver_application/presentation/screens/login/view.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/binding.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/view.dart';
import 'package:tara_driver_application/presentation/screens/announcement/binding.dart';
import 'package:tara_driver_application/presentation/screens/announcement/view.dart';
import 'package:tara_driver_application/presentation/screens/announcement_detail/binding.dart';
import 'package:tara_driver_application/presentation/screens/announcement_detail/view.dart';
import 'package:tara_driver_application/presentation/screens/otp/binding.dart';
import 'package:tara_driver_application/presentation/screens/profile/binding.dart';
import 'package:tara_driver_application/presentation/screens/otp/view.dart';
import 'package:tara_driver_application/presentation/screens/register/binding.dart';
import 'package:tara_driver_application/presentation/screens/register/view.dart';
import 'package:tara_driver_application/presentation/screens/splash_screen/binding.dart';
import 'package:tara_driver_application/presentation/screens/splash_screen/view.dart';

/// GetPage table for AppRoutes (F-06, docs/12). `DrawerScreen` uses
/// [Transition.noTransition] because every call site that lands there does
/// so after clearing the stack (login, logout, cancel, language switch) and
/// the app never animated that transition.
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpPage(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    // `DrawerScreen` is a shell hosting several tab bodies, so its route
    // carries their bindings — the same shape as the passenger app's
    // BOTTOMNAV page (`14` §3.5). Tabs are registered here as each one is
    // migrated to the screen-unit convention.
    GetPage(
      name: AppRoutes.home,
      page: () => DrawerScreen(),
      transition: Transition.noTransition,
      bindings: [
        DrawerBinding(),
        ProfileBinding(),
        HomeBinding(),
        AnnouncementBinding(),
        ContactUsBinding(),
        HistoryBinding(),
        TermConditionBinding(),
        WalletBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => const AnnouncementPage(),
      binding: AnnouncementBinding(),
    ),
    // Typed args (`14` §4.2) are unpacked in the binding now, not the page
    // builder, so the view carries no route plumbing.
    GetPage(
      name: AppRoutes.notificationDetail,
      page: () => const AnnouncementDetailPage(),
      binding: AnnouncementDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.mapHistoryDetail,
      page: () => const HistoryDetailPage(),
      binding: HistoryDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.calculateFee,
      page: () => const CalculateFeeScreen(),
      binding: CalculateFeeBinding(),
    ),
    GetPage(
      name: AppRoutes.booking,
      page: () => const BookingScreen(),
      binding: BookingBinding(),
    ),
  ];
}
