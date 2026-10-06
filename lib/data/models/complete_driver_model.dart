// To parse this JSON data, do
//
//     final completeDriver = completeDriverFromJson(jsonString);

import 'dart:convert';
import 'package:pu_taxi_driver/core/utils/json_field.dart';

CompleteDriverModel CompleteDriverModelFromJson(String str) =>
    CompleteDriverModel.fromJson(json.decode(str));

String CompleteDriverModelToJson(CompleteDriverModel data) =>
    json.encode(data.toJson());

class CompleteDriverModel {
  Data? data;
  bool? status;
  String? message;

  CompleteDriverModel({
    this.data,
    this.status,
    this.message,
  });

  factory CompleteDriverModel.fromJson(Map<String, dynamic> json) =>
      CompleteDriverModel(
        data: objectOrNull(json["data"], Data.fromJson),
        status: json["status"] is bool ? json["status"] : null,
        message: stringOrNull(json["message"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
        "status": status,
        "message": message,
      };
}

class Data {
  int? id;
  String? bookingCode;
  String? startLatitude;
  String? startLongitude;
  String? endLatitude;
  String? endLongitude;
  String? startTime;
  String? endTime;
  dynamic startAddress;
  String? endAddress;
  dynamic fare;
  int? status;
  String? statusName;
  Passenger? passenger;
  Driver? driver;
  Payment? payment;
  String? createdAt;
  String? updatedAt;

  Data({
    this.id,
    this.bookingCode,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.startTime,
    this.endTime,
    this.startAddress,
    this.endAddress,
    this.fare,
    this.status,
    this.statusName,
    this.passenger,
    this.driver,
    this.payment,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: intOrNull(json["id"]),
        bookingCode: stringOrNull(json["booking_code"]),
        startLatitude: stringOrNull(json["start_latitude"]),
        startLongitude: stringOrNull(json["start_longitude"]),
        endLatitude: stringOrNull(json["end_latitude"]),
        endLongitude: stringOrNull(json["end_longitude"]),
        startTime: stringOrNull(json["start_time"]),
        endTime: stringOrNull(json["end_time"]),
        startAddress: json["start_address"],
        endAddress: stringOrNull(json["end_address"]),
        fare: json["fare"],
        status: intOrNull(json["status"]),
        statusName: stringOrNull(json["status_name"]),
        passenger: objectOrNull(json["passenger"], Passenger.fromJson),
        driver: objectOrNull(json["driver"], Driver.fromJson),
        payment: objectOrNull(json["payment"], Payment.fromJson),
        createdAt: stringOrNull(json["created_at"]),
        updatedAt: stringOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "booking_code": bookingCode,
        "start_latitude": startLatitude,
        "start_longitude": startLongitude,
        "end_latitude": endLatitude,
        "end_longitude": endLongitude,
        "start_time": startTime,
        "end_time": endTime,
        "start_address": startAddress,
        "end_address": endAddress,
        "fare": fare,
        "status": status,
        "status_name": statusName,
        "passenger": passenger?.toJson(),
        "driver": driver?.toJson(),
        "payment": payment?.toJson(),
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}

class Driver {
  int? id;
  String? name;
  String? lastName;
  String? firstName;
  String? email;
  int? gender;
  String? dob;
  String? countryCode;
  String? phone;
  int? cardType;
  String? cardNumber;
  String? cardImage;
  String? driverLicenseNumber;
  String? driverLicenseExpired;
  String? driverLicenseImage;
  int? status;
  String? statusDate;
  String? profileImage;
  Vehicle? vehicle;
  LastLocation? lastLocation;

  Driver({
    this.id,
    this.name,
    this.lastName,
    this.firstName,
    this.email,
    this.gender,
    this.dob,
    this.countryCode,
    this.phone,
    this.cardType,
    this.cardNumber,
    this.cardImage,
    this.driverLicenseNumber,
    this.driverLicenseExpired,
    this.driverLicenseImage,
    this.status,
    this.statusDate,
    this.profileImage,
    this.vehicle,
    this.lastLocation,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: intOrNull(json["id"]),
        name: stringOrNull(json["name"]),
        lastName: stringOrNull(json["last_name"]),
        firstName: stringOrNull(json["first_name"]),
        email: stringOrNull(json["email"]),
        gender: intOrNull(json["gender"]),
        dob: stringOrNull(json["dob"]),
        countryCode: stringOrNull(json["country_code"]),
        phone: stringOrNull(json["phone"]),
        cardType: intOrNull(json["card_type"]),
        cardNumber: stringOrNull(json["card_number"]),
        cardImage: stringOrNull(json["card_image"]),
        driverLicenseNumber: stringOrNull(json["driver_license_number"]),
        driverLicenseExpired: stringOrNull(json["driver_license_expired"]),
        driverLicenseImage: stringOrNull(json["driver_license_image"]),
        status: intOrNull(json["status"]),
        statusDate: stringOrNull(json["status_date"]),
        profileImage: stringOrNull(json["profile_image"]),
        vehicle: objectOrNull(json["vehicle"], Vehicle.fromJson),
        lastLocation:
            objectOrNull(json["last_location"], LastLocation.fromJson),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "last_name": lastName,
        "first_name": firstName,
        "email": email,
        "gender": gender,
        "dob": dob,
        "country_code": countryCode,
        "phone": phone,
        "card_type": cardType,
        "card_number": cardNumber,
        "card_image": cardImage,
        "driver_license_number": driverLicenseNumber,
        "driver_license_expired": driverLicenseExpired,
        "driver_license_image": driverLicenseImage,
        "status": status,
        "status_date": statusDate,
        "profile_image": profileImage,
        "vehicle": vehicle?.toJson(),
        "last_location": lastLocation?.toJson(),
      };
}

class LastLocation {
  String? latitude;
  String? longitude;

  LastLocation({
    this.latitude,
    this.longitude,
  });

  factory LastLocation.fromJson(Map<String, dynamic> json) => LastLocation(
        latitude: stringOrNull(json["latitude"]),
        longitude: stringOrNull(json["longitude"]),
      );

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
      };
}

class Vehicle {
  int? id;
  int? typeVehicleId;
  String? model;
  String? manufacturer;
  int? yearOfManufacture;
  String? color;
  String? plateNumber;
  String? enginePower;
  int? maxPassenger;
  int? status;
  List<VehicleImage>? vehicleImage;

  Vehicle({
    this.id,
    this.typeVehicleId,
    this.model,
    this.manufacturer,
    this.yearOfManufacture,
    this.color,
    this.plateNumber,
    this.enginePower,
    this.maxPassenger,
    this.status,
    this.vehicleImage,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: intOrNull(json["id"]),
        typeVehicleId: intOrNull(json["type_vehicle_id"]),
        model: stringOrNull(json["model"]),
        manufacturer: stringOrNull(json["manufacturer"]),
        yearOfManufacture: intOrNull(json["year_of_manufacture"]),
        color: stringOrNull(json["color"]),
        plateNumber: stringOrNull(json["plate_number"]),
        enginePower: stringOrNull(json["engine_power"]),
        maxPassenger: intOrNull(json["max_passenger"]),
        status: intOrNull(json["status"]),
        vehicleImage: objectList(json["vehicle_image"], VehicleImage.fromJson),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type_vehicle_id": typeVehicleId,
        "model": model,
        "manufacturer": manufacturer,
        "year_of_manufacture": yearOfManufacture,
        "color": color,
        "plate_number": plateNumber,
        "engine_power": enginePower,
        "max_passenger": maxPassenger,
        "status": status,
        "vehicle_image":
            List<dynamic>.from(vehicleImage!.map((x) => x.toJson())),
      };
}

class VehicleImage {
  int? id;
  String? fileOriginalName;
  String? fileSize;
  String? fileType;
  String? fileUrl;
  int? objectId;
  String? objectType;
  dynamic createdBy;

  VehicleImage({
    this.id,
    this.fileOriginalName,
    this.fileSize,
    this.fileType,
    this.fileUrl,
    this.objectId,
    this.objectType,
    this.createdBy,
  });

  factory VehicleImage.fromJson(Map<String, dynamic> json) => VehicleImage(
        id: intOrNull(json["id"]),
        fileOriginalName: stringOrNull(json["file_original_name"]),
        fileSize: stringOrNull(json["file_size"]),
        fileType: stringOrNull(json["file_type"]),
        fileUrl: stringOrNull(json["file_url"]),
        objectId: intOrNull(json["object_id"]),
        objectType: stringOrNull(json["object_type"]),
        createdBy: json["created_by"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "file_original_name": fileOriginalName,
        "file_size": fileSize,
        "file_type": fileType,
        "file_url": fileUrl,
        "object_id": objectId,
        "object_type": objectType,
        "created_by": createdBy,
      };
}

class Passenger {
  int? id;
  String? name;
  String? lastName;
  String? firstName;
  String? email;
  int? gender;
  String? dob;
  String? countryCode;
  String? phone;
  dynamic cardType;
  dynamic cardNumber;
  dynamic cardImage;
  int? status;
  String? statusDate;
  int? roleId;
  dynamic profileImage;
  LastLocation? lastLocation;

  Passenger({
    this.id,
    this.name,
    this.lastName,
    this.firstName,
    this.email,
    this.gender,
    this.dob,
    this.countryCode,
    this.phone,
    this.cardType,
    this.cardNumber,
    this.cardImage,
    this.status,
    this.statusDate,
    this.roleId,
    this.profileImage,
    this.lastLocation,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        id: intOrNull(json["id"]),
        name: stringOrNull(json["name"]),
        lastName: stringOrNull(json["last_name"]),
        firstName: stringOrNull(json["first_name"]),
        email: stringOrNull(json["email"]),
        gender: intOrNull(json["gender"]),
        dob: stringOrNull(json["dob"]),
        countryCode: stringOrNull(json["country_code"]),
        phone: stringOrNull(json["phone"]),
        cardType: json["card_type"],
        cardNumber: json["card_number"],
        cardImage: json["card_image"],
        status: intOrNull(json["status"]),
        statusDate: stringOrNull(json["status_date"]),
        roleId: intOrNull(json["role_id"]),
        profileImage: json["profile_image"],
        lastLocation:
            objectOrNull(json["last_location"], LastLocation.fromJson),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "last_name": lastName,
        "first_name": firstName,
        "email": email,
        "gender": gender,
        "dob": dob,
        "country_code": countryCode,
        "phone": phone,
        "card_type": cardType,
        "card_number": cardNumber,
        "card_image": cardImage,
        "status": status,
        "status_date": statusDate,
        "role_id": roleId,
        "profile_image": profileImage,
        "last_location": lastLocation?.toJson(),
      };
}

class Payment {
  int? id;
  int? invoiceId;
  int? rideId;
  String? distance;
  String? duration;
  String? amount;
  String? paymentMethod;

  /// DD-51: the passenger's ride credit used on this trip (proposed
  /// field, mock only). The driver collects the fare less this in cash.
  dynamic rideCredit;
  int? status;
  String? statusName;
  String? createdAt;
  String? updatedAt;

  Payment({
    this.id,
    this.invoiceId,
    this.rideId,
    this.distance,
    this.duration,
    this.amount,
    this.paymentMethod,
    this.rideCredit,
    this.status,
    this.statusName,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: intOrNull(json["id"]),
        invoiceId: intOrNull(json["invoice_id"]),
        rideId: intOrNull(json["ride_id"]),
        distance: stringOrNull(json["distance"]),
        duration: stringOrNull(json["duration"]),
        amount: stringOrNull(json["amount"]),
        paymentMethod: stringOrNull(json["payment_method"]),
        rideCredit: json["ride_credit"],
        status: intOrNull(json["status"]),
        statusName: stringOrNull(json["status_name"]),
        createdAt: stringOrNull(json["created_at"]),
        updatedAt: stringOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "invoice_id": invoiceId,
        "ride_id": rideId,
        "distance": distance,
        "duration": duration,
        "amount": amount,
        "payment_method": paymentMethod,
        "ride_credit": rideCredit,
        "status": status,
        "status_name": statusName,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
