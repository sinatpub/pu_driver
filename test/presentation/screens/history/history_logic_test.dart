import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/repository/history_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/history/logic.dart';

/// DD-41 — each tab keeps its own list; nothing is refetched on a switch.
class _FakeRepository implements HistoryRepository {
  final List<(int page, int status)> calls = <(int, int)>[];

  @override
  Future<Result<HistoryDriveInfoModel>> getHistory({
    required int page,
    required int status,
  }) async {
    calls.add((page, status));
    return Result<HistoryDriveInfoModel>.ok(
      HistoryDriveInfoModel(
        data: page == 1
            ? <DataHistory>[
                DataHistory.fromJson(<String, dynamic>{
                  'id': status * 10,
                  'status': status,
                }),
              ]
            : <DataHistory>[],
      ),
    );
  }
}

void main() {
  test('the completed list loads with the screen; cancelled waits', () async {
    final _FakeRepository repo = _FakeRepository();
    final HistoryLogic logic = HistoryLogic(repo)..onInit();
    await Future<void>.delayed(Duration.zero);

    expect(repo.calls, <(int, int)>[(1, 4)]);
    expect(logic.lists[0].items, hasLength(1));
    expect(logic.lists[1].items, isEmpty);
  });

  test('the cancelled list loads the first time its tab shows', () async {
    final _FakeRepository repo = _FakeRepository();
    final HistoryLogic logic = HistoryLogic(repo)..onInit();
    await Future<void>.delayed(Duration.zero);

    logic.switchTab(1);
    await Future<void>.delayed(Duration.zero);

    expect(logic.state.indexActive.value, 1);
    expect(repo.calls, <(int, int)>[(1, 4), (1, 5)]);
    expect(logic.lists[1].items.single.status, 5);
  });

  test('switching back and forth refetches nothing', () async {
    final _FakeRepository repo = _FakeRepository();
    final HistoryLogic logic = HistoryLogic(repo)..onInit();
    await Future<void>.delayed(Duration.zero);

    logic.switchTab(1);
    await Future<void>.delayed(Duration.zero);
    logic.switchTab(0);
    logic.switchTab(1);
    logic.switchTab(0);
    await Future<void>.delayed(Duration.zero);

    expect(repo.calls, hasLength(2));
    expect(logic.lists[0].items, hasLength(1));
  });

  test('pull-to-refresh reloads only that tab', () async {
    final _FakeRepository repo = _FakeRepository();
    final HistoryLogic logic = HistoryLogic(repo)..onInit();
    await Future<void>.delayed(Duration.zero);

    await logic.lists[0].reload();

    expect(repo.calls, <(int, int)>[(1, 4), (1, 4)]);
  });
}
