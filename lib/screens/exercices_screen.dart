import 'package:flutter/material.dart';
import '../widgets/goals_at_glance_card.dart';
import '../widgets/exercises_at_glance_card.dart';

class ExercicesScreen extends StatefulWidget {
  @override
  State<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends State<ExercicesScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercices & Objectifs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GoalsAtGlanceCard(),
          const SizedBox(height: 16),
          const ExercisesAtGlanceCard(),
        ],
      ),
    );
  }
}