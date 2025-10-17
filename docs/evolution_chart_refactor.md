# EvolutionChart - Composant réfactoré

## Vue d'ensemble

Le composant `EvolutionChart` a été réfactorisé pour offrir plus de flexibilité tout en maintenant la compatibilité avec l'usage existant.

## Nouvelles fonctionnalités

### 1. Tendances configurables
- Possibilité d'activer/désactiver l'affichage de la tendance SMA3 par courbe
- Couleurs de tendance personnalisables
- Configuration indépendante pour chaque courbe

### 2. Multi-courbes
- Support de plusieurs courbes dans un même graphique
- Jusqu'à N courbes simultanées (testé avec 3)
- Légende automatique adaptative

### 3. Axes Y multiples
- Axe gauche et axe droit indépendants
- Normalisation automatique des données pour l'axe droit
- Labels d'unités séparés

## API

### Constructeur principal
```dart
EvolutionChart({
  required String title,
  required List<EvolutionCurveConfig> curves,
  bool isLoading = false,
})
```

### Constructeur de compatibilité
```dart
EvolutionChart.single({
  required EvolutionData data,
  bool isLoading = false,
  bool showTrend = false,
})
```

### Configuration de courbe
```dart
EvolutionCurveConfig({
  required EvolutionData data,
  required Color color,
  required String label,
  bool showTrend = false,
  Color? trendColor,
  bool useRightAxis = false,
})
```

## Exemples d'utilisation

### Usage simple (compatible avec l'existant)
```dart
EvolutionChart.single(
  data: pointsData,
  showTrend: true,
)
```

### Deux courbes, même axe
```dart
EvolutionChart(
  title: 'Points vs Groupement',
  curves: [
    EvolutionCurveConfig(
      data: pointsData,
      color: Colors.amber,
      label: 'Points',
      showTrend: true,
    ),
    EvolutionCurveConfig(
      data: groupSizeData,
      color: Colors.blue,
      label: 'Groupement',
    ),
  ],
)
```

### Deux courbes, axes différents
```dart
EvolutionChart(
  title: 'Points (gauche) vs Fréquence (droite)',
  curves: [
    EvolutionCurveConfig(
      data: pointsData,
      color: Colors.green,
      label: 'Points',
      useRightAxis: false, // Axe gauche
    ),
    EvolutionCurveConfig(
      data: frequencyData,
      color: Colors.purple,
      label: 'Fréquence',
      useRightAxis: true, // Axe droit
    ),
  ],
)
```

## Migration

### Code existant
```dart
EvolutionChart(
  data: scoreEvolution,
  isLoading: false,
)
```

### Code migré
```dart
EvolutionChart.single(
  data: scoreEvolution,
  isLoading: false,
  showTrend: true, // Nouvelle option
)
```

## Contraintes et limitations

1. **Performance** : Testé jusqu'à 3 courbes simultanées
2. **Axes** : Maximum 2 axes (gauche + droit)
3. **Compatibilité** : L'ancienne API est maintenue via le constructeur `.single()`
4. **Données** : Toutes les courbes doivent avoir des longueurs de données cohérentes pour les labels X

## Architecture

Le composant suit les principes :
- **Réutilisabilité** : API flexible pour différents cas d'usage
- **Rétrocompatibilité** : Constructeur `.single()` pour l'existant
- **Agilité** : Fonctionnalités ajoutées au besoin, pas de sur-engineering
- **Généricité** : Utilisable dans tout l'app, pas seulement le dashboard