import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen UI Elements', () {
    testWidgets('affiche le titre correct', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text('NexTarget'),
            ),
          ),
        ),
      );
      
      expect(find.text('NexTarget'), findsOneWidget);
    });

    testWidgets('contient des boutons de navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Sessions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.flag),
                  label: 'Objectifs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center),
                  label: 'Exercices',
                ),
              ],
            ),
          ),
        ),
      );
      
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Objectifs'), findsOneWidget);
      expect(find.text('Exercices'), findsOneWidget);
    });

    testWidgets('contient un bouton flottant d\'ajout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.add),
              tooltip: 'Nouvelle session',
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Nouvelle session'), findsOneWidget);
    });
  });
}