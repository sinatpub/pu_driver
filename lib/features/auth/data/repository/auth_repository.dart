import 'dart:io';

import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/features/auth/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/features/auth/data/models/phone_model.dart';

class AuthRepository {
  AuthRepository(this._datasource);

  final AuthDatasource _datasource;

  Future<Result<PhoneNumberModel>> loginPhone(String phone) => _datasource.loginPhone(phone);

  Future<Result<RegisterModel>> verifyOtp({required String phone, required String otpCode}) =>
      _datasource.verifyOtp(phone: phone, otpCode: otpCode);

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
  }) =>
      _datasource.register(
        fullName: fullName,
        phoneNumber: phoneNumber,
        vehicalId: vehicalId,
        vehicalColor: vehicalColor,
        deviceToken: deviceToken,
        platform: platform,
        plateNumber: plateNumber,
        cardImage: cardImage,
        profileImage: profileImage,
        vehicleImage: vehicleImage,
        driverLicenseImage: driverLicenseImage,
      );
}
