import 'package:tara_driver_application/core/utils/json_list.dart';

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
        data: parseJsonList<SingleVehical>(
            json["data"], (x) => SingleVehical.fromJson(x)),
        color: parseJsonList<Color>(
            json["color"], (x) => Color.fromJson(x)),
        message: json["message"],
        status: json["status"],
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
  int price;
  int minimumFare;
  String? image;
  DateTime createdAt;
  DateTime updatedAt;

  SingleVehical({
    required this.id,
    required this.name,
    required this.price,
    required this.minimumFare,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SingleVehical.fromJson(Map<String, dynamic> json) => SingleVehical(
        id: json["id"],
        name: json["name"],
        price: json["price"],
        minimumFare: json["minimum_fare"],
        image: json["image"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "price": price,
        "image": image,
        "minimum_fare": minimumFare,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
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
        id: json["id"],
        name: json["name"],
        colorCode: json["color_code"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "color_code": colorCode,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
