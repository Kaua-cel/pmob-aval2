import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/data/services/item_record_repository.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/state/item_list_controller.dart';

void main() {
  final ItemRecord record = ItemRecord(
    id: 'record-1',
    name: 'Guarda-chuva',
    description: 'Guarda-chuva preto.',
    location: 'Biblioteca',
    status: ItemStatus.found,
    createdAt: DateTime.utc(2026, 10, 31),
  );

  test('stores records and notifies loading then success', () async {
    final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
      onList: () async => <ItemRecord>[record],
    );
    final ItemListController controller = ItemListController(repository);
    final List<ItemListState> observedStates = <ItemListState>[];
    controller.addListener(() => observedStates.add(controller.state));

    await controller.load();

    expect(repository.listCalls, 1);
    expect(controller.state, ItemListState.success);
    expect(controller.records, <ItemRecord>[record]);
    expect(observedStates, <ItemListState>[ItemListState.loading, ItemListState.success]);
  });

  test('allows a new remote request after a failure', () async {
    var attempt = 0;
    final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
      onList: () async {
        attempt++;
        if (attempt == 1) {
          throw StateError('offline');
        }
        return <ItemRecord>[record];
      },
    );
    final ItemListController controller = ItemListController(repository);

    await controller.load();

    expect(controller.state, ItemListState.failure);
    expect(controller.error, isA<StateError>());

    await controller.load();

    expect(repository.listCalls, 2);
    expect(controller.state, ItemListState.success);
    expect(controller.error, isNull);
    expect(controller.records, <ItemRecord>[record]);
  });
}

final class _FakeItemRecordRepository implements ItemRecordRepository {
  _FakeItemRecordRepository({required this.onList});

  final Future<List<ItemRecord>> Function() onList;
  int listCalls = 0;

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItemRecord>> listItemRecords() {
    listCalls++;
    return onList();
  }
}
