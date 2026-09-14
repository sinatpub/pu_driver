/// N-02 (docs/12) — invites and attribution: who counts as whose invitee,
/// and what the client may decide about an invite code on its own.
///
/// Spec: `ux_ui_design/referral-ux-copy-deck.md` §6 (direct-only rule), §7
/// (invite flow), §13 (error copy), §18 (open questions); `docs/03` N1, N6.
/// Neither app has any referral or invite field today — not in
/// registration, not in the profile — so there is no wire format, and the
/// server remains the only authority on whether a code matches a driver.
///
/// Pure: no copy, no Flutter, no HTTP.
library;

/// Does the invited person receive anything? — copy deck §18, one of the two
/// questions it says "block the entire deck".
///
/// Required with **no default**. It decides whether the invite message can
/// say `we both start earning`, which §7 calls "either the strongest line in
/// the deck or a false promise".
enum JoinerReward {
  /// The invited driver gets something too.
  invitedPersonRewarded,

  /// Only the inviter earns.
  noJoinerReward,
}

/// Can an existing account be linked to an inviter after signup? — §18,
/// with its error string still reading `{Confirm rule — see §18}`.
///
/// Required with **no default**.
enum LateAttribution {
  /// Codes can only be entered during signup.
  signupOnly,

  /// A code can be added to an existing account.
  allowedAfterSignup,
}

/// Which driver invite message may be sent (§7).
enum InviteMessageVariant {
  /// A: `I drive with {Platform}. Sign up with my code {CODE} and we both
  /// start earning.`
  weBothStartEarning,

  /// B: `I drive with {Platform}. Use my code {CODE} when you sign up.`
  /// Makes no promise it cannot keep.
  neutral,
}

/// The driver invite message allowed under [joinerReward].
///
/// §7: variant A is "**Do not use if they don't**" get anything — "we both"
/// would be a lie. The promotional variant C is not modelled at all.
///
/// The passenger message (`Use my code {CODE} for your first ride…`) has
/// only one variant and is not modelled here. Worth raising alongside the
/// same question, though: "for your first ride" reads as if the passenger
/// gets something for using the code.
InviteMessageVariant driverInviteMessage(JoinerReward joinerReward) =>
    switch (joinerReward) {
      JoinerReward.invitedPersonRewarded =>
        InviteMessageVariant.weBothStartEarning,
      JoinerReward.noJoinerReward => InviteMessageVariant.neutral,
    };

// ---- Code entry ----------------------------------------------------------

/// What the client can conclude about an entered code by itself. Each
/// refusal maps to one row of §13.
enum InviteCodeCheck {
  /// Blank. Allowed: §13 offers "continue without one".
  noCode,

  /// `You can't use your own invite code.`
  ownCode,

  /// `Your account is already linked to an invite.`
  alreadyLinked,

  /// `Invite codes can only be added when you sign up.`
  afterSignupWindow,

  /// Passes every rule the client can check. Whether it matches a driver
  /// (`That code doesn't match any driver.`) only the server can say.
  needsServerCheck,
}

/// The code as the user meant it: surrounding whitespace removed, since
/// codes are pasted from messages.
///
/// Case is **not** folded. The code format is unspecified, and folding
/// case would be a guess about it. The cost is only that a wrongly-cased
/// own code is refused by the server rather than by the client.
String normalizeInviteCode(String raw) => raw.trim();

/// Checks [entered] against the rules the client can decide.
///
/// Order matters for which message the user sees. An account that already
/// has an inviter hears that first, because it is the one fact no other
/// code could change. A closed window comes next, and own code last.
///
/// At signup, [ownCode] is null: a new account has no code yet, so a person
/// re-registering to invite themselves can only be caught server-side (the
/// device and payment matching `docs/03` N6 assigns to fraud detection).
InviteCodeCheck checkInviteCode({
  required String entered,
  required String? ownCode,
  required bool alreadyHasInviter,
  required bool isSigningUp,
  required LateAttribution lateAttribution,
}) {
  final code = normalizeInviteCode(entered);
  if (code.isEmpty) return InviteCodeCheck.noCode;
  if (alreadyHasInviter) return InviteCodeCheck.alreadyLinked;
  if (!isSigningUp && lateAttribution == LateAttribution.signupOnly) {
    return InviteCodeCheck.afterSignupWindow;
  }
  final own = ownCode == null ? null : normalizeInviteCode(ownCode);
  if (own != null && own.isNotEmpty && code == own) {
    return InviteCodeCheck.ownCode;
  }
  return InviteCodeCheck.needsServerCheck;
}

// ---- Attribution ---------------------------------------------------------

/// Only drivers invite; both drivers and passengers can be invited.
enum InviteeKind { driver, passenger }

/// An invited person.
///
/// Kind is part of identity. Drivers and passengers are separate accounts
/// with separate ids, so passenger `5` and driver `5` are different people,
/// and keying attribution on the bare id would merge them.
class Invitee {
  const Invitee(this.kind, this.id);

  final InviteeKind kind;
  final int id;

  @override
  bool operator ==(Object other) =>
      other is Invitee && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'Invitee(${kind.name} $id)';
}

/// Why an attribution may not be recorded.
enum AttributionRefusal {
  /// A driver inviting themselves.
  selfReferral,

  /// "Each account can have one inviter" (§13). Attribution is permanent
  /// once established (`docs/03` N1).
  alreadyLinked,

  /// The inviter was themselves invited, directly or further up, by this
  /// invitee. `docs/03` N6 lists circular referral as an abuse signal. It
  /// can only arise if [LateAttribution.allowedAfterSignup] is chosen: at
  /// signup a new driver has invited nobody, so no loop can close.
  circular,
}

/// Whether [invitee] may be attributed to the driver [inviterDriverId],
/// given the existing [attributions] (invitee → inviting driver id). Null
/// means it may.
AttributionRefusal? refuseAttribution({
  required Invitee invitee,
  required int inviterDriverId,
  required Map<Invitee, int> attributions,
}) {
  final isDriver = invitee.kind == InviteeKind.driver;
  if (isDriver && invitee.id == inviterDriverId) {
    return AttributionRefusal.selfReferral;
  }
  if (attributions.containsKey(invitee))
    return AttributionRefusal.alreadyLinked;

  // Passengers invite nobody, so only a driver invitee can close a loop.
  if (isDriver) {
    final seen = <int>{};
    int? current = inviterDriverId;
    while (current != null && seen.add(current)) {
      final upstream = attributions[Invitee(InviteeKind.driver, current)];
      if (upstream == invitee.id) return AttributionRefusal.circular;
      current = upstream;
    }
  }
  return null;
}

/// Whether [driverId] earns from activity by [activityOwner] — the
/// direct-only rule (§6).
///
/// True only when [driverId] invited [activityOwner] themselves. "If a driver
/// you invited invites someone else, that person's activity doesn't earn you
/// anything." A driver never earns from their own activity, even if bad data
/// records them as their own inviter.
bool earnsFrom({
  required int driverId,
  required Invitee activityOwner,
  required Map<Invitee, int> attributions,
}) {
  if (activityOwner.kind == InviteeKind.driver &&
      activityOwner.id == driverId) {
    return false;
  }
  return attributions[activityOwner] == driverId;
}
