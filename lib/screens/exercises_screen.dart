import 'package:flutter/material.dart';
import '../widgets/goals_at_glance_card.dart';
import '../widgets/exercises_at_glance_card.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercices & Objectifs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          GoalsAtGlanceCard(),
          SizedBox(height: 16),
          ExercisesAtGlanceCard(),
        ],
      ),
    );
  }
}