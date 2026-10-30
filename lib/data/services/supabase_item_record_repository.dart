import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/item_record.dart';
import '../../models/item_record_mapper.dart';
import 'item_record_repository.dart';

const String _itemRecordsTable = 'item_records';

/// Makes the minimum remote operations testable without a Supabase connection.
abstract interface class ItemRecordRemoteDataSource {
  /// Fetches remote rows ordered from most recent to least recent.
  Future<List<ItemRecordStorage>> listNewestFirst();

  /// Inserts [payload] and returns the database row selected after insertion.
  Future<ItemRecordStorage> insertItemRecord(ItemRecordStorage payload);
}

/// Implements [ItemRecordRepository] with the Supabase Postgres REST API.
final class SupabaseItemRecordRepository implements ItemRecordRepository {
  /// Creates a repository backed by [remoteDataSource].
  const SupabaseItemRecordRepository(this._remoteDataSource);

  /// Creates a repository using the initialized default Supabase client.
  factory SupabaseItemRecordRepository.fromInitializedClient() {
    return SupabaseItemRecordRepository(
      SupabaseItemRecordRemoteDataSource(Supabase.instance.client),
    );
  }

  final ItemRecordRemoteDataSource _remoteDataSource;

  @override
  Future<List<ItemRecord>> listItemRecords() async {
    final List<ItemRecordStorage> rows = await _remoteDataSource.listNewestFirst();
    return rows.map(_fromSupabaseRow).toList(growable: false);
  }

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) async {
    final ItemRecordStorage row = await _remoteDataSource.insertItemRecord(_creationPayload(draft));
    return _fromSupabaseRow(row);
  }

  ItemRecordStorage _creationPayload(ItemRecord draft) {
    final ItemRecordStorage storage = ItemRecordMapper.toStorage(draft);
    return {
      'name': storage['name'],
      'description': storage['description'],
      'location': storage['location'],
      'status': storage['status'],
    };
  }

  ItemRecord _fromSupabaseRow(ItemRecordStorage row) {
    final ItemRecordStorage storage = Map<String, Object?>.from(row)
      ..['createdAt'] = row['created_at'];

    final ItemRecord record;
    try {
      record = ItemRecordMapper.fromStorage(storage);
    } on ArgumentError catch (error) {
      throw FormatException('Invalid item_records response: $error');
    }

    if (record.id == null || record.createdAt == null) {
      throw const FormatException('Invalid item_records response: id and created_at are required.');
    }
    return record;
  }
}

/// Executes item-record requests against an initialized [SupabaseClient].
final class SupabaseItemRecordRemoteDataSource implements ItemRecordRemoteDataSource {
  /// Creates a data source that uses [client] for all database requests.
  const SupabaseItemRecordRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ItemRecordStorage>> listNewestFirst() async {
    final List<Map<String, dynamic>> rows = await _client
        .from(_itemRecordsTable)
        .select()
        .order('created_at', ascending: false);
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  @override
  Future<ItemRecordStorage> insertItemRecord(ItemRecordStorage payload) async {
    final Map<String, dynamic> row = await _client
        .from(_itemRecordsTable)
        .insert(payload)
        .select()
        .single();
    return Map<String, Object?>.from(row);
  }
}
