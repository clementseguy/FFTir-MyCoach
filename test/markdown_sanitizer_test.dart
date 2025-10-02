import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/utils/markdown_sanitizer.dart';

void main() {
  group('sanitizeCoachMarkdown', () {
    test('retire fences englobants avec langue', () {
      final input = '```markdown\n# Titre\nTexte **fort**\n```';
      final out = sanitizeCoachMarkdown(input);
      expect(out.startsWith('# Titre'), true);
      expect(out.contains('```'), false);
    });

    test('laisse markdown propre inchangé', () {
      final input = '# Titre\nTexte **fort**';
      final out = sanitizeCoachMarkdown(input);
      expect(out, input);
    });

    test('ne casse pas contenu sans fence de fin', () {
      final input = '```\n# Titre\nTexte';
      final out = sanitizeCoachMarkdown(input);
      // Pas de fence terminal -> on ne le retire pas (sécurité)
      expect(out, input.trim());
    });

    test('convertit literal \n en retours ligne', () {
      final input = '# Ligne 1\\nLigne 2';
      final out = sanitizeCoachMarkdown(input);
      expect(out.contains('Ligne 2'), true);
      expect(out.split('\n').length >= 2, true);
    });
  });
}
