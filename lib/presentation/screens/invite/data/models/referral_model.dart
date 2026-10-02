import 'package:tara_driver_application/core/utils/money.dart';

/// The driver's invite code, what it earns, and who it brought in (DD-45).
///
/// The shape is the app's proposal: no backend endpoint exists yet, so the
/// mock backend is the only thing that produces it. Parsing is tolerant in
/// the way the wallet's is — a missing field is null or empty, never a throw.
class ReferralModel {
  const ReferralModel({
    this.code,
    this.link,
    this.currency,
    this.driverTopUpRate,
    this.passengerCommissionRate,
    this.invitees = const <Invitee>[],
    this.rewards = const <ReferralReward>[],
  });

  factory ReferralModel.fromJson(dynamic json) {
    final Map<String, dynamic> root =
        json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final dynamic data = root['data'];
    final Map<String, dynamic> map =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return ReferralModel(
      code: map['code']?.toString(),
      link: map['link']?.toString(),
      currency: map['currency']?.toString(),
      driverTopUpRate: parseMoney(map['driver_top_up_rate']),
      passengerCommissionRate: parseMoney(map['passenger_commission_rate']),
      invitees: <Invitee>[
        for (final dynamic item
            in map['invitees'] as List? ?? const <dynamic>[])
          if (item is Map<String, dynamic>) Invitee.fromJson(item),
      ],
      rewards: <ReferralReward>[
        for (final dynamic item in map['rewards'] as List? ?? const <dynamic>[])
          if (item is Map<String, dynamic>) ReferralReward.fromJson(item),
      ],
    );
  }

  /// "PU7K2M" — what a new person types at sign-up.
  final String? code;

  /// What the QR holds: a link that opens the sign-up page with [code].
  final String? link;
  final String? currency;

  /// Percent of an invited driver's wallet top-ups paid to the inviter.
  final num? driverTopUpRate;

  /// Percent of the platform's commission on an invited passenger's trips
  /// paid to the inviter.
  final num? passengerCommissionRate;

  final List<Invitee> invitees;
  final List<ReferralReward> rewards;
}

/// Someone who signed up with the driver's code.
class Invitee {
  const Invitee({
    this.id,
    this.name,
    this.image,
    this.role,
    this.joinedAt,
    this.earned,
  });

  factory Invitee.fromJson(Map<String, dynamic> json) => Invitee(
        id: json['id'],
        name: json['name']?.toString(),
        image: json['profile_image']?.toString(),
        role: json['role']?.toString(),
        joinedAt: json['joined_at']?.toString(),
        earned: parseMoney(json['earned']),
      );

  final dynamic id;
  final String? name;
  final String? image;

  /// "driver" or "passenger".
  final String? role;
  final String? joinedAt;

  /// What this person has earned the driver so far.
  final num? earned;
}

/// One reward: an invited driver topped up, or an invited passenger rode.
class ReferralReward {
  const ReferralReward({
    this.id,
    this.inviteeName,
    this.role,
    this.amount,
    this.baseAmount,
    this.createdAt,
  });

  factory ReferralReward.fromJson(Map<String, dynamic> json) => ReferralReward(
        id: json['id'],
        inviteeName: json['invitee_name']?.toString(),
        role: json['invitee_role']?.toString(),
        amount: parseMoney(json['amount']),
        baseAmount: parseMoney(json['base_amount']),
        createdAt: json['created_at']?.toString(),
      );

  final dynamic id;
  final String? inviteeName;
  final String? role;
  final num? amount;

  /// The top-up the reward was taken from. Null for a trip reward: what the
  /// platform earned on someone else's trip is not the driver's to see.
  final num? baseAmount;
  final String? createdAt;
}

/// The answer to "is this invite code real?" at sign-up.
class InviteCodeCheck {
  const InviteCodeCheck({required this.valid, this.inviterName});

  factory InviteCodeCheck.fromJson(dynamic json) {
    final Map<String, dynamic> root =
        json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final dynamic data = root['data'];
    final Map<String, dynamic> map =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return InviteCodeCheck(
      valid: map['valid'] == true,
      inviterName: map['inviter_name']?.toString(),
    );
  }

  final bool valid;
  final String? inviterName;
}
