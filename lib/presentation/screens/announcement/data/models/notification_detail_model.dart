// To parse this JSON data, do
//
//     final detailNotificationModel = detailNotificationModelFromJson(jsonString);

import 'dart:convert';
import 'package:pu_taxi_driver/core/utils/json_list.dart';
import 'package:pu_taxi_driver/core/utils/json_field.dart';

DetailNotificationModel detailNotificationModelFromJson(String str) =>
    DetailNotificationModel.fromJson(json.decode(str));

String detailNotificationModelToJson(DetailNotificationModel data) =>
    json.encode(data.toJson());

class DetailNotificationModel {
  bool? status;
  DataDetailNotification? data;

  DetailNotificationModel({
    this.status,
    this.data,
  });

  factory DetailNotificationModel.fromJson(Map<String, dynamic> json) =>
      DetailNotificationModel(
        status: json["status"] is bool ? json["status"] : null,
        data: objectOrNull(json["data"], DataDetailNotification.fromJson),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data!.toJson(),
      };
}

class DataDetailNotification {
  int? id;
  String? title;
  String? description;
  String? releaseDate;
  String? expiredDate;
  int? target;
  int? status;
  int? createdBy;
  String? createdAt;
  String? updatedAt;
  List<FileElement>? files;

  DataDetailNotification({
    this.id,
    this.title,
    this.description,
    this.releaseDate,
    this.expiredDate,
    this.target,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.files,
  });

  factory DataDetailNotification.fromJson(Map<String, dynamic> json) =>
      DataDetailNotification(
        id: intOrNull(json["id"]),
        title: stringOrNull(json["title"]),
        description: stringOrNull(json["description"]),
        releaseDate: stringOrNull(json["release_date"]),
        expiredDate: stringOrNull(json["expired_date"]),
        target: intOrNull(json["target"]),
        status: intOrNull(json["status"]),
        createdBy: intOrNull(json["created_by"]),
        createdAt: stringOrNull(json["created_at"]),
        updatedAt: stringOrNull(json["updated_at"]),
        files: parseJsonList<FileElement>(
            json["files"], (x) => FileElement.fromJson(x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "release_date": releaseDate,
        "expired_date": expiredDate,
        "target": target,
        "status": status,
        "created_by": createdBy,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "files": List<dynamic>.from(files!.map((x) => x)),
      };
}

class FileElement {
  int? id;
  String? fileOriginalName;
  String? fileSize;
  String? fileType;
  String? fileUrl;
  int? objectId;
  String? objectType;
  int? createdBy;

  FileElement({
    this.id,
    this.fileOriginalName,
    this.fileSize,
    this.fileType,
    this.fileUrl,
    this.objectId,
    this.objectType,
    this.createdBy,
  });

  factory FileElement.fromJson(Map<String, dynamic> json) => FileElement(
        id: intOrNull(json["id"]),
        fileOriginalName: stringOrNull(json["file_original_name"]),
        fileSize: stringOrNull(json["file_size"]),
        fileType: stringOrNull(json["file_type"]),
        fileUrl: stringOrNull(json["file_url"]),
        objectId: intOrNull(json["object_id"]),
        objectType: stringOrNull(json["object_type"]),
        createdBy: intOrNull(json["created_by"]),
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
