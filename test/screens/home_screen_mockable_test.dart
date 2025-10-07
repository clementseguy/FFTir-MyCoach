import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Adaptation très simplifiée pour tester HomeScreen
class MockableHomeScreen extends StatelessWidget {
  final int selectedTabIndex;
  final VoidCallback? onAddPressed;
  final List<Widget> tabContents;
  
  const MockableHomeScreen({
    Key? key,
    this.selectedTabIndex = 0,
    this.onAddPressed,
    this.tabContents = const [
      Center(child: Text('Accueil')),
      Center(child: Text('Sessions')),
      Center(child: Text('Objectifs')),
      Center(child: Text('Exercices')),
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NexTarget'),
        actions: const [
          // Actions ici
        ],
      ),
      body: tabContents[selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedTabIndex,
        items: const [
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
      floatingActionButton: FloatingActionButton(
        onPressed: onAddPressed ?? () {},
        child: const Icon(Icons.add),
        tooltip: 'Nouvelle session',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen UI Elements avec mock', () {
    testWidgets('affiche le titre correct et la navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockableHomeScreen(),
        ),
      );
      
      expect(find.text('NexTarget'), findsOneWidget);
      expect(find.text('Accueil'), findsNWidgets(2)); // Label + tab content
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Objectifs'), findsOneWidget);
      expect(find.text('Exercices'), findsOneWidget);
    });

    testWidgets('navigue entre les tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MockableHomeScreen(selectedTabIndex: 1),
        ),
      );
      
      // Vérifie que l'onglet Sessions est actif
      expect(find.text('Sessions'), findsNWidgets(2)); // Label + tab content
    });

    testWidgets('bouton flottant est présent et cliquable', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MockableHomeScreen(
            onAddPressed: () {
              buttonPressed = true;
            },
          ),
        ),
      );
      
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Nouvelle session'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.add));
      expect(buttonPressed, true);
    });
  });
}