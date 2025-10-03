# Statistiques Accueil – Documentation Technique (v0.3)

Portée: décrit UNIQUEMENT l'existant (implémenté) pour l'écran Accueil. Aucune projection future.

## 1. Sources & Préparation
- Filtrage spécifique AVANT `StatsService`: dans `HomeScreen`, on restreint la liste aux sessions dont `status == 'réalisée'` et `date != null`.
- Construction `_series` (`StatsService`): pour chaque session retenue, chaque série reçoit la date de la session (si date absente → fallback epoch `1970-01-01`), puis toutes les séries sont triées par date croissante.
- Couverture `RollingStatsService`: lit toutes les sessions du repository sans filtrer le statut; ignore seulement celles sans date. Les sessions `prévue` datées sont donc incluses dans les calculs rolling (avg30/avg60/delta) à l'état actuel.

## 2. Règles Globales
- Fenêtres temporelles: 30 jours (`date > now - 30j`), 60 jours analogue. Les fenêtres progression: (0..30j) vs (30..60j).
- Groupement: les valeurs `groupSize <= 0` NE SONT PAS filtrées dans la moyenne 30j (elles entrent dans le dénominateur) mais sont ignorées pour: best groupement (`bestGroupSize`) et record groupement (`lastSeriesIsRecordGroup`) et implicites dans min() (positives uniquement).
- Valeurs par défaut / insuffisance:
	- Moyennes / compte / distributions / rolling / streak / charge: 0 si vide ou insuffisant.
	- Consistency: 0 si <3 séries ou moyenne ≤0 ou résultat non fini.
	- Progression: `NaN` si conditions non remplies (≥5 séries dans chaque fenêtre & avgPrev>0).
	- Records: false si <2 séries ou conditions non satisfaites.
- Scatter: jeu de points construit uniquement sur les (jusqu'à) 10 dernières séries (logique UI, indépendant des fenêtres 30j/60j).

## 3. Glossaire
Points = `serie.points` • Groupement = `serie.groupSize` (cm) • Distance = `serie.distance` (m) • Catégorie = `session.category`.

## 4. Tableau Synthétique
| Code | Nom UI | Source | Fenêtre | Formule / Règle | Condition | Fallback |
|------|--------|--------|---------|-----------------|----------|----------|
| AVG30 | Moy. points 30j | Séries | 30j | sum(points)/N | ≥1 série 30j | 0 |
| GRP30 | Groupement moy 30j | Séries | 30j (groupSize>0) | sum(groupSize)/N | ≥1 série valide | 0 |
| BEST | Best série | Séries | Toutes | max(points) | ≥1 série | '-' |
| SESSM | Sessions ce mois | Sessions | Mois courant | count(sessions) | Toujours | 0 |
| SMA3 | Tendance (SMA3) | Séries | Historique | moyenne glissante taille 3 | ≥1 série | valeurs brutes |
| CONS | Consistency 30j | Séries | 30j | (1 - σ/μ)*100 clamp [0,100] | ≥3 séries & μ>0 | 0 |
| PROG | Progression % | Séries | 0..30 vs 30..60 | ((avgC-avgP)/avgP)*100 | ≥5 & avgP>0 | NaN |
| DIST30 | Répartition distances 30j | Séries | 30j | comptage distance arrondie | ≥1 série | liste vide |
| CAT | Répartition catégories | Sessions | Toutes | count(category) | ≥1 session | liste vide |
| BUCK | Distribution points 30j | Séries | 30j | buckets taille 10 | ≥1 série | liste vide |
| ROLL | Rolling avg30/avg60 | Sessions | 30/60j | sum(pointsSession)/count | ≥0 | 0 |
| RDELTA | Rolling delta | Sessions | 30/60j | avg30 - avg60 | dépend ROLL | 0 |
| STRK | Streak (jours) | Sessions | Historique | jours consécutifs | ≥1 session | 0 |
| LOAD | Charge semaine | Sessions | Semaine ISO | sessionsThisWeek() | ≥0 | 0 |
| LΔ | Delta charge | Sessions | Semaine cour./préc. | currentWeek - previousWeek | ≥0 | 0 |
| BESTGRP | Best groupement | Séries | Toutes | min(groupSize>0) | ≥1 série valide | 0 |
| RRECPTS | Record points dernière | Séries | Dernière vs précédent | last.points > max(prev) | ≥2 séries | false |
| RRECGRP | Record groupement dernière | Séries | Dernière vs précédent | last.groupSize < min(prev>0) | ≥2 séries valides | false |
| SCAT | Scatter pts/groupement | Séries | 10 dernières séries | (x=group_size,y=points) | ≥1 série | n/a |

## 5. Détails des Calculs
### 5.1 Moyenne points 30j (AVG30)
Filtre: séries date > now-30j. Moyenne simple. Vide → 0.
### 5.2 Groupement moyen 30j (GRP30)
Filtre 30j + groupSize>0. Moyenne arithmétique. Vide → 0.
### 5.3 Best série (BEST)
Max(points) global. Aucune série → '-'.
### 5.4 Sessions ce mois (SESSM)
Count sessions (year & month = now).
### 5.5 SMA3 (SMA3)
Pour i: moyenne des points indices [i-2..i]. Bords tronqués.
### 5.6 Consistency (CONS)
Fenêtre 30j. Conditions: ≥3 séries & moyenne>0. σ population. (1 - σ/μ)*100 clamp [0,100]. Sinon 0.
### 5.7 Progression (PROG)
Fenêtres: C (0..30j) & P (30..60j). Conditions: |C|≥5 & |P|≥5 & avgP>0 sinon NaN.
### 5.8 Distances 30j (DIST30)
Arrondi entier + comptage.
### 5.9 Catégories (CAT)
1 incrément par session (sessionsOnly).
### 5.10 Buckets points 30j (BUCK)
Buckets 10 pts successifs jusqu'au max.
### 5.11 Rolling (ROLL)
Somme points/session. avg30 / avg60 = sum / count (0 si count=0).
### 5.12 Rolling delta (RDELTA)
Delta = avg30 - avg60.
### 5.13 Streak (STRK)
Dates normalisées jour; tri DESC; diff==1 successif.
### 5.14 Charge & Delta (LOAD / LΔ)
Semaine ISO (lundi). Delta = current - previous.
### 5.15 Best groupement (BESTGRP)
Min groupSize>0 sinon 0.
### 5.16 Records dernière (RRECPTS / RRECGRP)
Points: last > max(prev). Groupement: last < min(prev>0). <2 séries → false.
### 5.17 Scatter (SCAT)
Tri sessions DESC → 10; aplatir séries → tri ASC → garder 10 dernières; spots (group_size, points); maxX = max(group_size)+5 (≥10); maxY=55 fixe.

## 6. Règles d'Affichage
- Progression NaN → '-'. Consistency==0 → '-'.
- Badges record affichés si true.
- Scatter / distributions masqués si aucune donnée.
- 0 ≠ '-' (0 = calcul valide; '-' = absence / insuffisant).

## 7. Limites Connues
- Scatter tronqué (10 séries) donc non exhaustif.
- Pas de normalisation distance sur groupement.
- σ population utilisé.

## 8. Révision
2025-10-03 Réécriture propre (existant only).