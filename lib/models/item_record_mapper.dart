import 'item_record.dart';

/// Typed key-value data used when serializing an [ItemRecord].
typedef ItemRecordStorage = Map<String, Object?>;

/// Converts [ItemRecord] values to and from stable persistence data.
abstract final class ItemRecordMapper {
  /// Serializes [record] using stable cloud-ready storage keys.
  ///
  /// The `id` and `createdAt` keys contain `null` until remote confirmation.
  /// Non-null dates are ISO 8601 UTC strings.
  static ItemRecordStorage toStorage(ItemRecord record) {
    return {
      'id': record.id,
      'name': record.name,
      'description': record.description,
      'location': record.location,
      'status': _statusToStorage(record.status),
      'createdAt': record.createdAt?.toUtc().toIso8601String(),
    };
  }

  /// Reconstructs an [ItemRecord] from stable persistence [storage].
  ///
  /// Throws an [ArgumentError] for missing required fields, invalid value types,
  /// unknown statuses, or dates that are not ISO 8601 UTC strings.
  static ItemRecord fromStorage(ItemRecordStorage storage) {
    return ItemRecord(
      id: _readOptionalString(storage, 'id'),
      name: _readRequiredString(storage, 'name'),
      description: _readRequiredString(storage, 'description'),
      location: _readRequiredString(storage, 'location'),
      status: _statusFromStorage(_readRequiredString(storage, 'status')),
      createdAt: _readOptionalUtcDateTime(storage, 'createdAt'),
    );
  }

  static String _readRequiredString(ItemRecordStorage storage, String key) {
    final Object? value = storage[key];
    if (value is String) {
      return value;
    }

    throw ArgumentError.value(value, key, 'Expected a non-null String.');
  }

  static String? _readOptionalString(ItemRecordStorage storage, String key) {
    final Object? value = storage[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }

    throw ArgumentError.value(value, key, 'Expected a String or null.');
  }

  static DateTime? _readOptionalUtcDateTime(ItemRecordStorage storage, String key) {
    final Object? value = storage[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw ArgumentError.value(value, key, 'Expected an ISO 8601 UTC String or null.');
    }

    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) {
      throw ArgumentError.value(value, key, 'Expected an ISO 8601 UTC String or null.');
    }

    return parsed;
  }
}

String _statusToStorage(ItemStatus status) {
  return switch (status) {
    ItemStatus.lost => 'lost',
    ItemStatus.found => 'found',
  };
}

ItemStatus _statusFromStorage(String value) {
  return switch (value) {
    'lost' => ItemStatus.lost,
    'found' => ItemStatus.found,
    _ => throw ArgumentError.value(
      value,
      'status',
      'Unsupported item status. Expected "lost" or "found".',
    ),
  };
}
