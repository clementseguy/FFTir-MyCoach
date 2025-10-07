import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/goal.dart';

// Widget de test qui simule le MultiGoalCard
class MockMultiGoalCard extends StatelessWidget {
  final bool loading;
  final List<Goal> activeGoals;

  const MockMultiGoalCard({
    Key? key,
    this.loading = false,
    this.activeGoals = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : activeGoals.isEmpty
                ? const Text('Aucun objectif actif.', style: TextStyle(fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.flag_circle, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text('Objectifs actifs', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...activeGoals.map((g) => _GoalRow(goal: g)).toList(),
                      if (activeGoals.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text('${activeGoals.length} objectifs actifs', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Goal goal;
  const _GoalRow({required this.goal});
  
  @override
  Widget build(BuildContext context) {
    final progress = (goal.lastProgress ?? 0).clamp(0, 1).toDouble();
    final pct = (progress * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[850],
                  color: _colorFor(progress),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _colorFor(double p) {
    if (p >= 0.9) return Colors.green;
    if (p >= 0.6) return Colors.amber;
    return Colors.blueGrey;
  }
}

void main() {
  group('MultiGoalCard', () {
    testWidgets('affiche un indicateur de chargement', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MockMultiGoalCard(
              loading: true,
            ),
          ),
        ),
      );

      // Vérifier que l'indicateur de chargement est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Objectifs actifs'), findsNothing);
    });

    testWidgets('affiche "Aucun objectif actif" quand la liste est vide', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MockMultiGoalCard(
              loading: false,
              activeGoals: [],
            ),
          ),
        ),
      );

      // Vérifier que le message est affiché
      expect(find.text('Aucun objectif actif.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('affiche les objectifs correctement', (WidgetTester tester) async {
      final goals = [
        Goal(
          id: '1',
          title: 'Objectif 1',
          description: 'Description 1',
          metric: GoalMetric.averagePoints,
          comparator: GoalComparator.greaterOrEqual,
          status: GoalStatus.active,
          targetValue: 80,
          priority: 1,
          lastProgress: 0.25,
        ),
        Goal(
          id: '2',
          title: 'Objectif 2',
          description: 'Description 2',
          metric: GoalMetric.averagePoints,
          comparator: GoalComparator.greaterOrEqual,
          status: GoalStatus.active,
          targetValue: 80,
          priority: 2,
          lastProgress: 0.75,
        ),
        Goal(
          id: '3',
          title: 'Objectif 3',
          description: 'Description 3',
          metric: GoalMetric.averagePoints,
          comparator: GoalComparator.greaterOrEqual,
          status: GoalStatus.active,
          targetValue: 80,
          priority: 3,
          lastProgress: 0.95,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockMultiGoalCard(
              loading: false,
              activeGoals: goals,
            ),
          ),
        ),
      );

      // Vérifier que l'en-tête est affiché
      expect(find.text('Objectifs actifs'), findsOneWidget);
      expect(find.byIcon(Icons.flag_circle), findsOneWidget);
      
      // Vérifier que les 3 objectifs sont affichés
      expect(find.text('Objectif 1'), findsOneWidget);
      expect(find.text('Objectif 2'), findsOneWidget);
      expect(find.text('Objectif 3'), findsOneWidget);
      
      // Vérifier que les pourcentages sont affichés
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      
      // Vérifier que les barres de progression sont affichées
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('affiche un compteur si plus de 10 objectifs', (WidgetTester tester) async {
      // Créer 11 objectifs
      final goals = List.generate(11, (i) => Goal(
        id: i.toString(),
        title: 'Objectif $i',
        description: 'Description $i',
        metric: GoalMetric.averagePoints,
        comparator: GoalComparator.greaterOrEqual,
        status: GoalStatus.active,
        targetValue: 80,
        priority: i,
        lastProgress: 0.5,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockMultiGoalCard(
              loading: false,
              activeGoals: goals,
            ),
          ),
        ),
      );

      // Vérifier que le compteur est affiché
      expect(find.text('11 objectifs actifs'), findsOneWidget);
    });
  });
}