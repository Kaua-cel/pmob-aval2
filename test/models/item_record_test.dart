import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/models/item_record_mapper.dart';

void main() {
  group('ItemRecordMapper', () {
    const String itemId = 'record-42';
    final DateTime createdAt = DateTime.utc(2026, 10, 29, 14, 30, 15, 123);
    final ItemRecord record = ItemRecord(
      id: itemId,
      name: 'Blue backpack',
      description: 'Blue backpack with a mathematics notebook.',
      location: 'Library',
      status: ItemStatus.found,
      createdAt: createdAt,
    );

    test('serializes every storage field', () {
      expect(ItemRecordMapper.toStorage(record), {
        'id': itemId,
        'name': 'Blue backpack',
        'description': 'Blue backpack with a mathematics notebook.',
        'location': 'Library',
        'status': 'found',
        'createdAt': '2026-10-29T14:30:15.123Z',
      });
    });

    test('reconstructs a persisted record', () {
      final ItemRecord restored = ItemRecordMapper.fromStorage({
        'id': itemId,
        'name': 'Blue backpack',
        'description': 'Blue backpack with a mathematics notebook.',
        'location': 'Library',
        'status': 'found',
        'createdAt': '2026-10-29T14:30:15.123Z',
      });

      expect(restored.id, itemId);
      expect(restored.name, 'Blue backpack');
      expect(restored.description, 'Blue backpack with a mathematics notebook.');
      expect(restored.location, 'Library');
      expect(restored.status, ItemStatus.found);
      expect(restored.createdAt, createdAt);
    });

    test('preserves status and creation time through a round trip', () {
      final ItemRecord restored = ItemRecordMapper.fromStorage(ItemRecordMapper.toStorage(record));

      expect(restored.status, record.status);
      expect(restored.createdAt, record.createdAt);
    });

    test('keeps remote metadata absent before remote confirmation', () {
      final ItemRecord pending = ItemRecord(
        name: 'Water bottle',
        description: 'Stainless steel bottle.',
        location: 'Sports center',
        status: ItemStatus.lost,
      );

      final Map<String, dynamic> storage = ItemRecordMapper.toStorage(pending);
      final ItemRecord restored = ItemRecordMapper.fromStorage(storage);
      final ItemRecord restoredWithoutMetadata = ItemRecordMapper.fromStorage({
        'name': 'Water bottle',
        'description': 'Stainless steel bottle.',
        'location': 'Sports center',
        'status': 'lost',
      });

      expect(storage['id'], isNull);
      expect(storage['createdAt'], isNull);
      expect(restored.id, isNull);
      expect(restored.createdAt, isNull);
      expect(restoredWithoutMetadata.id, isNull);
      expect(restoredWithoutMetadata.createdAt, isNull);
    });

    test('rejects an unknown persisted status', () {
      expect(
        () => ItemRecordMapper.fromStorage({
          'id': itemId,
          'name': 'Blue backpack',
          'description': 'Blue backpack with a mathematics notebook.',
          'location': 'Library',
          'status': 'missing',
          'createdAt': '2026-10-29T14:30:15.123Z',
        }),
        throwsArgumentError,
      );
    });
  });

  group('ItemFieldLimits', () {
    test('accepts the shared maximum lengths', () {
      expect(
        () => ItemRecord(
          name: List<String>.filled(ItemFieldLimits.nameMaxLength, 'a').join(),
          description: List<String>.filled(ItemFieldLimits.descriptionMaxLength, 'b').join(),
          location: 'Library',
          status: ItemStatus.found,
        ),
        returnsNormally,
      );
    });

    test('rejects values longer than the shared maximum lengths', () {
      expect(
        () => ItemRecord(
          name: List<String>.filled(ItemFieldLimits.nameMaxLength + 1, 'a').join(),
          description: 'Description',
          location: 'Library',
          status: ItemStatus.lost,
        ),
        throwsArgumentError,
      );
      expect(
        () => ItemRecord(
          name: 'Name',
          description: List<String>.filled(ItemFieldLimits.descriptionMaxLength + 1, 'b').join(),
          location: 'Library',
          status: ItemStatus.lost,
        ),
        throwsArgumentError,
      );
    });
  });
}
