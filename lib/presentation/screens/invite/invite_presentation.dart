// DateFormat comes via easy_localization's re-export, as in
// `wallet_presentation.dart`.
import 'package:easy_localization/easy_localization.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_days.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';

/// DD-45 — the rules of the invite and rewards screens.
///
/// Pure, like `wallet_presentation.dart`: no GetX, no BuildContext. Rewards
/// are the driver's money, so every sum and every ordering rule is here,
/// where it is tested, and not inside a widget.

/// Who an invited person is. The reward rule depends on it.
enum InviteeRole {
  driver,
  passenger,
  unknown;

  static InviteeRole of(String? role) =>
      switch ((role ?? '').trim().toLowerCase()) {
        'driver' => InviteeRole.driver,
        'passenger' => InviteeRole.passenger,
        _ => InviteeRole.unknown,
      };
}

/// An invite code is 4 to 12 letters and digits.
final RegExp _codePattern = RegExp(r'^[A-Z0-9]{4,12}$');

/// The invite code inside [raw], or null when there is none.
///
/// [raw] is what a person typed or what a QR held. A QR holds a link — the
/// code is its `code` parameter, or else its last path segment — but a bare
/// code is accepted too. Case and surrounding spaces do not matter.
String? parseInviteCode(String? raw) {
  final String text = (raw ?? '').trim();
  if (text.isEmpty) return null;

  String candidate = text;
  final Uri? uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    final String? fromQuery = uri.queryParameters['code'];
    final List<String> segments =
        uri.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (fromQuery != null && fromQuery.isNotEmpty) {
      candidate = fromQuery;
    } else if (segments.isNotEmpty) {
      candidate = segments.last;
    } else {
      return null;
    }
  }

  final String code = candidate.trim().toUpperCase();
  return _codePattern.hasMatch(code) ? code : null;
}

/// What the QR encodes: the server's link, or the bare code when it sent no
/// link. Null when there is nothing to show.
String? inviteQrData(ReferralModel? referral) {
  final String link = (referral?.link ?? '').trim();
  if (link.isNotEmpty) return link;
  final String code = (referral?.code ?? '').trim();
  return code.isEmpty ? null : code;
}

/// Everything the invited people have earned the driver.
num totalEarned(List<ReferralReward> rewards) => earnedFrom(rewards, null);

/// What invited people of [role] have earned the driver; null means all.
num earnedFrom(List<ReferralReward> rewards, InviteeRole? role) {
  num sum = 0;
  for (final ReferralReward r in rewards) {
    if (role != null && InviteeRole.of(r.role) != role) continue;
    sum += r.amount ?? 0;
  }
  return sum;
}

/// Invited people of [role]; null means everyone. Newest first.
List<Invitee> inviteesOf(List<Invitee> invitees, InviteeRole? role) {
  final List<Invitee> list = <Invitee>[
    for (final Invitee i in invitees)
      if (role == null || InviteeRole.of(i.role) == role) i,
  ];
  _sortNewestFirst(list, (Invitee i) => parseHistoryTime(i.joinedAt));
  return list;
}

/// Rewards, newest first.
List<ReferralReward> sortedRewards(List<ReferralReward> rewards) {
  final List<ReferralReward> list = <ReferralReward>[...rewards];
  _sortNewestFirst(list, (ReferralReward r) => parseHistoryTime(r.createdAt));
  return list;
}

/// Newest first; an item with no readable date goes last; ties keep the
/// order the server sent.
void _sortNewestFirst<T>(List<T> list, DateTime? Function(T) dateOf) {
  final Map<T, int> order = <T, int>{
    for (int i = 0; i < list.length; i++) list[i]: i,
  };
  list.sort((T a, T b) {
    final DateTime? da = dateOf(a);
    final DateTime? db = dateOf(b);
    if (da == null && db == null) return order[a]!.compareTo(order[b]!);
    if (da == null) return 1;
    if (db == null) return -1;
    final int byDate = db.compareTo(da);
    return byDate != 0 ? byDate : order[a]!.compareTo(order[b]!);
  });
}

/// One line of the reward list: a day header or a reward.
sealed class RewardRow {
  const RewardRow();
}

class RewardDayHeader extends RewardRow {
  const RewardDayHeader(this.day);

  /// Midnight of the day.
  final DateTime day;
}

class RewardItemRow extends RewardRow {
  const RewardItemRow(this.reward);

  final ReferralReward reward;
}

/// [rewards] (already sorted) with a [RewardDayHeader] before the first one
/// of each day — the same grouping as the wallet and the riding history.
List<RewardRow> rewardRows(List<ReferralReward> rewards) {
  final List<RewardRow> rows = <RewardRow>[];
  DateTime? current;
  for (final ReferralReward r in rewards) {
    final DateTime? at = parseHistoryTime(r.createdAt);
    if (at != null) {
      final DateTime day = DateTime(at.year, at.month, at.day);
      if (day != current) {
        rows.add(RewardDayHeader(day));
        current = day;
      }
    }
    rows.add(RewardItemRow(r));
  }
  return rows;
}

/// "12 Sep", or "12 Sep 2025" for another year. Digits-only if the locale's
/// month names are not loaded.
String inviteShortDate(DateTime day, {required DateTime now, String? locale}) {
  try {
    return DateFormat(day.year == now.year ? 'd MMM' : 'd MMM yyyy', locale)
        .format(day);
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(day);
  }
}
