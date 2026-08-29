// To parse this JSON data, do
//
//     final walletModel = walletModelFromJson(jsonString);

import 'dart:convert';

VersionAppModel versionAppModelFromJson(String str) => VersionAppModel.fromJson(json.decode(str));

String versionAppModelToJson(VersionAppModel data) => json.encode(data.toJson());

class VersionAppModel {
    Data? data;
    String? message;

    VersionAppModel({
        this.data,
        this.message,
    });

    factory VersionAppModel.fromJson(Map<String, dynamic> json) => VersionAppModel(
        data: json["data"] == null?null: Data.fromJson(json["data"]),
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
        "message": message,
    };
}

class Data {
    dynamic id;
    dynamic appType;
    dynamic releaseDate;
    dynamic releaseDateIos;
    dynamic versionAndroid;
    dynamic versionIos;
    dynamic playStoreLink;
    dynamic appStoreLink;
    dynamic featureRelease;
    dynamic isActive;
   

    Data({
        this.id,
        this.appType,
        this.releaseDate,
        this.releaseDateIos,
        this.versionAndroid,
        this.versionIos,
        this.playStoreLink,
        this.appStoreLink,
        this.featureRelease,
        this.isActive,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        appType: json["app_type"],
        releaseDate: json["release_date"],
        releaseDateIos: json["release_date_ios"],
        versionAndroid: json["version_android"],
        versionIos: json["version_ios"],
        playStoreLink: json["play_store_link"],
        appStoreLink: json["app_store_link"],
        featureRelease: json["features_release"],
        isActive: json["is_active"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "app_type": appType,
        "release_date": releaseDate,
        "release_date_ios": releaseDateIos,
        "version_android": versionAndroid,
        "version_ios": versionIos,
        "play_store_link": playStoreLink,
        "app_store_link": appStoreLink,
        "features_release": featureRelease,
        "is_active": isActive,
    };
}
