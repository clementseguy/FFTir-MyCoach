# Documentation des Statistiques (v0.3)

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


