import 'package:flutter/foundation.dart';

import '../data/models/recording_meta.dart';
import '../data/repositories/recording_repository.dart';

class RecordingsProvider extends ChangeNotifier {
  RecordingsProvider(this._repo) {
    refresh();
  }

  final RecordingRepository _repo;
  List<RecordingMeta> _items = [];
  bool _loading = true;

  List<RecordingMeta> get items => _items;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> delete(RecordingMeta meta) async {
    await _repo.delete(meta.path);
    _items = _items.where((e) => e.path != meta.path).toList();
    notifyListeners();
  }
}
