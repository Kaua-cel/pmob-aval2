import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/data/services/item_record_repository.dart';
import 'package:pmob_aval2/data/services/supabase_configuration.dart';
import 'package:pmob_aval2/data/services/supabase_item_record_repository.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/models/item_record_mapper.dart';

void main() {
  group('SupabaseItemRecordRepository', () {
    final ItemRecord draft = ItemRecord(
      id: 'client-must-not-send-this',
      name: 'Blue backpack',
      description: 'Blue backpack with a mathematics notebook.',
      location: 'Library',
      status: ItemStatus.found,
      createdAt: DateTime.utc(2026, 10, 29),
    );

    test('exposes asynchronous list and create operations', () async {
      final _FakeRemoteDataSource remote = _FakeRemoteDataSource(
        rows: [_remoteRow(id: 'record-1')],
        createdRow: _remoteRow(id: 'record-2'),
      );
      final ItemRecordRepository repository = SupabaseItemRecordRepository(remote);

      await expectLater(repository.listItemRecords(), completion(hasLength(1)));
      await expectLater(repository.createItemRecord(draft), completion(isA<ItemRecord>()));
    });

    test('sends only fields accepted during creation', () async {
      final _FakeRemoteDataSource remote = _FakeRemoteDataSource(createdRow: _remoteRow());
      final ItemRecordRepository repository = SupabaseItemRecordRepository(remote);

      await repository.createItemRecord(draft);

      expect(remote.lastInsertPayload, {
        'name': 'Blue backpack',
        'description': 'Blue backpack with a mathematics notebook.',
        'location': 'Library',
        'status': 'found',
      });
      expect(remote.lastInsertPayload, isNot(contains('id')));
      expect(remote.lastInsertPayload, isNot(contains('created_at')));
    });

    test('maps created_at into UTC createdAt and preserves metadata', () async {
      final _FakeRemoteDataSource remote = _FakeRemoteDataSource(
        rows: [_remoteRow(id: 'record-42', createdAt: '2026-10-29T14:30:15.123Z', status: 'lost')],
      );
      final ItemRecordRepository repository = SupabaseItemRecordRepository(remote);

      final ItemRecord record = (await repository.listItemRecords()).single;

      expect(record.id, 'record-42');
      expect(record.status, ItemStatus.lost);
      expect(record.createdAt, DateTime.utc(2026, 10, 29, 14, 30, 15, 123));
    });

    test('requests records in descending creation order', () async {
      final _FakeRemoteDataSource remote = _FakeRemoteDataSource(rows: [_remoteRow()]);
      final ItemRecordRepository repository = SupabaseItemRecordRepository(remote);

      await repository.listItemRecords();

      expect(remote.listRequested, isTrue);
    });

    test('does not present invalid data or remote failures as success', () async {
      final ItemRecordRepository invalidRepository = SupabaseItemRecordRepository(
        _FakeRemoteDataSource(
          rows: [
            <String, Object?>{'id': 'missing-fields'},
          ],
        ),
      );
      final ItemRecordRepository failingRepository = SupabaseItemRecordRepository(
        _FakeRemoteDataSource(listError: StateError('remote unavailable')),
      );

      expect(invalidRepository.listItemRecords(), throwsA(isA<FormatException>()));
      expect(failingRepository.listItemRecords(), throwsStateError);
    });
  });

  group('SupabaseConfiguration', () {
    test('rejects missing mandatory public settings before a network request', () {
      expect(
        () => SupabaseConfiguration(url: '', anonKey: 'public-anon-key'),
        throwsA(isA<SupabaseConfigurationException>()),
      );
      expect(
        () => SupabaseConfiguration(url: 'https://project.supabase.co', anonKey: ''),
        throwsA(isA<SupabaseConfigurationException>()),
      );
    });

    test('rejects a URL without an HTTP(S) host', () {
      expect(
        () => SupabaseConfiguration(url: 'ftp://project.supabase.co', anonKey: 'public-anon-key'),
        throwsA(isA<SupabaseConfigurationException>()),
      );
      expect(
        () => SupabaseConfiguration(url: 'https://', anonKey: 'public-anon-key'),
        throwsA(isA<SupabaseConfigurationException>()),
      );
    });
  });
}

final class _FakeRemoteDataSource implements ItemRecordRemoteDataSource {
  _FakeRemoteDataSource({this.rows = const [], ItemRecordStorage? createdRow, this.listError})
    : _createdRow = createdRow ?? _remoteRow();

  final List<ItemRecordStorage> rows;
  final ItemRecordStorage _createdRow;
  final Object? listError;
  bool listRequested = false;
  ItemRecordStorage? lastInsertPayload;

  @override
  Future<List<ItemRecordStorage>> listNewestFirst() async {
    listRequested = true;
    if (listError case final Object error) {
      throw error;
    }
    return rows;
  }

  @override
  Future<ItemRecordStorage> insertItemRecord(ItemRecordStorage payload) async {
    lastInsertPayload = Map<String, Object?>.from(payload);
    return _createdRow;
  }
}

ItemRecordStorage _remoteRow({
  String id = 'record-1',
  String createdAt = '2026-10-29T14:30:15.123Z',
  String status = 'found',
}) {
  return {
    'id': id,
    'name': 'Blue backpack',
    'description': 'Blue backpack with a mathematics notebook.',
    'location': 'Library',
    'status': status,
    'created_at': createdAt,
  };
}
