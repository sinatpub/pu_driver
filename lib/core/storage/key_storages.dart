class StorageKeys {
  static const String phoneNumber = 'phone_number';
  static const String driverService = 'driver_service';
  static const String registerData = 'register_data';
  static const String fcmTokenData = "fcm_token_data";

  /// DD-37: when the driver arrived at the pickup, as
  /// `bookingId|epochMs`. One trip runs at a time, so one key.
  static const String arrivedAt = 'arrived_at';

  /// The distance driven on the running trip and where it was last counted,
  /// as `bookingId|meters|latitude|longitude`. One trip runs at a time, so
  /// one key.
  static const String tripDistance = 'trip_distance';
}
