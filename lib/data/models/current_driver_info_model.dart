import 'package:pu_taxi_driver/core/utils/json_field.dart';
import 'package:pu_taxi_driver/core/utils/money.dart';

// Every field is read through `json_field.dart`. This model is what the
// approval gate and the resume-a-trip redirect are fed from, and it used to
// read each value straight into a typed field: one `"1"` where an `int` was
// declared, or one `[]` where an object was, threw inside `fromJson` and the
// whole response was lost — with the gate left on "checking" for good.

class CurrentDriverInfoModel {
  DataDriverInfo? data;
  bool? status;
  String? message;

  CurrentDriverInfoModel({
    this.data,
    this.status,
    this.message,
  });

  factory CurrentDriverInfoModel.fromJson(Map<String, dynamic> json) =>
      CurrentDriverInfoModel(
        data: objectOrNull(json["data"], DataDriverInfo.fromJson),
        status: json["status"] is bool ? json["status"] : null,
        message: stringOrNull(json["message"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
        "status": status,
        "message": message,
      };
}

class DataDriverInfo {
  int? id;
  String? bookingCode;
  String? startLatitude;
  String? startLongitude;
  dynamic endLatitude;
  dynamic endLongitude;
  DateTime? startTime;
  dynamic endTime;
  String? startAddress;
  dynamic endAddress;
  dynamic fare;
  int? status;
  String? statusName;
  Passenger? passenger;
  Driver? driver;
  Payment? payment;
  DateTime? createdAt;
  DateTime? updatedAt;

  DataDriverInfo({
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

  factory DataDriverInfo.fromJson(Map<String, dynamic> json) => DataDriverInfo(
        id: intOrNull(json["id"]),
        bookingCode: stringOrNull(json["booking_code"]),
        startLatitude: stringOrNull(json["start_latitude"]),
        startLongitude: stringOrNull(json["start_longitude"]),
        endLatitude: json["end_latitude"],
        endLongitude: json["end_longitude"],
        startTime: dateOrNull(json["start_time"]),
        endTime: json["end_time"],
        startAddress: stringOrNull(json["start_address"]),
        endAddress: json["end_address"],
        fare: json["fare"],
        status: intOrNull(json["status"]),
        statusName: stringOrNull(json["status_name"]),
        passenger: objectOrNull(json["passenger"], Passenger.fromJson),
        driver: objectOrNull(json["driver"], Driver.fromJson),
        payment: objectOrNull(json["payment"], Payment.fromJson),
        createdAt: dateOrNull(json["created_at"]),
        updatedAt: dateOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "booking_code": bookingCode,
        "start_latitude": startLatitude,
        "start_longitude": startLongitude,
        "end_latitude": endLatitude,
        "end_longitude": endLongitude,
        "start_time": startTime?.toIso8601String(),
        "end_time": endTime,
        "start_address": startAddress,
        "end_address": endAddress,
        "fare": fare,
        "status": status,
        "status_name": statusName,
        "passenger": passenger?.toJson(),
        "driver": driver?.toJson(),
        "payment": payment?.toJson(),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
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
  int? roleId;
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
    this.driverLicenseNumber,
    this.driverLicenseExpired,
    this.driverLicenseImage,
    this.status,
    this.statusDate,
    this.profileImage,
    this.vehicle,
    this.roleId,
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
        roleId: intOrNull(json["role_id"]),
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
        "role_id": roleId,
        "last_location": lastLocation?.toJson(),
      };
}

class Vehicle {
  int? id;
  int? typeVehicleId;
  num? pricrVehicle;
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
    this.pricrVehicle,
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
        // DD-54: price per km, a decimal. The backend sends it on the
        // vehicle's type (`vehicle_type.price: "0.30"`); `vehicle_price` is
        // where the app first expected it and is still read when present.
        pricrVehicle: parseMoney(json["vehicle_price"]) ??
            parseMoney(
              json["vehicle_type"] is Map
                  ? json["vehicle_type"]["price"]
                  : null,
            ),
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
        "vehicle_price": pricrVehicle ?? pricrVehicle,
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
