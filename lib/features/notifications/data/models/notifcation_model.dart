// To parse this JSON data, do
//
//     final notificationMode = notificationModeFromJson(jsonString);

import 'dart:convert';

NotificationModel notificationModeFromJson(String str) =>
    NotificationModel.fromJson(json.decode(str));

String notificationModeToJson(NotificationModel data) =>
    json.encode(data.toJson());

class NotificationModel {
  bool? status;
  List<DataNotification>? data;
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;

  NotificationModel({
    this.status,
    this.data,
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        status: json["status"],
        data: List<DataNotification>.from(
            json["data"].map((x) => DataNotification.fromJson(x))),
        currentPage: json["current_page"],
        lastPage: json["last_page"],
        perPage: json["per_page"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": List<dynamic>.from(data!.map((x) => x.toJson())),
        "current_page": currentPage,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
      };
}

class DataNotification {
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

  DataNotification({
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

  factory DataNotification.fromJson(Map<String, dynamic> json) =>
      DataNotification(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        releaseDate: json["release_date"],
        expiredDate: json["expired_date"],
        target: json["target"],
        status: json["status"],
        createdBy: json["created_by"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        files: List<FileElement>.from(
            json["files"].map((x) => FileElement.fromJson(x))),
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
        id: json["id"],
        fileOriginalName: json["file_original_name"],
        fileSize: json["file_size"],
        fileType: json["file_type"],
        fileUrl: json["file_url"],
        objectId: json["object_id"],
        objectType: json["object_type"],
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
