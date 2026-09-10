/// N-03 (docs/12) — the reward lifecycle and ledger status.
///
/// This is the model **U1 blocks**, so it is built to survive either answer
/// rather than to pre-empt one. See [RewardLifecycle].
library;

/// Days a reward stays pending before becoming available.
///
/// **Placeholder, not a decision.** `docs/03` U4: the value appears as `{n}`
/// in six user-facing strings and admin mockups show "3 days" as an example.
/// It is a business/ops call, not a design one.
const int kRewardPendingDaysPlaceholder = 3;

/// Where the reward money comes from — **U2**, and the single highest-priority
/// blocking question in the project (`docs/03` §6.4).
///
/// `reward_driver_flowchart.png` states it as settled ("platform-funded");
/// every UX document treats it as unresolved and blocking. `.agent/DECISIONS.md`
/// warns explicitly not to read the flowchart as authoritative.
///
/// Modelled as a required value with **no default**, deliberately. Any code
/// that computes or displays a reward has to state which funding model it
/// assumes, so the open question cannot be silently resolved by whoever writes
/// the first calculation.
enum RewardFunding {
  /// The platform pays the reward. The invited driver is unaffected.
  platformFunded,

  /// The reward is deducted from the invited driver's top-up.
  deductedFromInvitee,
}

/// A reward's status.
///
/// **U1 is why this has four values and not two.** The flowchart specifies
/// `Pending → Available → Transferred → Withdrawn`; the copy deck and layout
/// system describe `Pending → Available`, with transfer and withdrawal treated
/// as separate *wallet* actions rather than reward statuses.
///
/// The two-state model is a strict prefix of the four-state one, so modelling
/// the superset satisfies both: under the two-state answer, [transferred] and
/// [withdrawn] simply never occur, and [RewardLifecycle.twoState] makes that a
/// checkable rule rather than a convention. Choosing the smaller model now
/// would mean a migration if the flowchart turns out to be authoritative;
/// choosing the larger costs two unused values if it does not.
enum RewardStatus {
  /// Earned but not yet usable.
  pending,

  /// Cleared and usable now.
  available,

  /// Moved into the operational wallet. Four-state model only.
  transferred,

  /// Paid out externally. Four-state model only.
  withdrawn,

  /// The activity behind the reward was refunded, so the reward was reversed.
  ///
  /// Not part of either U1 candidate — `docs/03` N5 specifies reversal
  /// separately, and the copy deck requires it render in neutral styling,
  /// **never red**, because a routine reversal must not look like a system
  /// failure.
  reversed,
}

/// Which lifecycle model is in force — the U1 answer, once there is one.
enum RewardLifecycle {
  /// Copy deck / layout system: `Pending → Available`, with transfer and
  /// withdrawal handled as wallet actions.
  twoState,

  /// Flowchart: `Pending → Available → Transferred → Withdrawn`.
  fourState,
}

extension RewardLifecycleRules on RewardLifecycle {
  /// The statuses this model can produce. Reversal is possible under both.
  Set<RewardStatus> get validStatuses => switch (this) {
        RewardLifecycle.twoState => const {
            RewardStatus.pending,
            RewardStatus.available,
            RewardStatus.reversed,
          },
        RewardLifecycle.fourState => const {
            RewardStatus.pending,
            RewardStatus.available,
            RewardStatus.transferred,
            RewardStatus.withdrawn,
            RewardStatus.reversed,
          },
      };

  bool permits(RewardStatus status) => validStatuses.contains(status);

  /// Whether [from] may move to [to] under this model.
  ///
  /// Forward-only, with one exception: a reward may be reversed from any
  /// non-terminal status, because the refund that triggers it can land at any
  /// time. Nothing leaves [RewardStatus.reversed] or
  /// [RewardStatus.withdrawn] — money that has left cannot un-leave.
  bool allowsTransition(RewardStatus from, RewardStatus to) {
    if (!permits(from) || !permits(to)) return false;
    if (from == to) return false;
    if (from == RewardStatus.reversed || from == RewardStatus.withdrawn) {
      return false;
    }
    if (to == RewardStatus.reversed) return true;

    const order = [
      RewardStatus.pending,
      RewardStatus.available,
      RewardStatus.transferred,
      RewardStatus.withdrawn,
    ];
    final fromIndex = order.indexOf(from);
    final toIndex = order.indexOf(to);
    if (fromIndex < 0 || toIndex < 0) return false;
    // Strictly the next step: skipping `available` would let a reward be
    // withdrawn before it cleared.
    return toIndex == fromIndex + 1;
  }
}

extension RewardStatusRules on RewardStatus {
  /// Whether this reward counts toward the driver's spendable balance.
  ///
  /// Pending explicitly does not — the copy deck is emphatic that the UI must
  /// never promise a reward before the backend confirms it, and that
  /// `Pending` always carries its own helper line.
  bool get countsTowardAvailableBalance => this == RewardStatus.available;

  /// Whether this reward counts toward "total earned".
  ///
  /// Transferred and withdrawn rewards were earned and still count; a reversed
  /// reward was not, and must come back out of the total.
  bool get countsTowardTotalEarned =>
      this == RewardStatus.available ||
      this == RewardStatus.transferred ||
      this == RewardStatus.withdrawn;

  /// Whether the status is final.
  bool get isTerminal =>
      this == RewardStatus.withdrawn || this == RewardStatus.reversed;
}
