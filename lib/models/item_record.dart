/// Defines the shared item-record contract.
library;

/// Statuses accepted for an item record.
enum ItemStatus {
  /// An item reported as lost.
  lost,

  /// An item reported as found.
  found,
}

/// Shared maximum lengths for [ItemRecord] fields.
abstract final class ItemFieldLimits {
  /// Maximum number of characters accepted for [ItemRecord.name].
  static const int nameMaxLength = 60;

  /// Maximum number of characters accepted for [ItemRecord.description].
  static const int descriptionMaxLength = 200;
}

/// Immutable record of a lost or found item.
///
/// The remote service assigns [id] and [createdAt]. Both remain `null` while a
/// record has not been confirmed by that service.
final class ItemRecord {
  /// Creates an item record with required item data and optional remote metadata.
  ItemRecord({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt?.toUtc() {
    _validateMaximumLength(value: name, maximum: ItemFieldLimits.nameMaxLength, fieldName: 'name');
    _validateMaximumLength(
      value: description,
      maximum: ItemFieldLimits.descriptionMaxLength,
      fieldName: 'description',
    );
  }

  /// Technical identifier assigned by the remote service.
  final String? id;

  /// Name of the item.
  final String name;

  /// Description of the item.
  final String description;

  /// Location associated with the item.
  final String location;

  /// Typed lost or found status of the item.
  final ItemStatus status;

  /// UTC creation time assigned by the remote service.
  final DateTime? createdAt;
}

void _validateMaximumLength({
  required String value,
  required int maximum,
  required String fieldName,
}) {
  if (value.length > maximum) {
    throw ArgumentError.value(value, fieldName, 'Must not exceed $maximum characters.');
  }
}
