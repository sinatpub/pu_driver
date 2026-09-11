/// N-06 (docs/12) — the driver-facing half of anti-abuse: what a reward
/// under review or rejected looks like to the driver.
///
/// N-06 is mostly server work — KYC, fraud detection, top-up monitoring
/// (`docs/03` N6) — and none of that exists. Its client half is the copy deck
/// §14 rule: "communicate verification without accusing the driver, and
/// without promising money before it's confirmed."
///
/// The account-level `Referral rewards paused` banner is not modelled: it is
/// fixed copy with no state beyond "paused". Its one rule is that it must
/// always carry `Trip earnings aren't affected`, and that belongs to the
/// view's string.
///
/// Pure: no copy, no Flutter, no HTTP.
library;

import 'package:tara_driver_application/features/referral/domain/reward_status.dart';

/// Why a reward was found not eligible.
///
/// Known to the server and the admin panel, **never displayed to the
/// driver**: both reasons render as the same `Not eligible` pill. The
/// admin strategy (§8.4): "Never expose detection thresholds in the
/// driver-facing UI … The admin panel is where the real reason lives."
enum NotEligibleReason {
  /// `This activity didn't qualify for a reward. [ Why? ]`
  ineligibleActivity,

  /// `This reward couldn't be confirmed. [ Contact support ]`
  suspectedAbuse,
}

/// What a reward's status pill says (§14). There is deliberately no
/// "approved": "Never say approved … `Pending` throughout, then `Available`.
/// No intermediate reassurance."
enum RewardDisplayState {
  /// `Pending` / `Confirming — available in {n} days`
  pending,

  /// `Being reviewed` / `This is taking longer than usual…`
  beingReviewed,

  available,
  transferred,
  withdrawn,

  /// `Not eligible`, whichever [NotEligibleReason] applies.
  notEligible,

  /// `Reversed` / `The top-up this reward came from was refunded.`
  reversed,
}

/// The one action a not-eligible reward offers.
enum NotEligibleAction {
  /// `[ Why? ]` — explains the rules.
  explainWhy,

  /// `[ Contact support ]`
  contactSupport,
}

/// The pill for a reward with [status] at [now].
///
/// A pending reward reads as **being reviewed** when the server flags it,
/// or when the clearing time the server itself stated has passed and it is
/// still not available. `Confirming — available in 0 days` on a reward
/// that is overdue is a promise already broken. §14's line for this case,
/// `This is taking longer than usual`, is simply true then.
///
/// A missing [availableAt] never makes a reward look overdue; there was no
/// promise to break.
RewardDisplayState rewardDisplayState({
  required RewardStatus status,
  required bool flaggedForReview,
  required DateTime? availableAt,
  required DateTime now,
}) {
  switch (status) {
    case RewardStatus.pending:
      final due = availableAt;
      final overdue = due != null && !now.isBefore(due);
      return flaggedForReview || overdue
          ? RewardDisplayState.beingReviewed
          : RewardDisplayState.pending;
    case RewardStatus.available:
      return RewardDisplayState.available;
    case RewardStatus.transferred:
      return RewardDisplayState.transferred;
    case RewardStatus.withdrawn:
      return RewardDisplayState.withdrawn;
    case RewardStatus.notEligible:
      return RewardDisplayState.notEligible;
    case RewardStatus.reversed:
      return RewardDisplayState.reversed;
  }
}

/// The action for a not-eligible reward.
///
/// An unknown reason gets `Contact support`. It explains no rules and
/// accuses no one, where `Why?` would promise an explanation of rules that
/// may not be the reason at all.
NotEligibleAction notEligibleAction(NotEligibleReason? reason) =>
    reason == NotEligibleReason.ineligibleActivity
        ? NotEligibleAction.explainWhy
        : NotEligibleAction.contactSupport;
