// DateFormat comes via easy_localization's re-export, as in
// `wallet_presentation.dart`.
import 'package:easy_localization/easy_localization.dart';
import 'package:pu_taxi_driver/presentation/screens/history/widgets/history_days.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/wallet_presentation.dart'
    show isWholeUnitCurrency;

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

/// Everything moved into the wallet balance so far.
num totalTransferred(List<RewardTransfer> transfers) {
  num sum = 0;
  for (final RewardTransfer t in transfers) {
    sum += t.amount ?? 0;
  }
  return sum;
}

/// What the driver can transfer now (DD-48): the server's `reward_balance`,
/// or, when it does not send one, what was earned less what was moved. Never
/// below zero.
num rewardBalance(ReferralModel? referral) {
  if (referral == null) return 0;
  final num value = referral.rewardBalance ??
      totalEarned(referral.rewards) - totalTransferred(referral.transfers);
  return value < 0 ? 0 : value;
}

/// Where a transfer of [amount] goes (DD-48). The wallet pays what the
/// driver owes first (DD-43), so with a debt only the rest reaches the
/// balance.
class TransferPreview {
  const TransferPreview({
    required this.toDebt,
    required this.toBalance,
    required this.debtLeft,
    required this.balanceAfter,
  });

  /// The part that pays unpaid commission. Zero with no debt.
  final num toDebt;

  /// The part that becomes usable balance.
  final num toBalance;

  /// What is still owed after the transfer.
  final num debtLeft;

  /// The wallet balance after the transfer; null when the balance is not
  /// known (the wallet has not loaded).
  final num? balanceAfter;
}

TransferPreview transferPreview({
  required num amount,
  required num? balance,
  required num? debt,
}) {
  final num owed = debt != null && debt > 0 ? debt : 0;
  final num toDebt = amount < owed ? amount : owed;
  final num toBalance = amount - toDebt;
  return TransferPreview(
    toDebt: toDebt,
    toBalance: toBalance,
    debtLeft: owed - toDebt,
    balanceAfter: balance == null ? null : balance + toBalance,
  );
}

/// The amount the driver typed (DD-49), or null when it is not one: empty,
/// not a number, zero or less, or finer than the currency goes — riel has no
/// fraction, other currencies have two decimals.
num? parseTransferAmount(String text, String? currency) {
  final String cleaned = text.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final num? value = num.tryParse(cleaned);
  if (value == null || value <= 0) return null;
  if (isWholeUnitCurrency(currency)) {
    return value == value.roundToDouble() ? value.round() : null;
  }
  final num cents = value * 100;
  if ((cents - cents.round()).abs() > 1e-6) return null;
  return cents.round() / 100;
}

/// [amount] as the amount field holds it — "5160", "12.50": no symbol and no
/// grouping, so it parses back to the same number. What "All" fills in.
String transferAmountText(num amount, String? currency) =>
    isWholeUnitCurrency(currency)
        ? amount.round().toString()
        : amount.toStringAsFixed(2);

/// Whether [amount] can be transferred out of [available].
enum TransferAmountCheck {
  ok,

  /// Nothing usable typed yet. Not an error to show — the button waits.
  empty,

  /// More than the reward balance holds.
  tooMuch,
}

TransferAmountCheck checkTransferAmount(num? amount, num available) {
  if (amount == null || amount <= 0) return TransferAmountCheck.empty;
  if (amount > available) return TransferAmountCheck.tooMuch;
  return TransferAmountCheck.ok;
}

/// One line of the reward history: a reward earned, or a transfer out.
sealed class RewardEntry {
  const RewardEntry();

  DateTime? get at;
}

class EarnedEntry extends RewardEntry {
  const EarnedEntry(this.reward);

  final ReferralReward reward;

  @override
  DateTime? get at => parseHistoryTime(reward.createdAt);
}

class TransferEntry extends RewardEntry {
  const TransferEntry(this.transfer);

  final RewardTransfer transfer;

  @override
  DateTime? get at => parseHistoryTime(transfer.createdAt);
}

/// Rewards and transfers in one list, newest first.
List<RewardEntry> rewardEntries(
  List<ReferralReward> rewards,
  List<RewardTransfer> transfers,
) {
  final List<RewardEntry> list = <RewardEntry>[
    for (final RewardTransfer t in transfers) TransferEntry(t),
    for (final ReferralReward r in rewards) EarnedEntry(r),
  ];
  _sortNewestFirst(list, (RewardEntry e) => e.at);
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

/// One line of the reward list: a day header or an entry.
sealed class RewardRow {
  const RewardRow();
}

class RewardDayHeader extends RewardRow {
  const RewardDayHeader(this.day);

  /// Midnight of the day.
  final DateTime day;
}

class RewardItemRow extends RewardRow {
  const RewardItemRow(this.entry);

  final RewardEntry entry;
}

/// [entries] (already sorted) with a [RewardDayHeader] before the first one
/// of each day — the same grouping as the wallet and the riding history.
List<RewardRow> rewardRows(List<RewardEntry> entries) {
  final List<RewardRow> rows = <RewardRow>[];
  DateTime? current;
  for (final RewardEntry e in entries) {
    final DateTime? at = e.at;
    if (at != null) {
      final DateTime day = DateTime(at.year, at.month, at.day);
      if (day != current) {
        rows.add(RewardDayHeader(day));
        current = day;
      }
    }
    rows.add(RewardItemRow(e));
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
