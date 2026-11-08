import '../../models/item_record.dart';

/// Provides cloud persistence for item records without exposing a vendor SDK.
abstract interface class ItemRecordRepository {
  /// Lists item records ordered from most recently created to least recently created.
  Future<List<ItemRecord>> listItemRecords();

  /// Creates [draft] remotely and returns server-assigned metadata.
  ///
  /// The remote service ignores local [ItemRecord.id] and [ItemRecord.createdAt]
  /// values. It assigns both values after a successful insertion.
  Future<ItemRecord> createItemRecord(ItemRecord draft);
}

/// Repository fallback used when cloud initialization fails at startup.
///
/// Surfaces [_initializationError] asynchronously on read and write operations
/// so the UI can present a controlled error state instead of crashing on boot.
final class FailingItemRecordRepository implements ItemRecordRepository {
  /// Creates a fallback repository that always throws [_initializationError].
  const FailingItemRecordRepository(this._initializationError);

  final Object _initializationError;

  @override
  Future<List<ItemRecord>> listItemRecords() {
    return Future<List<ItemRecord>>.error(_initializationError);
  }

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) {
    return Future<ItemRecord>.error(_initializationError);
  }
}
