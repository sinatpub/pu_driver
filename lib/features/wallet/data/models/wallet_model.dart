// To parse this JSON data, do
//
//     final walletModel = walletModelFromJson(jsonString);

import 'dart:convert';

WalletModel walletModelFromJson(String str) =>
    WalletModel.fromJson(json.decode(str));

String walletModelToJson(WalletModel data) => json.encode(data.toJson());

class WalletModel {
  Data? data;
  bool? status;
  String? message;

  WalletModel({
    this.data,
    this.status,
    this.message,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        status: json["status"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
        "status": status,
        "message": message,
      };
}

class Data {
  dynamic id;
  dynamic balance;
  dynamic debted;
  dynamic commistionFare;
  dynamic currency;
  List<Transaction>? transactions;

  Data({
    this.id,
    this.balance,
    this.debted,
    this.currency,
    this.commistionFare,
    this.transactions,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        balance: json["balance"],
        debted: json["debted"],
        commistionFare: json["commission_fare"],
        currency: json["currency"],
        transactions: List<Transaction>.from(
            json["transactions"].map((x) => Transaction.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "balance": balance,
        "debted": debted,
        "commission_fare": commistionFare,
        "currency": currency,
        "transactions":
            List<dynamic>.from(transactions!.map((x) => x.toJson())),
      };
}

class Transaction {
  dynamic id;
  dynamic type;
  dynamic typeName;
  dynamic amount;
  dynamic currency;
  dynamic status;
  dynamic statusName;
  dynamic referenceId;
  dynamic createdBy;
  dynamic createdAt;

  Transaction({
    this.id,
    this.type,
    this.typeName,
    this.amount,
    this.currency,
    this.status,
    this.statusName,
    this.referenceId,
    this.createdBy,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json["id"],
        type: json["type"],
        typeName: json["type_name"],
        amount: json["amount"],
        currency: json["currency"],
        status: json["status"],
        statusName: json["status_name"],
        referenceId: json["reference_id"],
        createdBy: json["created_by"],
        createdAt: json["created_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "type_name": typeName,
        "amount": amount,
        "currency": currency,
        "status": status,
        "status_name": statusName,
        "reference_id": referenceId,
        "created_by": createdBy,
        "created_at": createdAt,
      };
}
