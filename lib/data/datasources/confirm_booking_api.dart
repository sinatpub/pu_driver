import 'package:tara_driver_application/core/api_service/base_api_service.dart';
import 'package:dio/dio.dart';

/// confirm-drive-request, drive-arrive, start-drive, complete-drive, and
/// cancel-drive moved to features/trip/data/datasource/trip_datasource.dart
/// (D-06). completePayment (accept-payment) is called from
/// calculate_fee_screen.dart, outside the trip lifecycle — the rest of this
/// class existing only for that one method wasn't worth a full port.
class BookingApi {
  Future<bool> completePayment({
    required int rideId,
  }) async {
    FormData formData = FormData.fromMap({
      "ride_id": rideId
    });
    return BaseApiService().onRequest<bool>(
      path: "/taxi-driver/accept-payment",
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      bodyParse: formData,
      onSuccess: (result) {
        print("fasldfk$result");
        return true;
      },
    );
  }
}
