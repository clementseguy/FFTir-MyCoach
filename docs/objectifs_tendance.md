# Tendance des Objectifs

Cette documentation décrit précisément la façon dont la **tendance** ("En hausse", "Stable", "En baisse") est calculée pour chaque objectif.

## 1. Fenêtres de temps
Si l'objectif possède une *période roulante* :
- **7 derniers jours** (rollingWeek) : fenêtre courante = [J-7 ; J], fenêtre précédente = [J-14 ; J-7).
- **30 derniers jours** (rollingMonth) : fenêtre courante = [J-30 ; J], fenêtre précédente = [J-60 ; J-30).

Si l'objectif est **sans période (none)** :
- Aucune fenêtre précédente n'est calculée → la tendance n'est pas significative (affichage "-" dans l'interface).

## 2. Valeur mesurée
Pour chaque fenêtre on calcule la valeur de la métrique choisie :
- `averagePoints` : moyenne de tous les points de séries.
- `averageSessionPoints` : moyenne des moyennes par session.
- `sessionCount` : nombre de sessions.
- `totalPoints` : somme brute de points (hérité / déconseillé).
- `groupSize` : moyenne des groupements (mm).
- `bestSeriesPoints` : meilleur score de série.
- `bestSessionPoints` : meilleur score de session.
- `bestGroupSize` : plus petit groupement.

## 3. Normalisation du sens (delta)
On calcule :
- `valueCurrent` = valeur métrique fenêtre courante
- `valuePrevious` = valeur métrique fenêtre précédente (si disponible)

Le delta interne `improvementDelta` est :
- Si comparateur = **≥** (plus grand est mieux) : `delta = valueCurrent - valuePrevious`
- Si comparateur = **≤** (plus petit est mieux) : `delta = valuePrevious - valueCurrent`

Ainsi, **delta > 0 signifie toujours une amélioration**, quel que soit le sens initial de l'objectif.

## 4. Seuil de neutralité
Constante code : `kGoalDeltaNeutralEpsilon = 0.001`.

Classification :
- `delta >  epsilon`  → En hausse
- `|delta| <= epsilon` → Stable
- `delta < -epsilon`   → En baisse

## 5. Cas sans fenêtre précédente
Si `valuePrevious` est absente (pas assez d'historique ou période = none) : affichage de la tendance = `-`.

## 6. Exemples rapides
| Comparateur | valuePrevious | valueCurrent | delta calculé | Tendance |
|-------------|---------------|--------------|---------------|----------|
| ≥ (moyenne points) | 44.2 | 45.0 | +0.8 | En hausse |
| ≥ (sessions) | 5 | 5 | 0 | Stable |
| ≥ (score série) | 49 | 48 | -1 | En baisse |
| ≤ (groupement mm) | 32 | 30 | +2 (32-30) | En hausse |
| ≤ (groupement mm) | 30 | 30.0005 | ~0 (|delta|<ε) | Stable |
| ≤ (groupement mm) | 28 | 29 | -1 | En baisse |

## 7. Notes
- Le seuil très faible (0.001) évite que de minuscules variations flottantes changent l'état.
- L'affichage utilisateur est volontairement simple : pas de valeur numérique du delta (surcharge visuelle évitée).

## 8. Évolutions possibles
- Afficher une info-bulle chiffrée sur demande (future version).
- Paramétrer le seuil selon la métrique (actuellement global).
