import 'package:dio/dio.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/confirm_booking_model.dart';

/// The 5 driver-side trip-lifecycle calls (D-06). `accept-payment` stays on
/// the old `BookingApi` (`data/datasources/confirm_booking_api.dart`) — it's
/// called from `calculate_fee_screen.dart`, outside the trip lifecycle this
/// feature covers.
class TripDatasource {
  TripDatasource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<ConfirmBookingModel>> confirm(int rideId) {
    return _apiClient.request<ConfirmBookingModel>(
      path: '/taxi-driver/confirm-drive-request',
      method: 'POST',
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: FormData.fromMap({'ride_id': rideId}),
      decode: (response) => ConfirmBookingModel.fromJson(response.data),
    );
  }

  Future<Result<bool>> cancel(int rideId) {
    return _apiClient.request<bool>(
      path: '/taxi-driver/cancel-drive',
      method: 'POST',
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: FormData.fromMap({'ride_id': rideId}),
      decode: (_) => true,
    );
  }

  Future<Result<ConfirmBookingModel>> arrive(int rideId) {
    return _apiClient.request<ConfirmBookingModel>(
      path: '/taxi-driver/drive-arrive',
      method: 'POST',
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: FormData.fromMap({'ride_id': rideId}),
      decode: (response) => ConfirmBookingModel.fromJson(response.data),
    );
  }

  Future<Result<ConfirmBookingModel>> start(int rideId) {
    return _apiClient.request<ConfirmBookingModel>(
      path: '/taxi-driver/start-drive',
      method: 'POST',
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: FormData.fromMap({'ride_id': rideId}),
      decode: (response) => ConfirmBookingModel.fromJson(response.data),
    );
  }

  Future<Result<CompleteDriverModel>> complete({
    required int rideId,
    required double endLatitude,
    required double endLongitude,
    required String endAddress,
    required double distance,
  }) {
    return _apiClient.request<CompleteDriverModel>(
      path: '/taxi-driver/complete-drive',
      method: 'POST',
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: FormData.fromMap({
        'ride_id': rideId,
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
        'end_address': endAddress,
        'distance': distance,
      }),
      decode: (response) => CompleteDriverModel.fromJson(response.data),
    );
  }
}
