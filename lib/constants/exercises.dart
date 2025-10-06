/// Canonical exercise categories (early draft; can evolve).
class ExerciseCategories {
  static const precision = 'précision';
  static const vitesse = 'vitesse';
  static const technique = 'technique';
  static const mental = 'mental';
  static const physique = 'physique';

  static const all = <String>{precision, vitesse, technique, mental, physique};
}

String normalizeExerciseCategory(String raw) {
  final r = raw.trim().toLowerCase();
  // Basic normalization; could expand (accents) later
  if (ExerciseCategories.all.contains(r)) return r;
  return ExerciseCategories.technique; // fallback
}