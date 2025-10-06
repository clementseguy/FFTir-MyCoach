import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/preferences_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('.');
    await Hive.openBox('app_preferences');
  });

  test('PreferencesService stores and reads default caliber', () async {
    final prefs = PreferencesService();
    await prefs.setDefaultCaliber('.40 S&W');
    expect(prefs.getDefaultCaliber(), '.40 S&W');

    await prefs.setDefaultCaliber('');
    expect(prefs.getDefaultCaliber(), isNull);
  });
}
