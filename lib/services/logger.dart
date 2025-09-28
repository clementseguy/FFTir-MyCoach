/// Simple logger wrapper (can be expanded later: levels, sinks, etc.)
class AppLogger {
  static final AppLogger I = AppLogger._();
  AppLogger._();

  bool enableDebug = true;

  void debug(String message) {
    if (enableDebug) {
      // ignore: avoid_print
      print('[DEBUG] $message');
    }
  }

  void warn(String message) {
    // ignore: avoid_print
    print('[WARN] $message');
  }

  void error(String message, [Object? err, StackTrace? st]) {
    // ignore: avoid_print
    print('[ERROR] $message');
    if (err != null) {
      // ignore: avoid_print
      print('        err=$err');
    }
    if (st != null) {
      // ignore: avoid_print
      print(st);
    }
  }
}
