/// Named route constants (F-06, docs/12). One name per screen that is
/// reached via full-screen navigation — screens only ever shown as an
/// inline tab inside `DrawerScreen` (history, payment, contact, terms,
/// profile) don't need a route.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/otp';
  static const register = '/register';
  static const home = '/home';
  static const notification = '/notification';
  static const notificationDetail = '/notification-detail';
  static const mapHistoryDetail = '/map-history-detail';
  static const calculateFee = '/calculate-fee';
  static const booking = '/booking';
}
