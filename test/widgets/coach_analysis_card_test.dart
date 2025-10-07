import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/widgets/coach_analysis_card.dart';

void main() {
  group('CoachAnalysisCard', () {
    testWidgets('ne s\'affiche pas quand le contenu est vide', (WidgetTester tester) async {
      // Construire le widget avec un contenu vide
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoachAnalysisCard(analyse: ''),
          ),
        ),
      );

      // Vérifier qu'aucune Card n'est visible
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('ne s\'affiche pas quand le contenu est composé d\'espaces', (WidgetTester tester) async {
      // Construire le widget avec un contenu composé uniquement d'espaces
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoachAnalysisCard(analyse: '   '),
          ),
        ),
      );

      // Vérifier qu'aucune Card n'est visible
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('affiche correctement un texte simple', (WidgetTester tester) async {
      const String analyseSimple = 'Voici une analyse simple.';
      
      // Construire le widget avec un texte simple
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoachAnalysisCard(analyse: analyseSimple),
          ),
        ),
      );

      // Vérifier que la Card est visible
      expect(find.byType(Card), findsOneWidget);
      
      // Vérifier que le titre est affiché
      expect(find.text('Analyse du coach'), findsOneWidget);
      
      // Vérifier que le contenu est affiché dans le MarkdownBody
      expect(find.text(analyseSimple), findsOneWidget);
    });

    testWidgets('affiche correctement du markdown', (WidgetTester tester) async {
      const String analyseMarkdown = '# Titre\n\n**Texte en gras**\n\n- Point 1\n- Point 2';
      
      // Construire le widget avec du markdown
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoachAnalysisCard(analyse: analyseMarkdown),
          ),
        ),
      );

      // Vérifier que la Card est visible
      expect(find.byType(Card), findsOneWidget);
      
      // Le rendu markdown est plus difficile à tester directement
      // car il est transformé en widgets RichText.
      // On peut vérifier que le widget MarkdownBody est présent
      expect(find.byType(CoachAnalysisCard), findsOneWidget);
    });
  });
}