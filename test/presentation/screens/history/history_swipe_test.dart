import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/repository/history_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/history/logic.dart';
import 'package:pu_taxi_driver/presentation/screens/history/view.dart';

import '../../../helpers/localized_host.dart';

/// DD-41 — the two history tabs are pages: swipe between them, or tap a tab.
class _FakeRepository implements HistoryRepository {
  final List<int> statusesFetched = <int>[];

  @override
  Future<Result<HistoryDriveInfoModel>> getHistory({
    required int page,
    required int status,
  }) async {
    if (page == 1) statusesFetched.add(status);
    return Result<HistoryDriveInfoModel>.ok(
      HistoryDriveInfoModel(
        data: page > 1
            ? <DataHistory>[]
            : <DataHistory>[
                DataHistory.fromJson(<String, dynamic>{
                  'id': status,
                  'start_time': '2026-09-12 09:30:00',
                  'start_address': 'St. 271, Phnom Penh',
                  'end_address': 'Sisowath Quay',
                  'status': status,
                  'status_name': status == 4 ? 'completed' : 'cancelled',
                  'passenger': <String, dynamic>{
                    'name': status == 4 ? 'Mey Lin' : 'Sok Dara',
                  },
                  'payment': <String, dynamic>{
                    'invoice_id': 7700 + status,
                    'distance': '3.5 km',
                    'duration': '14 mins',
                    'amount': '7600',
                    'payment_method': 'Cash',
                  },
                }),
              ],
      ),
    );
  }
}

void main() {
  late _FakeRepository repo;
  late HistoryLogic logic;

  setUp(() {
    repo = _FakeRepository();
    logic = Get.put<HistoryLogic>(HistoryLogic(repo));
  });

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester t) async {
    await t.pumpWidget(localizedHostPage(const Scaffold(body: HistoryPage())));
    await t.pumpAndSettle();
  }

  testWidgets('opens on Completed; Cancelled is not fetched yet',
      (WidgetTester t) async {
    await pumpPage(t);

    expect(find.text('Mey Lin · #7704'), findsOneWidget);
    expect(repo.statusesFetched, <int>[4]);
  });

  testWidgets('a swipe left shows Cancelled and loads it once',
      (WidgetTester t) async {
    await pumpPage(t);

    await t.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await t.pumpAndSettle();

    expect(logic.state.indexActive.value, 1);
    expect(find.text('Sok Dara · #7705'), findsOneWidget);
    expect(repo.statusesFetched, <int>[4, 5]);

    // And back: the completed list is still there, nothing refetched.
    await t.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await t.pumpAndSettle();

    expect(logic.state.indexActive.value, 0);
    expect(find.text('Mey Lin · #7704'), findsOneWidget);
    expect(repo.statusesFetched, <int>[4, 5]);
  });

  testWidgets('tapping a tab slides to its page', (WidgetTester t) async {
    await pumpPage(t);

    await t.tap(find.text('Cancelled'));
    await t.pumpAndSettle();

    expect(logic.state.indexActive.value, 1);
    expect(find.text('Sok Dara · #7705'), findsOneWidget);
  });
}
