import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/data/services/item_record_repository.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/state/item_form_controller.dart';

void main() {
  final ItemRecord draft = ItemRecord(
    name: 'Guarda-chuva',
    description: 'Preto, cabo vermelho.',
    location: 'Biblioteca',
    status: ItemStatus.lost,
  );

  final ItemRecord confirmed = ItemRecord(
    id: 'uuid-1',
    name: 'Guarda-chuva',
    description: 'Preto, cabo vermelho.',
    location: 'Biblioteca',
    status: ItemStatus.lost,
    createdAt: DateTime.utc(2026, 11, 1),
  );

  test('transita idle → submitting → success e sinaliza refresh', () async {
    final _FakeRepository repo = _FakeRepository(onCreate: (_) async => confirmed);
    final ItemFormController ctrl = ItemFormController(repo);
    final List<ItemFormState> states = [];
    ctrl.addListener(() => states.add(ctrl.state));

    await ctrl.submit(draft);

    expect(repo.createCalls, 1);
    expect(ctrl.state, ItemFormState.success);
    expect(ctrl.needsListRefresh, isTrue);
    expect(ctrl.error, isNull);
    expect(states, [ItemFormState.submitting, ItemFormState.success]);
  });

  test('transita idle → submitting → failure e preserva erro', () async {
    final StateError boom = StateError('sem rede');
    final _FakeRepository repo = _FakeRepository(onCreate: (_) async => throw boom);
    final ItemFormController ctrl = ItemFormController(repo);

    await ctrl.submit(draft);

    expect(ctrl.state, ItemFormState.failure);
    expect(ctrl.error, same(boom));
    expect(ctrl.needsListRefresh, isFalse);
  });

  test('bloqueia segundo envio enquanto submitting', () async {
    bool resolved = false;
    final _FakeRepository repo = _FakeRepository(
      onCreate: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        resolved = true;
        return confirmed;
      },
    );
    final ItemFormController ctrl = ItemFormController(repo);

    // Dispara sem await — deixa em submitting
    final Future<void> first = ctrl.submit(draft);
    await ctrl.submit(draft); // segunda chamada deve ser ignorada

    await first;

    expect(repo.createCalls, 1); // apenas uma chamada ao repositório
    expect(resolved, isTrue);
  });

  test('acknowledgeSuccess retorna a idle e limpa needsListRefresh', () async {
    final _FakeRepository repo = _FakeRepository(onCreate: (_) async => confirmed);
    final ItemFormController ctrl = ItemFormController(repo);

    await ctrl.submit(draft);
    expect(ctrl.state, ItemFormState.success);

    ctrl.acknowledgeSuccess();

    expect(ctrl.state, ItemFormState.idle);
    expect(ctrl.needsListRefresh, isFalse);
  });

  test('permite retry após failure e conclui com success', () async {
    int attempt = 0;
    final _FakeRepository repo = _FakeRepository(
      onCreate: (_) async {
        attempt++;
        if (attempt == 1) throw StateError('offline');
        return confirmed;
      },
    );
    final ItemFormController ctrl = ItemFormController(repo);

    await ctrl.submit(draft);
    expect(ctrl.state, ItemFormState.failure);
    expect(ctrl.canRetry, isTrue);
    expect(ctrl.lastFailedDraft, same(draft));
    expect(ctrl.errorMessage, 'Não foi possível cadastrar o objeto. Tente novamente.');

    await ctrl.retry();

    expect(repo.createCalls, 2);
    expect(ctrl.state, ItemFormState.success);
    expect(ctrl.canRetry, isFalse);
    expect(ctrl.lastFailedDraft, isNull);
    expect(ctrl.error, isNull);
    expect(ctrl.errorMessage, isNull);
  });

  test('retry ignora chamadas fora do estado failure para evitar duplicação', () async {
    final _FakeRepository repo = _FakeRepository(onCreate: (_) async => confirmed);
    final ItemFormController ctrl = ItemFormController(repo);

    // Em idle, retry não deve chamar o repositório
    await ctrl.retry();
    expect(repo.createCalls, 0);

    // Após success, retry também não deve criar duplicata
    await ctrl.submit(draft);
    expect(ctrl.state, ItemFormState.success);
    await ctrl.retry();
    expect(repo.createCalls, 1);
  });

  test('reset volta a idle e limpa o erro', () async {
    final _FakeRepository repo = _FakeRepository(onCreate: (_) async => throw StateError('x'));
    final ItemFormController ctrl = ItemFormController(repo);

    await ctrl.submit(draft);
    expect(ctrl.state, ItemFormState.failure);

    ctrl.reset();

    expect(ctrl.state, ItemFormState.idle);
    expect(ctrl.error, isNull);
  });

  test('reset não age durante submitting', () async {
    final _FakeRepository repo = _FakeRepository(
      onCreate: (_) => Future.delayed(const Duration(milliseconds: 50), () => confirmed),
    );
    final ItemFormController ctrl = ItemFormController(repo);

    final Future<void> op = ctrl.submit(draft);
    ctrl.reset(); // chamado enquanto submitting — deve ser ignorado
    await op;

    expect(ctrl.state, ItemFormState.success); // operação concluiu normalmente
  });
}

final class _FakeRepository implements ItemRecordRepository {
  _FakeRepository({required this.onCreate});

  final Future<ItemRecord> Function(ItemRecord) onCreate;
  int createCalls = 0;

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) {
    createCalls++;
    return onCreate(draft);
  }

  @override
  Future<List<ItemRecord>> listItemRecords() => throw UnimplementedError();
}
