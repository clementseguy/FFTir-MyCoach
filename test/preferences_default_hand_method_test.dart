import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/preferences_service.dart';
import 'package:tir_sportif/models/series.dart';

void main() {
  setUpAll(() async {
    if (!Hive.isBoxOpen('app_preferences')) {
      Hive.init('.');
      await Hive.openBox('app_preferences');
    }
  });

  test('PreferencesService stores and reads default hand method', () async {
    final prefs = PreferencesService();
    await prefs.setDefaultHandMethod(HandMethod.oneHand);
    expect(prefs.getDefaultHandMethod(), HandMethod.oneHand);

    await prefs.setDefaultHandMethod(HandMethod.twoHands);
    expect(prefs.getDefaultHandMethod(), HandMethod.twoHands);
  });
}
