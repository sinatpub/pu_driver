import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/referral/domain/invite_attribution.dart';

/// N-02 (docs/12) — invites and attribution. Decides who earns from whom, so
/// money territory per `.agent/RULES.md`.
void main() {
  group('the invite message follows the joiner-reward answer', () {
    test('"we both start earning" only if the invited person gets something',
        () {
      expect(driverInviteMessage(JoinerReward.invitedPersonRewarded),
          InviteMessageVariant.weBothStartEarning);
    });

    test('otherwise the neutral message, which promises nothing', () {
      expect(driverInviteMessage(JoinerReward.noJoinerReward),
          InviteMessageVariant.neutral);
    });

    test('the promotional variant does not exist', () {
      expect(InviteMessageVariant.values, hasLength(2));
    });
  });

  group('code entry', () {
    InviteCodeCheck check(
      String entered, {
      String? ownCode,
      bool alreadyHasInviter = false,
      bool isSigningUp = true,
      LateAttribution late = LateAttribution.signupOnly,
    }) =>
        checkInviteCode(
          entered: entered,
          ownCode: ownCode,
          alreadyHasInviter: alreadyHasInviter,
          isSigningUp: isSigningUp,
          lateAttribution: late,
        );

    test('a blank code means continue without one', () {
      expect(check(''), InviteCodeCheck.noCode);
      expect(check('   '), InviteCodeCheck.noCode);
    });

    test('a plausible code at signup goes to the server', () {
      expect(check('SOK123'), InviteCodeCheck.needsServerCheck);
    });

    test('surrounding whitespace from a pasted message is ignored', () {
      expect(normalizeInviteCode('  SOK123\n'), 'SOK123');
      expect(check(' SOK123 ', ownCode: 'SOK123'), InviteCodeCheck.ownCode);
    });

    test('case is not folded, because the format is unspecified', () {
      expect(normalizeInviteCode('sok123'), 'sok123');
      expect(
          check('sok123', ownCode: 'SOK123'), InviteCodeCheck.needsServerCheck);
    });

    test('your own code is refused', () {
      expect(
          check('SOK123',
              ownCode: 'SOK123',
              isSigningUp: false,
              late: LateAttribution.allowedAfterSignup),
          InviteCodeCheck.ownCode);
    });

    test('a blank own code matches nothing', () {
      expect(check('X', ownCode: '  '), InviteCodeCheck.needsServerCheck);
    });

    test('an account with an inviter hears that first', () {
      expect(
          check('SOK123',
              ownCode: 'SOK123', alreadyHasInviter: true, isSigningUp: false),
          InviteCodeCheck.alreadyLinked);
    });

    test('signup-only: a code after signup is refused', () {
      expect(check('SOK123', isSigningUp: false),
          InviteCodeCheck.afterSignupWindow);
    });

    test('allowed after signup: the same code goes to the server', () {
      expect(
          check('SOK123',
              isSigningUp: false, late: LateAttribution.allowedAfterSignup),
          InviteCodeCheck.needsServerCheck);
    });

    test('the window only applies after signup', () {
      expect(check('SOK123', late: LateAttribution.signupOnly),
          InviteCodeCheck.needsServerCheck);
    });
  });

  group('attribution', () {
    const d1 = Invitee(InviteeKind.driver, 1);
    const d2 = Invitee(InviteeKind.driver, 2);
    const d3 = Invitee(InviteeKind.driver, 3);
    const p2 = Invitee(InviteeKind.passenger, 2);

    test('a fresh invitee may be attributed', () {
      expect(
          refuseAttribution(invitee: d2, inviterDriverId: 1, attributions: {}),
          isNull);
    });

    test('a driver cannot invite themselves', () {
      expect(
          refuseAttribution(invitee: d1, inviterDriverId: 1, attributions: {}),
          AttributionRefusal.selfReferral);
    });

    test('a passenger sharing a driver\'s id is a different person', () {
      expect(
          refuseAttribution(invitee: p2, inviterDriverId: 2, attributions: {}),
          isNull);
      expect(p2 == d2, isFalse);
    });

    test('one inviter per account, permanently', () {
      expect(
          refuseAttribution(
              invitee: d2, inviterDriverId: 3, attributions: {d2: 1}),
          AttributionRefusal.alreadyLinked);
    });

    test('a direct loop is refused', () {
      // 1 invited 2; 1 now tries to join as 2's invitee.
      expect(
          refuseAttribution(
              invitee: d1, inviterDriverId: 2, attributions: {d2: 1}),
          AttributionRefusal.circular);
    });

    test('a longer loop is refused', () {
      // 1 → 2 → 3; 1 tries to join as 3's invitee.
      expect(
          refuseAttribution(
              invitee: d1, inviterDriverId: 3, attributions: {d2: 1, d3: 2}),
          AttributionRefusal.circular);
    });

    test('a chain that does not come back is fine', () {
      // 1 → 2; 4 joins as 2's invitee.
      expect(
          refuseAttribution(
              invitee: const Invitee(InviteeKind.driver, 4),
              inviterDriverId: 2,
              attributions: {d2: 1}),
          isNull);
    });

    test('a passenger cannot close a loop', () {
      expect(
          refuseAttribution(
              invitee: const Invitee(InviteeKind.passenger, 1),
              inviterDriverId: 2,
              attributions: {d2: 1}),
          isNull);
    });

    test('a loop already in the data does not hang the check', () {
      expect(
          refuseAttribution(
              invitee: const Invitee(InviteeKind.driver, 9),
              inviterDriverId: 2,
              attributions: {d2: 3, d3: 2}),
          isNull);
    });
  });

  group('the direct-only rule', () {
    const d2 = Invitee(InviteeKind.driver, 2);
    const d3 = Invitee(InviteeKind.driver, 3);
    const p5 = Invitee(InviteeKind.passenger, 5);
    final attributions = {d2: 1, d3: 2, p5: 1};

    test('you earn from people you invited yourself', () {
      expect(
          earnsFrom(driverId: 1, activityOwner: d2, attributions: attributions),
          isTrue);
      expect(
          earnsFrom(driverId: 1, activityOwner: p5, attributions: attributions),
          isTrue);
    });

    test('not from the people they invite', () {
      // 1 invited 2, 2 invited 3: 3's activity earns 1 nothing.
      expect(
          earnsFrom(driverId: 1, activityOwner: d3, attributions: attributions),
          isFalse);
      expect(
          earnsFrom(driverId: 2, activityOwner: d3, attributions: attributions),
          isTrue);
    });

    test('not from strangers', () {
      expect(
          earnsFrom(
              driverId: 1,
              activityOwner: const Invitee(InviteeKind.passenger, 99),
              attributions: attributions),
          isFalse);
    });

    test('never from your own activity, even with bad data', () {
      const d1 = Invitee(InviteeKind.driver, 1);
      expect(earnsFrom(driverId: 1, activityOwner: d1, attributions: {d1: 1}),
          isFalse);
    });
  });
}
