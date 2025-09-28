import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet affichant deux onglets:
///  - Sécurité: 3 règles essentielles 
///  - Technique: 5 fondamentaux (posture, respiration, visée, lâcher, suivi)
class RulesBottomSheet extends StatelessWidget {
  const RulesBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RulesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.only(top: 12),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Rappels Essentiels', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TabBar(
                  labelColor: Colors.amberAccent,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.amberAccent,
                  tabs: const [
                    Tab(icon: Icon(Icons.shield), text: 'Sécurité'),
                    Tab(icon: Icon(Icons.center_focus_strong), text: 'Tir'),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    children: [
                      _RulesList(
                        controller: controller,
                        title: '3 Règles de Sécurité essentielles',
                        icon: Icons.shield,
                        color: Colors.redAccent,
                        rules: const [
                          'Toujours considérer une arme comme chargée.',
                          'Ne jamais pointer le canon vers quelque chose que l’on ne veut pas atteindre.',
                          'Garder le doigt hors de la détente tant que les organes de visée ne sont pas sur la cible.',
                        ],
                      ),
                      _RulesList(
                        controller: controller,
                        title: '5 Fondamentaux du Tir',
                        icon: Icons.adjust,
                        color: Colors.lightBlueAccent,
                        rules: const [
                          'Posture stable et équilibrée (ancrage, centre de gravité neutre).',
                          'Respiration contrôlée (lâcher durant la pause respiratoire).',
                          'Visée: alignement régulier, focalisation sur le guidon / point de mire.',
                          'Lâcher progressif et sans à-coup (pression linéaire sur la détente).',
                          'Suivi (follow-through): maintenir visée et position après le départ du coup.',
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _FftirPdfButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RulesList extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> rules;
  final ScrollController controller;
  const _RulesList({required this.title, required this.icon, required this.color, required this.rules, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          ],
        ),
        const SizedBox(height: 12),
        ...rules.asMap().entries.map((e) => _RuleTile(index: e.key + 1, text: e.value, accent: color)).toList(),
        const SizedBox(height: 16),
        Text('Ces principes doivent être intégrés de manière consciente puis automatisée pour une progression durable.', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  final int index;
  final String text;
  final Color accent;
  const _RuleTile({required this.index, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: accent.withOpacity(0.18),
          child: Text('$index', style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
        ),
        title: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.25)),
      ),
    );
  }
}

class _FftirPdfButton extends StatelessWidget {
  final Uri _url = Uri.parse('https://www.fftir.org/les-regles-de-securite/');
  _FftirPdfButton();

  Future<void> _open(BuildContext context) async {
    try {
      final ok = await launchUrl(_url, mode: LaunchMode.externalApplication);
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le PDF.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ouverture: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amberAccent.withOpacity(0.15),
          foregroundColor: Colors.amberAccent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
  icon: const Icon(Icons.open_in_new),
  label: const Text('Voir les règles officielles FFTir', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _open(context),
      ),
    );
  }
}

