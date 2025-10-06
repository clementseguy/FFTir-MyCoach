import '../models/exercise.dart';

/// Modes de tri disponibles pour la liste des exercices.
enum ExerciseSortMode {
  defaultOrder, // priority asc puis createdAt asc (déjà implémenté en repo)
  nameAsc,
  nameDesc,
  category,
  type,
  newest,
}

List<Exercise> sortExercises(List<Exercise> list, ExerciseSortMode mode) {
  final copy = List<Exercise>.from(list);
  int catOrder(ExerciseCategory c) => ExerciseCategory.values.indexOf(c);
  int typeOrder(ExerciseType t) => ExerciseType.values.indexOf(t); // stand avant home
  switch (mode) {
    case ExerciseSortMode.defaultOrder:
      // L’ordre est déjà assuré par le repository (priority puis createdAt)
      return copy;
    case ExerciseSortMode.nameAsc:
      copy.sort((a,b)=> a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return copy;
    case ExerciseSortMode.nameDesc:
      copy.sort((a,b)=> b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      return copy;
    case ExerciseSortMode.category:
      copy.sort((a,b){
        final c = catOrder(a.categoryEnum).compareTo(catOrder(b.categoryEnum));
        if (c!=0) return c;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return copy;
    case ExerciseSortMode.type:
      copy.sort((a,b){
        final c = typeOrder(a.type).compareTo(typeOrder(b.type));
        if (c!=0) return c;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return copy;
    case ExerciseSortMode.newest:
      copy.sort((a,b)=> b.createdAt.compareTo(a.createdAt));
      return copy;
  }
}
