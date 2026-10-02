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

  group('rewards list', () {
    test('newest first, with an undated one last', () {
      expect(
        sortedRewards(rewards).map((ReferralReward r) => r.id),
        <int>[2, 5, 1, 3, 4],
      );
    });

    test('a header before the first reward of each day', () {
      final List<RewardRow> rows = rewardRows(sortedRewards(rewards));
      expect(
        rows.map((RewardRow r) => switch (r) {
              RewardDayHeader(:final DateTime day) => 'day ${day.day}',
              RewardItemRow(:final ReferralReward reward) => '${reward.id}',
            }),
        <String>['day 1', '2', 'day 30', '5', '1', 'day 23', '3', '4'],
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
