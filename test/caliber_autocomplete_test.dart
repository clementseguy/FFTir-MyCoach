import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/utils/caliber_autocomplete.dart';

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  test('Autoremplacement unique', () {
    final r1 = suggestFor('22');
    expect(r1.autoReplacement, '.22 LR');
    expect(r1.suggestions, isEmpty);

    final r2 = suggestFor('45');
    expect(r2.autoReplacement, '.45 ACP');
  });

  test('Ambiguïté -> suggestions', () {
    final r = suggestFor('38');
    expect(r.autoReplacement, isNull);
    expect(r.suggestions, contains('.38 Special'));
    expect(r.suggestions, contains('.380 ACP'));
  });

  test('pickInitialCaliber prefers existing, else default, else empty', () {
    expect(pickInitialCaliber(existing: '.22 LR', defaultCaliber: ''), '.22 LR');
    expect(pickInitialCaliber(existing: '', defaultCaliber: '.45 ACP'), '.45 ACP');
    expect(pickInitialCaliber(existing: null, defaultCaliber: null), '');
  });
}
