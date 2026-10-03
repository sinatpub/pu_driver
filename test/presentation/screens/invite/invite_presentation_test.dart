import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';

/// DD-45 — the invite and reward rules. Rewards are the driver's money, so
/// the sums and the ordering are pinned here.
void main() {
  group('parseInviteCode', () {
    test('a bare code, in any case, with spaces around it', () {
      expect(parseInviteCode('PU7K2M'), 'PU7K2M');
      expect(parseInviteCode('  pu7k2m '), 'PU7K2M');
    });

    test('a link: the last path segment', () {
      expect(parseInviteCode('https://putaxi.example/i/PU7K2M'), 'PU7K2M');
      expect(parseInviteCode('https://putaxi.example/i/pu7k2m/'), 'PU7K2M');
    });

    test('a link: the code parameter wins over the path', () {
      expect(
        parseInviteCode('https://putaxi.example/join?code=sokha88'),
        'SOKHA88',
      );
    });

    test('nothing, or something that is not an invite', () {
      expect(parseInviteCode(null), isNull);
      expect(parseInviteCode(''), isNull);
      expect(parseInviteCode('abc'), isNull, reason: 'too short');
      expect(parseInviteCode('ABCDEFGHIJKLM'), isNull, reason: 'too long');
      expect(parseInviteCode('PU 7K2M'), isNull);
      expect(parseInviteCode('https://putaxi.example'), isNull);
      expect(parseInviteCode('https://putaxi.example/about-us'), isNull);
      expect(parseInviteCode('WIFI:S:Cafe;T:WPA;P:secret;;'), isNull);
    });
  });

  group('inviteQrData', () {
    test('the link when there is one, else the code, else nothing', () {
      expect(
        inviteQrData(const ReferralModel(code: 'PU7K2M', link: 'https://x/i')),
        'https://x/i',
      );
      expect(inviteQrData(const ReferralModel(code: 'PU7K2M')), 'PU7K2M');
      expect(inviteQrData(const ReferralModel()), isNull);
      expect(inviteQrData(null), isNull);
    });
  });

  const List<ReferralReward> rewards = <ReferralReward>[
    ReferralReward(
        id: 1, role: 'driver', amount: 1000, createdAt: '2026-09-30 09:14:00'),
    ReferralReward(
        id: 2,
        role: 'passenger',
        amount: 120,
        createdAt: '2026-10-01 08:14:00'),
    ReferralReward(
        id: 3, role: 'Driver', amount: 2500, createdAt: '2026-09-23 11:14:00'),
    ReferralReward(id: 4, role: 'passenger', amount: null),
    ReferralReward(
        id: 5, role: 'passenger', amount: 90, createdAt: '2026-09-30 18:14:00'),
  ];

  group('earned', () {
    test('the total, and the share from each kind of person', () {
      expect(totalEarned(rewards), 3710);
      expect(earnedFrom(rewards, InviteeRole.driver), 3500);
      expect(earnedFrom(rewards, InviteeRole.passenger), 210);
    });

    test('the two shares add up to the total', () {
      expect(
        earnedFrom(rewards, InviteeRole.driver) +
            earnedFrom(rewards, InviteeRole.passenger),
        totalEarned(rewards),
      );
    });

    test('nothing earned is zero, not null', () {
      expect(totalEarned(const <ReferralReward>[]), 0);
    });
  });

  const List<RewardTransfer> transfers = <RewardTransfer>[
    RewardTransfer(id: 1, amount: 2500, createdAt: '2026-09-25 10:00:00'),
    RewardTransfer(id: 2, amount: 1000, createdAt: '2026-09-30 12:00:00'),
  ];

  group('reward balance (DD-48)', () {
    test('what was moved to the wallet', () {
      expect(totalTransferred(transfers), 3500);
      expect(totalTransferred(const <RewardTransfer>[]), 0);
    });

    test('the server\'s figure when it sends one', () {
      expect(
        rewardBalance(const ReferralModel(
            rewardBalance: 42, rewards: rewards, transfers: transfers)),
        42,
      );
    });

    test('else earned less moved, and never below zero', () {
      expect(
        rewardBalance(
            const ReferralModel(rewards: rewards, transfers: transfers)),
        210,
      );
      expect(
        rewardBalance(const ReferralModel(transfers: transfers)),
        0,
      );
      expect(rewardBalance(const ReferralModel(rewardBalance: -5)), 0);
      expect(rewardBalance(null), 0);
    });
  });

  group('transferPreview (DD-48)', () {
    test('no debt: all of it reaches the balance', () {
      final TransferPreview p =
          transferPreview(amount: 5160, balance: 85400, debt: null);
      expect(p.toDebt, 0);
      expect(p.toBalance, 5160);
      expect(p.debtLeft, 0);
      expect(p.balanceAfter, 90560);
    });

    test('a debt smaller than the transfer is paid first', () {
      final TransferPreview p =
          transferPreview(amount: 5160, balance: 0, debt: 5000);
      expect(p.toDebt, 5000);
      expect(p.toBalance, 160);
      expect(p.debtLeft, 0);
      expect(p.balanceAfter, 160);
    });

    test('a debt larger than the transfer takes all of it', () {
      final TransferPreview p =
          transferPreview(amount: 5160, balance: 0, debt: 8000);
      expect(p.toDebt, 5160);
      expect(p.toBalance, 0);
      expect(p.debtLeft, 2840);
      expect(p.balanceAfter, 0);
    });

    test('an unknown balance stays unknown', () {
      expect(
        transferPreview(amount: 5160, balance: null, debt: null).balanceAfter,
        isNull,
      );
    });
  });

  group('the typed transfer amount (DD-49)', () {
    test('riel: whole numbers above zero only', () {
      expect(parseTransferAmount('2000', 'KHR'), 2000);
      expect(parseTransferAmount(' 2,000 ', 'KHR'), 2000);
      expect(parseTransferAmount('', 'KHR'), isNull);
      expect(parseTransferAmount('0', 'KHR'), isNull);
      expect(parseTransferAmount('-5', 'KHR'), isNull);
      expect(parseTransferAmount('12.5', 'KHR'), isNull);
      expect(parseTransferAmount('abc', 'KHR'), isNull);
    });

    test('other currencies: up to two decimals', () {
      expect(parseTransferAmount('12.5', 'USD'), 12.5);
      expect(parseTransferAmount('12.50', 'USD'), 12.5);
      expect(parseTransferAmount('0.01', 'USD'), 0.01);
      expect(parseTransferAmount('12.505', 'USD'), isNull);
    });

    test('"All" fills in text that parses back to the same amount', () {
      expect(transferAmountText(5160, 'KHR'), '5160');
      expect(transferAmountText(12.5, 'USD'), '12.50');
      expect(
        parseTransferAmount(transferAmountText(5160, 'KHR'), 'KHR'),
        5160,
      );
    });

    test('nothing typed waits; more than the balance is refused', () {
      expect(checkTransferAmount(null, 5160), TransferAmountCheck.empty);
      expect(checkTransferAmount(0, 5160), TransferAmountCheck.empty);
      expect(checkTransferAmount(1, 5160), TransferAmountCheck.ok);
      expect(checkTransferAmount(5160, 5160), TransferAmountCheck.ok);
      expect(checkTransferAmount(5161, 5160), TransferAmountCheck.tooMuch);
    });

    test('a part transfer adds only that part to the balance', () {
      final TransferPreview p =
          transferPreview(amount: 2000, balance: 85400, debt: null);
      expect(p.toBalance, 2000);
      expect(p.balanceAfter, 87400);
    });
  });

  group('reward history', () {
    String label(RewardEntry e) => switch (e) {
          EarnedEntry(:final ReferralReward reward) => 'r${reward.id}',
          TransferEntry(:final RewardTransfer transfer) => 't${transfer.id}',
        };

    test('rewards and transfers together, newest first, undated last', () {
      expect(
        rewardEntries(rewards, transfers).map(label),
        <String>['r2', 'r5', 't2', 'r1', 't1', 'r3', 'r4'],
      );
    });

    test('a header before the first entry of each day', () {
      final List<RewardRow> rows =
          rewardRows(rewardEntries(rewards, const <RewardTransfer>[]));
      expect(
        rows.map((RewardRow r) => switch (r) {
              RewardDayHeader(:final DateTime day) => 'day ${day.day}',
              RewardItemRow(:final RewardEntry entry) => label(entry),
            }),
        <String>['day 1', 'r2', 'day 30', 'r5', 'r1', 'day 23', 'r3', 'r4'],
      );
    });
  });

  group('invited people', () {
    const List<Invitee> people = <Invitee>[
      Invitee(id: 1, role: 'driver', joinedAt: '2026-09-10 10:00:00'),
      Invitee(id: 2, role: 'passenger', joinedAt: '2026-09-16 10:00:00'),
      Invitee(id: 3, role: 'driver', joinedAt: '2026-09-22 10:00:00'),
      Invitee(id: 4, role: null),
    ];

    test('everyone, newest first', () {
      expect(
          inviteesOf(people, null).map((Invitee i) => i.id), <int>[3, 2, 1, 4]);
    });

    test('one kind of person only', () {
      expect(inviteesOf(people, InviteeRole.driver).map((Invitee i) => i.id),
          <int>[3, 1]);
      expect(inviteesOf(people, InviteeRole.passenger).map((Invitee i) => i.id),
          <int>[2]);
    });
  });

  group('ReferralModel.fromJson', () {
    test('reads the proposed payload', () {
      final ReferralModel m = ReferralModel.fromJson(<String, dynamic>{
        'status': true,
        'data': <String, dynamic>{
          'code': 'PU7K2M',
          'link': 'https://putaxi.example/i/PU7K2M',
          'currency': 'KHR',
          'driver_top_up_rate': 1,
          'passenger_commission_rate': '10',
          'invitees': <dynamic>[
            <String, dynamic>{'id': 1, 'name': 'Sokha', 'role': 'driver'},
          ],
          'rewards': <dynamic>[
            <String, dynamic>{
              'id': 1,
              'amount': '1,000',
              'base_amount': 100000
            },
          ],
        },
      });
      expect(m.code, 'PU7K2M');
      expect(m.passengerCommissionRate, 10);
      expect(m.invitees.single.name, 'Sokha');
      expect(m.rewards.single.amount, 1000);
      expect(m.rewards.single.baseAmount, 100000);
      expect(m.rewardBalance, isNull);
      expect(m.transfers, isEmpty);
    });

    test('an empty or malformed payload is an empty model, not a throw', () {
      expect(ReferralModel.fromJson(null).code, isNull);
      expect(ReferralModel.fromJson(<String, dynamic>{'data': 'x'}).rewards,
          isEmpty);
      expect(
        ReferralModel.fromJson(<String, dynamic>{
          'data': <String, dynamic>{
            'invitees': null,
            'rewards': <dynamic>[1]
          },
        }).rewards,
        isEmpty,
      );
    });
  });

  test('inviteShortDate leaves the year off for this year only', () {
    final DateTime now = DateTime(2026, 10, 1);
    expect(inviteShortDate(DateTime(2026, 9, 12), now: now), '12 Sep');
    expect(inviteShortDate(DateTime(2025, 9, 12), now: now), '12 Sep 2025');
  });
}
