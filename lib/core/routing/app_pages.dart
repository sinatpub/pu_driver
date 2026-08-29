import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/routing/route_arguments.dart';
import 'package:tara_driver_application/presentation/screens/booking/booking/booking_screen.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee_screen.dart';
import 'package:tara_driver_application/presentation/screens/drawer_screen.dart';
import 'package:tara_driver_application/presentation/screens/login_page.dart';
import 'package:tara_driver_application/presentation/screens/map_history_detail_screen.dart';
import 'package:tara_driver_application/presentation/screens/notification/view/notification_detail_screen.dart';
import 'package:tara_driver_application/presentation/screens/notification/view/notification_screen.dart';
import 'package:tara_driver_application/presentation/screens/otp_page.dart';
import 'package:tara_driver_application/presentation/screens/register_page.dart';
import 'package:tara_driver_application/presentation/screens/splash_screen.dart';

/// GetPage table for AppRoutes (F-06, docs/12). `DrawerScreen` uses
/// [Transition.noTransition] because every call site that lands there does
/// so after clearing the stack (login, logout, cancel, language switch) and
/// the app never animated that transition.
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(
      name: AppRoutes.otp,
      page: () {
        final args = Get.arguments as OtpPageArgs?;
        return OtpPage(
          phoneNumberModel: args?.phoneNumberModel,
          phoneNumber: args?.phoneNumber,
        );
      },
    ),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => DrawerScreen(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => NotificationPage(),
    ),
    GetPage(
      name: AppRoutes.notificationDetail,
      page: () {
        final args = Get.arguments as NotificationDetailArgs;
        return NotificationDetailPage(
          notificationId: args.notificationId,
          appOpened: args.appOpened,
        );
      },
    ),
    GetPage(
      name: AppRoutes.mapHistoryDetail,
      page: () {
        final args = Get.arguments as MapHistoryDetailArgs;
        return MapHistoryDetailScreen(
          typeVehicleId: args.typeVehicleId,
          cost: args.cost,
          distand: args.distand,
          duration: args.duration,
          latStart: args.latStart,
          lngStart: args.lngStart,
          latEnd: args.latEnd,
          lngEnd: args.lngEnd,
        );
      },
    ),
    GetPage(
      name: AppRoutes.calculateFee,
      page: () {
        final args = Get.arguments as CalculateFeeScreenArgs;
        return CalculateFeeScreen(
          routFrom: args.routFrom,
          dataDriverInfo: args.dataDriverInfo,
          dataComplete: args.dataComplete,
          startAddress: args.startAddress,
          endAddress: args.endAddress,
        );
      },
    ),
    GetPage(
      name: AppRoutes.booking,
      page: () {
        final args = Get.arguments as BookingScreenArgs;
        return BookingScreen(
          startTime: args.startTime,
          lngStart: args.lngStart,
          latStart: args.latStart,
          typeVehicleId: args.typeVehicleId,
          pricrVehicle: args.pricrVehicle,
          bookingId: args.bookingId,
          bookingCode: args.bookingCode,
          latPassenger: args.latPassenger,
          lngPassenger: args.lngPassenger,
          processStepBook: args.processStepBook,
          desLatPassenger: args.desLatPassenger,
          desLngPassenger: args.desLngPassenger,
          latDriver: args.latDriver,
          lngDriver: args.lngDriver,
          timeOut: args.timeOut,
          passengerId: args.passengerId,
          namePassanger: args.namePassanger,
          phonePassanger: args.phonePassanger,
          imagePassanger: args.imagePassanger,
          refreshApp: args.refreshApp,
        );
      },
    ),
  ];
}
