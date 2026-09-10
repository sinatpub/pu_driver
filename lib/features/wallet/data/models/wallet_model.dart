// To parse this JSON data, do
//
//     final walletModel = walletModelFromJson(jsonString);

import 'dart:convert';

import 'package:tara_driver_application/core/utils/money.dart';

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

  /// N-01: typed views over the `dynamic` money fields. The backend sends
  /// these sometimes as numbers and sometimes as quoted strings; every caller
  /// coercing for itself is how a wallet screen ends up showing "12.50" in
  /// one place and 12.5 in another. Null means "not reported", which is not
  /// the same as zero.
  num? get balanceAmount => parseMoney(balance);
  num? get debtedAmount => parseMoney(debted);
  num? get commissionFareAmount => parseMoney(commistionFare);

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        balance: json["balance"],
        debted: json["debted"],
        commistionFare: json["commission_fare"],
        currency: json["currency"],
        // N-01: was `json["transactions"].map(...)` with no null check, so a
        // driver with no transactions yet — every newly approved driver —
        // hit a NoSuchMethodError on null and could not open their wallet.
        transactions: json["transactions"] is List
            ? List<Transaction>.from(
                (json["transactions"] as List)
                    .map((x) => Transaction.fromJson(x as Map<String, dynamic>)))
            : const <Transaction>[],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "balance": balance,
        "debted": debted,
        "commission_fare": commistionFare,
        "currency": currency,
        // N-01: was a force-unwrap on a nullable list.
        "transactions":
            List<dynamic>.from((transactions ?? const []).map((x) => x.toJson())),
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

  /// N-01: see `Data.balanceAmount`.
  num? get amountValue => parseMoney(amount);

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
