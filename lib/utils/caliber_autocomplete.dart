import '../config/app_config.dart';

String _norm(String s) {
  var t = s.trim().toLowerCase();
  t = t.replaceAll('×', 'x');
  t = t.replaceAll('mm', '');
  t = t.replaceAll(RegExp(r'\s+'), '');
  return t;
}

class CaliberAutocompleteResult {
  final String? autoReplacement;
  final List<String> suggestions;
  CaliberAutocompleteResult({this.autoReplacement, required this.suggestions});
}

CaliberAutocompleteResult suggestFor(String input) {
  final list = AppConfig.I.calibers;
  final normIn = _norm(input);
  if (normIn.isEmpty) return CaliberAutocompleteResult(autoReplacement: null, suggestions: const []);
  final matches = <String>[];
  for (final c in list) {
    final n = _norm(c);
    if (n.contains(normIn)) matches.add(c);
    if (n == normIn) {
      return CaliberAutocompleteResult(autoReplacement: c, suggestions: const []);
    }
  }
  if (matches.length == 1) {
    return CaliberAutocompleteResult(autoReplacement: matches.first, suggestions: const []);
  }
  return CaliberAutocompleteResult(autoReplacement: null, suggestions: matches);
}

String pickInitialCaliber({String? existing, String? defaultCaliber}) {
  final e = (existing ?? '').trim();
  if (e.isNotEmpty) return e;
  final d = (defaultCaliber ?? '').trim();
  return d;
}
