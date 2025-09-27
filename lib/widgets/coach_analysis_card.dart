import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Carte affichant l'analyse du coach rendue en markdown.
/// N'affiche rien si le contenu est vide.
class CoachAnalysisCard extends StatelessWidget {
  final String analyse;
  const CoachAnalysisCard({super.key, required this.analyse});

  @override
  Widget build(BuildContext context) {
    if (analyse.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.green[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analyse du coach', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            MarkdownBody(
              data: analyse,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white),
                strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                h1: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                code: TextStyle(color: Colors.yellow[200]),
                blockquote: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                listBullet: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
