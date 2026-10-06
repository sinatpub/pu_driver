import 'package:pu_taxi_driver/core/utils/json_field.dart';

class UpdateDriverLocationModel {
  Data? data;
  bool? status;
  String? message;

  UpdateDriverLocationModel({
    this.data,
    this.status,
    this.message,
  });

  factory UpdateDriverLocationModel.fromJson(Map<String, dynamic> json) =>
      UpdateDriverLocationModel(
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
  String? latitude;
  String? longitude;
  DateTime? createdAt;
  DateTime? updatedAt;

  Data({
    this.id,
    this.userId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: intOrNull(json["id"]),
        userId: intOrNull(json["user_id"]),
        latitude: stringOrNull(json["latitude"]),
        longitude: stringOrNull(json["longitude"]),
        createdAt: dateOrNull(json["created_at"]),
        updatedAt: dateOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "latitude": latitude,
        "longitude": longitude,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
