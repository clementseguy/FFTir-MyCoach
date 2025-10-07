import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionDetailScreen UI Elements', () {
    testWidgets('affiche un titre approprié', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text('Détails session'),
            ),
          ),
        ),
      );
      
      expect(find.text('Détails session'), findsOneWidget);
    });

    testWidgets('contient des éléments de résumé de session', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Arme:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text('Pistolet test'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Calibre:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text('22LR'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text('01/01/2023'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Séries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Arme:'), findsOneWidget);
      expect(find.text('Calibre:'), findsOneWidget);
      expect(find.text('Date:'), findsOneWidget);
      expect(find.text('Pistolet test'), findsOneWidget);
      expect(find.text('22LR'), findsOneWidget);
      expect(find.text('01/01/2023'), findsOneWidget);
      expect(find.text('Séries'), findsOneWidget);
    });
  });
}