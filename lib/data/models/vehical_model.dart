import 'package:pu_taxi_driver/core/utils/json_field.dart';

class VehicalTypeEntities {
  List<SingleVehical> data;
  List<Color> color;
  String message;
  bool status;

  VehicalTypeEntities({
    required this.data,
    required this.message,
    required this.status,
    required this.color,
  });

  factory VehicalTypeEntities.fromJson(Map<String, dynamic> json) =>
      VehicalTypeEntities(
        data: objectList(json["data"], SingleVehical.fromJson),
        color: objectList(json["color"], Color.fromJson),
        message: stringOrEmpty(json["message"]),
        status: boolOrDefault(json["status"]),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "color": List<dynamic>.from(data.map((x) => x.toJson())),
        "message": message,
        "status": status,
      };
}

class SingleVehical {
  int id;
  String name;

  /// Price per km and the fare floor, in the fare currency. Decimals on the
  /// real backend (`"0.30"`, `"0.50"`), so not `int` (DD-54). Money: a value
  /// that is missing or not a number refuses to parse rather than becoming 0.
  num price;
  num minimumFare;
  String? image;
  DateTime? createdAt;
  DateTime? updatedAt;

  SingleVehical({
    required this.id,
    required this.name,
    required this.price,
    required this.minimumFare,
    required this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory SingleVehical.fromJson(Map<String, dynamic> json) => SingleVehical(
        id: intOrDefault(json["id"]),
        name: stringOrEmpty(json["name"]),
        price: requireMoney(
          json["price"],
          model: 'SingleVehical',
          field: 'price',
        ),
        minimumFare: requireMoney(
          json["minimum_fare"],
          model: 'SingleVehical',
          field: 'minimum_fare',
        ),
        image: stringOrNull(json["image"]),
        createdAt: dateOrNull(json["created_at"]),
        updatedAt: dateOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "price": price,
        "image": image,
        "minimum_fare": minimumFare,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

class Color {
  int id;
  String name;
  String? colorCode;
  String? createdAt;
  String? updatedAt;

  Color({
    required this.id,
    required this.name,
    required this.colorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Color.fromJson(Map<String, dynamic> json) => Color(
        id: intOrDefault(json["id"]),
        name: stringOrEmpty(json["name"]),
        colorCode: stringOrNull(json["color_code"]),
        createdAt: stringOrNull(json["created_at"]),
        updatedAt: stringOrNull(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "color_code": colorCode,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
