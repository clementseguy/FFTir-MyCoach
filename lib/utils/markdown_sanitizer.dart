/// Utilitaire de sanitation pour les réponses markdown du coach.
/// Objectif: retirer un éventuel bloc de code global ```...``` qui empêche
/// le moteur Markdown d'interpréter les titres / emphases.
/// Ne modifie pas le contenu interne si aucun fence englobant détecté.
String sanitizeCoachMarkdown(String input) {
  var s = input.trim();
  if (s.isEmpty) return s;

  // Si commence et finit par ``` ... ``` on tente de retirer l'enveloppe.
  // Pattern: ```lang?\n ... \n``` (lang optionnel)
  if (s.startsWith('```')) {
    final lastFence = s.lastIndexOf('```');
    if (lastFence > 0 && lastFence != 0) {
      // Vérifie qu'il y a au moins un saut de ligne après la première ligne fence.
      final firstLineEnd = s.indexOf('\n');
      if (firstLineEnd != -1) {
  // Première ligne ex: ```markdown ou ``` (langue ignorée)
        // On supprime seulement si le fence final est à la toute fin.
        if (lastFence >= s.length - 4) {
          // Extraire le corps entre premier saut de ligne et le début du fence final.
            s = s.substring(firstLineEnd + 1, lastFence).trim();
        }
      }
    }
  }

  // Convertit \n littéraux si pas de vrais retours ligne.
  if (!s.contains('\n') && s.contains('\\n')) {
    s = s.replaceAll('\\n', '\n');
  }

  // Retire wrappers éventuels <markdown>...</markdown>
  if (s.startsWith('<markdown>') && s.endsWith('</markdown>')) {
    s = s.substring('<markdown>'.length, s.length - '</markdown>'.length).trim();
  }

  return s;
}
