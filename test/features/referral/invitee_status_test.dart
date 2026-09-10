import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/referral/domain/invitee_status.dart';

/// N-07 (docs/12) — referral-ux-copy-deck.md §8.
void main() {
  DriverInviteeStage driver({
    bool signedUp = true,
    bool verified = true,
    bool wallet = true,
    bool toppedUp = false,
    int? idleDays,
  }) =>
      driverInviteeStage(
        hasSignedUp: signedUp,
        documentsVerified: verified,
        walletActivated: wallet,
        hasToppedUp: toppedUp,
        daysSinceLastTopUp: idleDays,
      );

  group('driver lifecycle', () {
    test('nobody joined yet', () {
      expect(driver(signedUp: false), DriverInviteeStage.inviteSent);
    });

    test('signed up but documents not verified', () {
      expect(driver(verified: false, wallet: false),
          DriverInviteeStage.signedUp);
    });

    test('verified but wallet not activated', () {
      expect(driver(wallet: false), DriverInviteeStage.verified);
    });

    test('wallet activated but no top-up', () {
      expect(driver(), DriverInviteeStage.readyToEarn);
    });

    test('first top-up starts earning', () {
      expect(driver(toppedUp: true, idleDays: 2), DriverInviteeStage.earning);
    });

    test('no top-ups for the inactivity window', () {
      expect(driver(toppedUp: true, idleDays: 30), DriverInviteeStage.inactive);
      expect(driver(toppedUp: true, idleDays: 90), DriverInviteeStage.inactive);
    });

    test('a day short of the window is still earning', () {
      expect(driver(toppedUp: true, idleDays: 29), DriverInviteeStage.earning);
    });

    test('an unknown idle period does not manufacture inactivity', () {
      // Absent data must not be read as "stopped".
      expect(driver(toppedUp: true, idleDays: null),
          DriverInviteeStage.earning);
    });

    test('verification cannot be skipped on the way to ready-to-earn', () {
      // A wallet flagged active without verification is a backend
      // inconsistency; the earlier, more honest stage wins.
      expect(driver(verified: false, wallet: true),
          DriverInviteeStage.signedUp);
    });
  });

  group('the "registered is not earning" rule', () {
    test('only the earning stage earns', () {
      for (final stage in DriverInviteeStage.values) {
        expect(stage.isEarning, stage == DriverInviteeStage.earning,
            reason: '$stage');
      }
    });

    test('every pre-earning stage after signup demands the notice', () {
      // The spec calls this "the single highest-value place for honest copy".
      expect(DriverInviteeStage.signedUp.requiresNotEarningYetNotice, isTrue);
      expect(DriverInviteeStage.verified.requiresNotEarningYetNotice, isTrue);
      expect(DriverInviteeStage.readyToEarn.requiresNotEarningYetNotice, isTrue);
    });

    test('an inactive invitee is not earning, but has earned', () {
      // Their historical total is real and must not display as zero.
      expect(DriverInviteeStage.inactive.isEarning, isFalse);
      expect(DriverInviteeStage.inactive.hasEverEarned, isTrue);
    });

    test('nothing before the first top-up has ever earned', () {
      expect(DriverInviteeStage.inviteSent.hasEverEarned, isFalse);
      expect(DriverInviteeStage.signedUp.hasEverEarned, isFalse);
      expect(DriverInviteeStage.verified.hasEverEarned, isFalse);
      expect(DriverInviteeStage.readyToEarn.hasEverEarned, isFalse);
    });
  });

  group('passenger lifecycle', () {
    test('four stages, no verification or wallet step', () {
      expect(
        passengerInviteeStage(hasSignedUp: false, hasCompletedTrip: false),
        PassengerInviteeStage.inviteSent,
      );
      expect(
        passengerInviteeStage(hasSignedUp: true, hasCompletedTrip: false),
        PassengerInviteeStage.signedUp,
      );
      expect(
        passengerInviteeStage(
            hasSignedUp: true, hasCompletedTrip: true, daysSinceLastTrip: 1),
        PassengerInviteeStage.earning,
      );
      expect(
        passengerInviteeStage(
            hasSignedUp: true, hasCompletedTrip: true, daysSinceLastTrip: 40),
        PassengerInviteeStage.inactive,
      );
    });

    test('signed-up passengers also demand the notice', () {
      expect(PassengerInviteeStage.signedUp.requiresNotEarningYetNotice, isTrue);
    });
  });
}
