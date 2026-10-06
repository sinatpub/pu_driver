import 'package:pu_taxi_driver/core/utils/json_field.dart';

class SetDriverStatusModel {
  Data? data;
  bool? status;
  String? message;

  SetDriverStatusModel({
    this.data,
    this.status,
    this.message,
  });

  factory SetDriverStatusModel.fromJson(Map<String, dynamic> json) =>
      SetDriverStatusModel(
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
  int? userId;
  int? vehicleId;
  String? licenseNumber;
  int? rating;
  int? isAvailable;
  DateTime? createdAt;
  DateTime? updatedAt;

  Data({
    this.id,
    this.userId,
    this.vehicleId,
    this.licenseNumber,
    this.rating,
    this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: intOrNull(json["id"]),
        userId: intOrNull(json["user_id"]),
        vehicleId: intOrNull(json["vehicle_id"]),
        licenseNumber: stringOrNull(json["license_number"]),
        rating: intOrNull(json["rating"]),
        // The one field the app acts on: 1 is online. A flag sent as
        // `true` / `false` reads the same way.
        isAvailable: json["is_available"] is bool
            ? (json["is_available"] == true ? 1 : 0)
            : intOrNull(json["is_available"]),
        createdAt: dateOrNull(json["created_at"]),
        updatedAt: dateOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "vehicle_id": vehicleId,
        "license_number": licenseNumber,
        "rating": rating,
        "is_available": isAvailable,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
