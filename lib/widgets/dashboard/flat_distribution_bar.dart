import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/mobile_utils.dart';

/// Widget affichant une barre de répartition unique segmentée par pourcentages
/// Remplace les barres individuelles pour une meilleure UX
class FlatDistributionBar extends StatelessWidget {
  final DistributionData data;
  final bool isLoading;

  const FlatDistributionBar({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(MobileUtils.isMobile(context) ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              _buildLoadingState()
            else if (data.data.isEmpty)
              _buildEmptyState(context)
            else
              _buildFlatBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 60,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Calcul des répartitions...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 60,
      child: Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFlatBar(BuildContext context) {
    final total = data.data.values.reduce((a, b) => a + b);
    if (total == 0) return _buildEmptyState(context);

    // Calcul des pourcentages
    final List<SegmentData> segments = [];
    final entries = data.data.entries.toList();
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percentage = (entry.value / total) * 100;
      if (percentage > 0) { // Ne montrer que les segments avec des données
        segments.add(SegmentData(
          label: entry.key,
          value: entry.value,
          percentage: percentage,
          color: _getSegmentColor(i),
        ));
      }
    }

    return Column(
      children: [
        // Barre segmentée
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: segments.map((segment) {
                return Flexible(
                  flex: segment.percentage.round(),
                  child: Container(
                    height: 24,
                    color: segment.color,
                    child: Center(
                      child: segment.percentage > 15 // Afficher le % seulement si assez de place
                          ? Text(
                              '${segment.percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Légende avec détails
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: segments.map((segment) {
            // Ne pas afficher les pourcentages dans la légende
            final valueText = data.isPercentage 
                ? '' // Pas de pourcentage affiché
                : '${segment.value.toInt()}'; // Juste la valeur brute
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: segment.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  segment.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Afficher la valeur seulement si elle n'est pas vide
                if (valueText.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    valueText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Retourne une couleur pour chaque segment selon le type de répartition
  /// Palette selon les spécifications utilisateur : bleu/vert/orange
  Color _getSegmentColor(int index) {
    // Couleurs spécifiques pour les catégories de séances
    if (data.title.contains('Catégorie') || data.title.contains('catégorie')) {
      final categoryColors = [
        Colors.blueAccent,              // Match - bleu comme spécifié
        const Color(0xFF16FF8B),        // Entraînement - vert des boutons (neon green)
        Colors.orange,                  // Test matériel - jaune-orangé comme spécifié
      ];
      return categoryColors[index % categoryColors.length];
    }
    
    // Couleurs spécifiques pour les distances
    if (data.title.contains('Distance') || data.title.contains('distance')) {
      final distanceColors = [
        Colors.blueAccent,              // Distance 1 - bleu
        const Color(0xFF16FF8B),        // Distance 2 - vert des boutons
        Colors.orange,                  // Distance 3 - orange
      ];
      return distanceColors[index % distanceColors.length];
    }
    
    // Palette par défaut cohérente avec le thème pour autres répartitions
    final defaultColors = [
      Colors.blueAccent,         // Bleu principal
      const Color(0xFF16FF8B),   // Vert du thème (neon green)
      Colors.orange,             // Orange
      Colors.amber,              // Couleur primaire de l'app
      Colors.teal,               // Couleur secondaire
      Colors.deepPurple,         // Accent violet
      Colors.indigo,             // Variation de bleu
      Colors.cyan,               // Variation de teal
      Colors.lightBlue,          // Couleur douce
      Colors.blueGrey,           // Couleur neutre
    ];
    return defaultColors[index % defaultColors.length];
  }
}

/// Données d'un segment de la barre de répartition
class SegmentData {
  final String label;
  final double value;
  final double percentage;
  final Color color;

  const SegmentData({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });
}