import 'package:hive/hive.dart';
import '../models/series.dart';

class PreferencesService {
  static const _boxName = 'app_preferences';
  static const _handMethodKey = 'default_hand_method';
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  Box<dynamic> get _box => Hive.box(_boxName);

  HandMethod getDefaultHandMethod() {
    final v = _box.get(_handMethodKey, defaultValue: 'two');
    return v == 'one' ? HandMethod.oneHand : HandMethod.twoHands;
  }

  Future<void> setDefaultHandMethod(HandMethod method) async {
    await _box.put(_handMethodKey, method == HandMethod.oneHand ? 'one' : 'two');
  }
}
