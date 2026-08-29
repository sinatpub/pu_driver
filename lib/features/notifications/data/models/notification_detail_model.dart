// To parse this JSON data, do
//
//     final detailNotificationModel = detailNotificationModelFromJson(jsonString);

import 'dart:convert';

DetailNotificationModel detailNotificationModelFromJson(String str) => DetailNotificationModel.fromJson(json.decode(str));

String detailNotificationModelToJson(DetailNotificationModel data) => json.encode(data.toJson());

class DetailNotificationModel {
    bool? status;
    DataDetailNotification? data;

    DetailNotificationModel({
        this.status,
        this.data,
    });

    factory DetailNotificationModel.fromJson(Map<String, dynamic> json) => DetailNotificationModel(
        status: json["status"],
        data: DataDetailNotification.fromJson(json["data"]),
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

    factory DataDetailNotification.fromJson(Map<String, dynamic> json) => DataDetailNotification(
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
        files: List<FileElement>.from(json["files"].map((x) => FileElement.fromJson(x))),
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
