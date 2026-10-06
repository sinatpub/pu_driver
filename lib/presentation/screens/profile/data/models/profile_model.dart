import 'package:pu_taxi_driver/core/utils/json_field.dart';

class ProfileModel {
  Data? data;
  bool? status;
  String? message;

  ProfileModel({
    this.data,
    this.status,
    this.message,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
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
  String? driverId;
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

  Data({
    this.id,
    this.driverId,
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
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: intOrNull(json["id"]),
        driverId: json['driver_id'],
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
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "driver_id": driverId,
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
        "vehicle_image": vehicleImage == null
            ? []
            : List<dynamic>.from(vehicleImage!.map((x) => x.toJson())),
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
