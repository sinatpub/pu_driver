/// N-07 (docs/12) — the per-invitee referral lifecycle, specified in
/// `ux_ui_design/referral-ux-copy-deck.md` §8.
///
/// Pure domain: no copy, no GetX, no widgets. The stages and the rules about
/// them are here; the labels and their translations belong with the view, as
/// with every other state model in this codebase.
///
/// The spec's central rule, and the reason this is a type rather than a
/// string: **"registered" must never read as "earning."** A driver who sees
/// five names and assumes five income streams "will feel cheated within a
/// week, and will say so to other drivers." [InviteeStage.isEarning] is what
/// makes that a property of the model instead of a copywriting habit.
library;

/// How long without activity before an invitee reads as inactive.
///
/// **Placeholder, not a decision.** `docs/03` N7 records "30 days is a
/// placeholder" and the question of what defines inactivity is unanswered.
/// Named so the eventual answer is a one-line change rather than a hunt.
const int kInviteeInactivityDaysPlaceholder = 30;

/// A driver invitee's stage. Ordered as the spec lists them.
enum DriverInviteeStage {
  /// Link shared, nobody joined.
  inviteSent,

  /// Account created.
  signedUp,

  /// Documents verified.
  verified,

  /// Wallet activated, no top-up yet.
  readyToEarn,

  /// First top-up made — the first stage that earns anything.
  earning,

  /// No top-ups for [kInviteeInactivityDaysPlaceholder] days.
  inactive,
}

/// A passenger invitee's stage. The passenger flow has no verification or
/// wallet-activation step, so it is four stages rather than six.
enum PassengerInviteeStage {
  inviteSent,
  signedUp,

  /// First trip completed.
  earning,

  inactive,
}

extension DriverInviteeStageRules on DriverInviteeStage {
  /// Whether this invitee is actually earning the referrer money.
  ///
  /// Only [DriverInviteeStage.earning] is. Everything before it must show the
  /// spec's explicit "Not earning yet" line, and [inactive] is deliberately
  /// **not** earning — an invitee who has stopped topping up is not producing
  /// income today, whatever they produced last month.
  bool get isEarning => this == DriverInviteeStage.earning;

  /// Whether the stage precedes any earning at all, which is where the spec
  /// requires the "Not earning yet" sub-line plus a statement of what unlocks
  /// it.
  bool get requiresNotEarningYetNotice =>
      this == DriverInviteeStage.signedUp ||
      this == DriverInviteeStage.verified ||
      this == DriverInviteeStage.readyToEarn;

  /// Whether this invitee has ever earned anything for the referrer.
  ///
  /// True for [inactive] as well as [earning]: an inactive invitee topped up
  /// at least once to have reached that stage, so their historical total is
  /// real and must not be shown as zero.
  bool get hasEverEarned =>
      this == DriverInviteeStage.earning ||
      this == DriverInviteeStage.inactive;
}

extension PassengerInviteeStageRules on PassengerInviteeStage {
  bool get isEarning => this == PassengerInviteeStage.earning;

  bool get requiresNotEarningYetNotice =>
      this == PassengerInviteeStage.signedUp;

  bool get hasEverEarned =>
      this == PassengerInviteeStage.earning ||
      this == PassengerInviteeStage.inactive;
}

/// The stage a driver invitee is in, derived from what they have done.
///
/// Deliberately takes facts rather than a status string: the backend has no
/// referral endpoint yet (probe-confirmed 2026-09-10), so there is no wire
/// format to parse and inventing one would be guessing. When the endpoint
/// exists this becomes the mapping layer for it, and the rules below stay put.
DriverInviteeStage driverInviteeStage({
  required bool hasSignedUp,
  required bool documentsVerified,
  required bool walletActivated,
  required bool hasToppedUp,
  int? daysSinceLastTopUp,
}) {
  if (!hasSignedUp) return DriverInviteeStage.inviteSent;

  if (hasToppedUp) {
    final idle = daysSinceLastTopUp;
    if (idle != null && idle >= kInviteeInactivityDaysPlaceholder) {
      return DriverInviteeStage.inactive;
    }
    return DriverInviteeStage.earning;
  }

  // Checked in spec order: verification precedes wallet activation, and a
  // driver cannot be "ready to earn" without being verified first.
  if (!documentsVerified) return DriverInviteeStage.signedUp;
  if (!walletActivated) return DriverInviteeStage.verified;
  return DriverInviteeStage.readyToEarn;
}

/// The stage a passenger invitee is in.
PassengerInviteeStage passengerInviteeStage({
  required bool hasSignedUp,
  required bool hasCompletedTrip,
  int? daysSinceLastTrip,
}) {
  if (!hasSignedUp) return PassengerInviteeStage.inviteSent;
  if (!hasCompletedTrip) return PassengerInviteeStage.signedUp;

  final idle = daysSinceLastTrip;
  if (idle != null && idle >= kInviteeInactivityDaysPlaceholder) {
    return PassengerInviteeStage.inactive;
  }
  return PassengerInviteeStage.earning;
}
