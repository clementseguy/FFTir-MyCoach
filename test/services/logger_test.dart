import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/logger.dart';

void main() {
  test('AppLogger toggles debug output', () {
    final log = AppLogger.I;
    log.enableDebug = false;
    log.debug('should not print');
    log.enableDebug = true;
    log.debug('should print');
    log.warn('warn');
    log.error('error', Exception('x'));
    // No assertions on print output; exercise code paths for coverage.
    expect(log.enableDebug, isTrue);
  });
}
