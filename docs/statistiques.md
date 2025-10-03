# Statistiques Accueil – Documentation Technique (v0.3)

Portée: décrit UNIQUEMENT l'existant (implémenté) pour l'écran Accueil. Aucune projection future.

## 1. Sources & Préparation
- Filtre UI préalable: `status == 'réalisée'` et `date != null` avant création de `StatsService`.
- `StatsService` : aplatissement séries (ordre date croissant) dans `_series`.
- `RollingStatsService` : calcule moyennes 30j / 60j sur points totaux par session (toutes sessions chargées avec date non nulle).

## 2. Règles Globales
- Fenêtre 30 jours : `date > now - 30j`. Fenêtre 60j analogue.
- Groupement ignoré si `groupSize <= 0` dans certains calculs (moyenne, best).
- Valeur défaut métriques numériques: 0 (sauf Progression → NaN quand insuffisant; Consistency → 0 si insuffisant).
- Scatter: limité aux 10 dernières séries (logique UI, distinct du filtrage 30j).

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
2025-10-03 Réécriture propre (existant only).# Documentation des Statistiques (v0.3)

Objectif: documenter uniquement l'existant (calculs réellement implémentés dans le code à la date de cette version).

Notes (périmètre implémenté):
- Aucune exclusion spécifique du statut "prévue" dans les calculs actuels (les sessions sont utilisées telles qu'elles sont fournies au service de stats).
- Pas de segmentation par onglets dans l'UI actuelle (toutes les stats sont rendues sur une seule page).
- Corrélation Points / Groupement: simple scatter construit à partir des 10 dernières séries disponibles (issues des séries des 10 dernières sessions), sans coefficient chiffré, sans seuil conditionnel, sans fenêtre 30j.

## Table récap (vue rapide)
| Nom | Source de données | Fenêtre / Ensemble | Formule / Algorithme | Conditions d'affichage | Valeurs limites / Fallback |
|-----|-------------------|--------------------|----------------------|------------------------|----------------------------|
| Moyenne points 30j | Séries (points) | 30 derniers jours (date série) | somme(points)/N | ≥1 série dans fenêtre | 0 si aucune série |
| Groupement moyen 30j | Séries (groupSize) | 30 derniers jours | somme(groupSize)/N | ≥1 série avec groupSize>0 | 0 si aucune |
| Meilleure série (points) | Séries | Toutes séries | max(points) | ≥1 série | null/"-" si aucune |
| Sessions ce mois | Sessions | Mois civil courant | count(sessions.date mois==now) | ≥0 (toujours) | 0 |
| SMA3 Points | Séries (points) | Séries triées par date | Moyenne glissante taille 3 (bord: moins d'éléments) | ≥1 série | Valeurs calculées |
| Consistency Index 30j | Séries (points) | 30 derniers jours | (1 - (σ/μ)) * 100 clampé [0,100] | ≥3 séries & μ>0 | 0 si insuffisant |
| Progression % (30 vs 30 précédent) | Séries (points) | 0..30j vs 30..60j | ((avgCurr - avgPrev)/avgPrev)*100 | ≥5 séries dans chaque fenêtre & avgPrev>0 | NaN → non affiché |
| Distribution distances 30j | Séries (distance) | 30 derniers jours | Comptage distance arrondie | ≥1 série | Liste vide |
| Distribution catégories (sessions) | Sessions | Toutes | count(session.category) | ≥1 session | Vide si aucune |
| Buckets points 30j | Séries (points) | 30 derniers jours | Buckets [k..k+bucketSize-1] | ≥1 série | Liste vide |
| Rolling avg30 / avg60 | Sessions (points/session) | 30 & 60j glissants | Moyenne points/session | ≥1 session/fenêtre | 0 si vide |
| Rolling delta | Sessions | 30 & 60j | avg30 - avg60 | Averages calculées | 0 si pas de données |
| Streak (jours consécutifs) | Sessions (dates) | Historique | Comptage jours consécutifs | ≥1 session | 0 |
| Charge (hebdo) | Sessions | Semaine ISO courante | sessionsThisWeek() | ≥0 | 0 |
| Delta Charge (hebdo) | Sessions | Semaine courante & précédente | sessionsThisWeek - sessionsPreviousWeek | ≥0 | 0 |
| Best groupement | Séries (groupSize>0) | Toutes | min(groupSize) | ≥1 série valide | 0 |
| Record points dernière série ? | Séries | Dernière vs historique | last.points > max(précédents) | ≥2 séries | false |
| Record groupement dernière série ? | Séries | Dernière vs historiques | last.groupSize < min(précédents) | ≥2 séries valides | false |
| Corrélation Points / Groupement | Séries (points, groupSize) | 10 dernières séries | Scatter (x=group_size, y=points) | ≥1 série | Pas de coefficient |

## Détails & Formules

### 1. Moyenne points 30j
- Séries dont `date > now - 30j`.
- Formule: `sum(points)/N`.
- N=0 → 0.

### 2. Groupement moyen 30j
- Séries 30j avec `groupSize > 0`.
- Formule: `sum(groupSize)/N`.
- Aucune série valide → 0.

### 3. Meilleure série (points)
- Max absolu des points sur l'historique.

### 4. Sessions ce mois
- Sessions dont `year==now.year` et `month==now.month`.

### 5. SMA3 (Points)
- Tri chronologique.
- Moyenne des 1..3 dernières selon disponibilité.

### 6. Consistency Index (30j)
- ≥3 séries & moyenne > 0.
- Population σ.
- `(1 - σ/μ)*100` clampé [0,100].

### 7. Progression % (30j vs 30j précédent)
- Fenêtres: (0..30j) & (30..60j).
- Conditions: ≥5 séries dans chaque & avgPrev>0.
- Formule: `((avgCurr - avgPrev)/avgPrev)*100`.
- Sinon: NaN (non affiché).

### 8. Distribution distances 30j
- Distance arrondie à l'entier, comptage.

### 9. Distribution catégories (sessionsOnly=true)
- 1 incrément par session.

### 10. Buckets points 30j
- Taille par défaut: 10.
- Construction jusqu'au max observé.

### 11. Rolling avg30 / avg60 & delta
- Points totaux par session.
- Moyennes séparées 30j / 60j.
- delta = avg30 - avg60.

### 12. Streak (jours consécutifs)
- Jours distincts triés desc; incrémente tant que diff==1 jour.

### 13. Charge (hebdomadaire)
- sessionsThisWeek() (lundi→dimanche).
- Delta = différence avec semaine précédente.

### 14. Best groupement
- Min groupSize > 0.

### 15. Records dernière série
- Points: last.points > max(précédents).
- Groupement: last.groupSize < min(previous>0).

### 16. Corrélation (scatter)
- Données: 10 dernières séries (issues des 10 dernières sessions) triées par date.
- X = group_size (cm), Y = points.
- Pas de seuil, pas de coefficient.
- maxX = max(group_size observé) + marge (≥10).

## Tooltips (existant)
- Consistency: "Homogénéité des points (30j)."
- Progression: "+X% vs 30j précédents".
- Charge: "Sessions cette semaine".
- Rolling: "Moyennes 30j / 60j (points/session)".
- SMA3: "Moyenne glissante (3 séries)".

### 1. Moyenne points 30j
- Entrées: toutes les séries dont `date > now - 30j`.
- Formule: `avgPoints30 = sum(points) / N`.
- Comportement bord: N=0 → 0.
- Interprétation: Production moyenne brute (sans pondération par distance / coups). 

### 2. Groupement moyen 30j
- Entrées: séries 30j avec `groupSize > 0`.
- Formule: `avgGroup30 = sum(groupSize)/N`.
- Bord: aucune série valide → 0.

### 3. Meilleure série (points)
- Max absolu des points sur tout l'historique.
- Affiche id ou metadata en tooltip (option futur).

### 4. Sessions ce mois
- Filtre: sessions dont `year==now.year` et `month==now.month`.

### 5. SMA3 (Points)
- Tri chronologique des séries.
- Pour i: moyenne des points de `[max(0,i-2)..i]`.
- Fenêtre réduite (<3) au début.

### 6. Consistency Index (30j)
- Fenêtre: séries 30j.
- Conditions: ≥3 séries et μ>0.
- σ population; `CI = (1 - (σ/μ)) * 100` clampé [0,100].
- Sinon: 0.

### 7. Progression % (30j vs 30j précédent)
- Fenêtre courante: `date > now-30j`.
- Fenêtre précédente: `now-60j < date <= now-30j`.
- Conditions: ≥5 séries dans chaque fenêtre & avgPrev>0.
- Formule: `((avgCurr - avgPrev)/avgPrev)*100`.
- Données insuffisantes: NaN (non affiché).

### 8. Distribution distances 30j
- Distances arrondies à l'entier et comptées.

### 9. Distribution catégories (sessionsOnly=true)
- Comptage 1 par session (catégorie de la session).

### 10. Buckets points 30j
- Buckets taille par défaut 10 jusqu'au max observé.

### 11. Rolling avg30 / avg60 & delta
- Points totaux/session agrégés.
- avg60: moyenne 60j; avg30: moyenne 30j; delta = avg30 - avg60.

### 12. Streak (jours consécutifs)
- Jours distincts triés desc; incrémente tant que diff==1.

### 13. Charge (hebdomadaire)
- sessionsThisWeek() (lundi→dimanche) & delta = diff avec semaine précédente.

### 14. Best groupement
- Minimum groupSize > 0.

### 15. Records dernière série
- Points: last.points > max(précédents).
- Groupement: last.groupSize < min(précédents>0).

## Tooltips (existant)
- Consistency: "Homogénéité des points (30j)."
- Progression: "+X% vs 30j précédents".
- Charge: "Sessions cette semaine".
- Rolling: "Moyennes 30j / 60j (points/session)".
- SMA3: "Moyenne glissante (3 séries)".

## Corrélation (scatter)
- Axe X: group_size (cm), Axe Y: points.
- Données: séries 30j.
- Seuil: <10 séries → message d'insuffisance.
- Pas de calcul de coefficient stocké.


