import 'package:flutter/foundation.dart';

import '../data/services/item_record_repository.dart';
import '../models/item_record.dart';
import 'operation_error_message.dart';

enum ItemListState { loading, success, failure }

class ItemListController extends ChangeNotifier {
  ItemListController(this._repository);

  final ItemRecordRepository _repository;
  List<ItemRecord> _records = const [];
  ItemListState _state = ItemListState.loading;
  Object? _error;
  Future<void>? _activeLoad;

  List<ItemRecord> get records => List<ItemRecord>.unmodifiable(_records);
  ItemListState get state => _state;
  Object? get error => _error;
  bool get isLoading => _state == ItemListState.loading;
  String? get errorMessage => _state == ItemListState.failure ? describeReadError(_error) : null;

  Future<void> load() {
    if (_activeLoad != null) {
      return _activeLoad!;
    }

    final Future<void> operation = _performLoad();
    _activeLoad = operation;
    return operation;
  }

  Future<void> _performLoad() async {
    _state = ItemListState.loading;
    _error = null;
    notifyListeners();

    try {
      final List<ItemRecord> records = await _repository.listItemRecords();
      _records = List<ItemRecord>.unmodifiable(records);
      _state = ItemListState.success;
    } catch (error) {
      _error = error;
      _state = ItemListState.failure;
    } finally {
      _activeLoad = null;
      notifyListeners();
    }
  }
}
