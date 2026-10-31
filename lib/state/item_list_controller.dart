import 'package:flutter/foundation.dart';

import '../data/services/item_record_repository.dart';
import '../models/item_record.dart';

enum ItemListState { loading, success, failure }

class ItemListController extends ChangeNotifier {
  ItemListController(this._repository);

  final ItemRecordRepository _repository;
  List<ItemRecord> _records = const [];
  ItemListState _state = ItemListState.loading;
  Object? _error;
  int _requestVersion = 0;

  List<ItemRecord> get records => List<ItemRecord>.unmodifiable(_records);
  ItemListState get state => _state;
  Object? get error => _error;

  Future<void> load() async {
    final int requestVersion = ++_requestVersion;
    _state = ItemListState.loading;
    _error = null;
    notifyListeners();

    try {
      final List<ItemRecord> records = await _repository.listItemRecords();
      if (requestVersion != _requestVersion) {
        return;
      }

      _records = List<ItemRecord>.unmodifiable(records);
      _state = ItemListState.success;
      notifyListeners();
    } catch (error) {
      if (requestVersion != _requestVersion) {
        return;
      }

      _error = error;
      _state = ItemListState.failure;
      notifyListeners();
    }
  }
}
