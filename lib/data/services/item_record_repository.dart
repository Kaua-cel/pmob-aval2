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
