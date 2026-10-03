import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';
import 'package:pu_taxi_driver/presentation/screens/login/data/models/phone_model.dart';

class AuthDatasource {
  AuthDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<PhoneNumberModel>> loginPhone(String phone) {
    return _apiClient.request<PhoneNumberModel>(
      path: '/taxi-driver/login-phone',
      method: 'POST',
      requiresToken: false,
      body: {'phone': phone},
      decode: (response) => PhoneNumberModel.fromJson(response.data),
    );
  }

  Future<Result<RegisterModel>> verifyOtp({
    required String phone,
    required String otpCode,
  }) {
    return _apiClient.request<RegisterModel>(
      path: '/taxi-driver/verify-phone-otp',
      method: 'POST',
      requiresToken: false,
      body: {'phone': phone, 'otp_code': otpCode},
      decode: (response) => RegisterModel.fromJson(response.data),
    );
  }

  Future<Result<RegisterModel>> register({
    required String fullName,
    required String phoneNumber,
    required String vehicalId,
    required String vehicalColor,
    required String deviceToken,
    required String platform,
    required String plateNumber,
    required File cardImage,
    required File profileImage,
    required File vehicleImage,
    required File driverLicenseImage,
    String? inviteCode,
  }) async {
    final formData = FormData.fromMap({
      // DD-45: sent only when the driver signed up with an invite code.
      if (inviteCode != null && inviteCode.isNotEmpty)
        'invite_code': inviteCode,
      'fullname': fullName,
      'phone': phoneNumber,
      'type_vehicle_id': vehicalId,
      'color': vehicalColor,
      'plate_number': plateNumber,
      'device_token': deviceToken,
      'platform': platform,
      'card_image': await MultipartFile.fromFile(cardImage.path),
      'profile_image': await MultipartFile.fromFile(profileImage.path),
      'vehicle_image': await MultipartFile.fromFile(vehicleImage.path),
      'driver_license_image':
          await MultipartFile.fromFile(driverLicenseImage.path),
    });

    return _apiClient.request<RegisterModel>(
      path: '/taxi-driver/register',
      method: 'POST',
      headers: const {'Content-Type': 'multipart/form-data'},
      body: formData,
      decode: (response) => RegisterModel.fromJson(response.data),
    );
  }
}
