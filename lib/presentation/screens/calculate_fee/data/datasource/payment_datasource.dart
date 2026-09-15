import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';

class PaymentDatasource {
  PaymentDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<bool>> acceptPayment(int rideId) {
    return _apiClient.request<bool>(
      path: '/taxi-driver/accept-payment',
      method: 'POST',
      body: {'ride_id': rideId},
      decode: (_) => true,
    );
  }
}
