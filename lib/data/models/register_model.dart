import 'package:pu_taxi_driver/core/utils/json_field.dart';

class RegisterModel {
  Data? data;
  bool? status;
  String? message;

  RegisterModel({
    this.data,
    this.status,
    this.message,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) => RegisterModel(
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
  Driver? driver;
  String? token;

  Data({
    this.driver,
    this.token,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        driver: objectOrNull(json["driver"], Driver.fromJson),
        token: stringOrNull(json["token"]),
      );

  Map<String, dynamic> toJson() => {
        "driver": driver?.toJson(),
        "token": token,
      };
}

class Driver {
  int? id;
  String? name;
  dynamic lastName;
  dynamic firstName;
  dynamic email;
  dynamic gender;
  String? dob;
  String? countryCode;
  String? phone;
  dynamic cardType;
  dynamic cardNumber;
  String? cardImage;
  dynamic driverLicenseNumber;
  String? driverLicenseExpired;
  String? driverLicenseImage;
  int? status;
  String? statusDate;
  String? profileImage;
  Vehicle? vehicle;

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
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: intOrNull(json["id"]),
        name: stringOrNull(json["name"]),
        lastName: json["last_name"],
        firstName: json["first_name"],
        email: json["email"],
        gender: json["gender"],
        dob: stringOrNull(json["dob"]),
        countryCode: stringOrNull(json["country_code"]),
        phone: stringOrNull(json["phone"]),
        cardType: json["card_type"],
        cardNumber: json["card_number"],
        cardImage: stringOrNull(json["card_image"]),
        driverLicenseNumber: json["driver_license_number"],
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
  dynamic model;
  dynamic manufacturer;
  dynamic yearOfManufacture;
  String? color;
  String? plateNumber;
  dynamic enginePower;
  dynamic maxPassenger;
  int? status;
  List<dynamic>? vehicleImage;

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
        model: json["model"],
        manufacturer: json["manufacturer"],
        yearOfManufacture: json["year_of_manufacture"],
        color: stringOrNull(json["color"]),
        plateNumber: stringOrNull(json["plate_number"]),
        enginePower: json["engine_power"],
        maxPassenger: json["max_passenger"],
        status: intOrNull(json["status"]),
        vehicleImage: json["vehicle_image"] is List
            ? List<dynamic>.from(json["vehicle_image"] as List)
            : <dynamic>[],
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
            : List<dynamic>.from(vehicleImage!.map((x) => x)),
      };
}
