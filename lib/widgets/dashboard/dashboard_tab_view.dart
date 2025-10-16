import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/shooting_session.dart';
import '../../models/series.dart';
import '../../services/dashboard_service.dart';
import '../../models/dashboard_data.dart';
import 'stats_summary_cards.dart';
import 'evolution_chart.dart';
import 'flat_distribution_bar.dart';
import 'points_histogram_chart.dart';
import 'advanced_stats_cards.dart';
import 'evolution_comparison_widget.dart';
import 'correlation_scatter_chart.dart';

/// Widget principal du dashboard avec onglets Synthèse/Avancé
class DashboardTabView extends StatefulWidget {
  final List<ShootingSession> sessions;
  
  const DashboardTabView({
    super.key,
    required this.sessions,
  });

  @override
  State<DashboardTabView> createState() => _DashboardTabViewState();
}

class _DashboardTabViewState extends State<DashboardTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DashboardService _dashboardService;
  
  bool _isLoading = true;
  DashboardSummary? _summary;
  EvolutionData? _scoreEvolution;
  EvolutionData? _groupSizeEvolution;
  DistributionData? _categoryDistribution;
  PointsHistogramData? _pointsHistogram;
  DistributionData? _distanceDistribution;
  
  // Données avancées
  AdvancedStatsData? _advancedStats;
  EvolutionComparisonData? _evolutionComparison;
  CorrelationData? _correlationData;
  EvolutionData? _oneHandPointsData;
  EvolutionData? _oneHandGroupSizeData;
  EvolutionData? _twoHandsPointsData;
  EvolutionData? _twoHandsGroupSizeData;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dashboardService = DashboardService(widget.sessions);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Données onglet Synthèse
      final summary = _dashboardService.generateSummary();
      final scoreEvolution = _dashboardService.generateScoreEvolution();
      final groupSizeEvolution = _dashboardService.generateGroupSizeEvolution();
      final categoryDistribution = _dashboardService.generateCategoryDistribution();
      final pointsHistogram = _dashboardService.generatePointsDistribution();
      final distanceDistribution = _dashboardService.generateDistanceDistribution();
      
      // Données onglet Avancé
      final advancedStats = _dashboardService.generateAdvancedStats();
      final evolutionComparison = _dashboardService.generateEvolutionComparison();
      final correlationData = _dashboardService.generateCorrelationData();
      final oneHandPointsData = _dashboardService.generateHandSpecificPointsEvolution(HandMethod.oneHand);
      final oneHandGroupSizeData = _dashboardService.generateHandSpecificGroupSizeEvolution(HandMethod.oneHand);
      final twoHandsPointsData = _dashboardService.generateHandSpecificPointsEvolution(HandMethod.twoHands);
      final twoHandsGroupSizeData = _dashboardService.generateHandSpecificGroupSizeEvolution(HandMethod.twoHands);
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _scoreEvolution = scoreEvolution;
          _groupSizeEvolution = groupSizeEvolution;
          _categoryDistribution = categoryDistribution;
          _pointsHistogram = pointsHistogram;
          _distanceDistribution = distanceDistribution;
          
          // Données avancées
          _advancedStats = advancedStats;
          _evolutionComparison = evolutionComparison;
          _correlationData = correlationData;
          _oneHandPointsData = oneHandPointsData;
          _oneHandGroupSizeData = oneHandGroupSizeData;
          _twoHandsPointsData = twoHandsPointsData;
          _twoHandsGroupSizeData = twoHandsGroupSizeData;
          
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $error')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(text: 'Synthèse'),
            Tab(text: 'Avancé'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSyntheseTab(),
              _buildAvanceTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSyntheseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 5 cartes de récapitulatif
          StatsSummaryCards(
            summary: _summary ?? const DashboardSummary.empty(),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 24),
          
          // Evolution Score
          EvolutionChart(
            data: _scoreEvolution ?? const EvolutionData.empty('Évolution Score', 'pts'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Evolution Groupement
          EvolutionChart(
            data: _groupSizeEvolution ?? const EvolutionData.empty('Évolution Groupement', 'cm'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Répartition catégories - flat bar segmentée
          FlatDistributionBar(
            data: _categoryDistribution ?? const DistributionData.empty('Répartition Catégories'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Distribution points
          PointsHistogramChart(
            data: _pointsHistogram ?? const PointsHistogramData.empty('Distribution Points'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Répartition distances - flat bar segmentée
          FlatDistributionBar(
            data: _distanceDistribution ?? const DistributionData.empty('Répartition Distances'),
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cartes statistiques avancées
          AdvancedStatsCards(
            data: _advancedStats,
            summary: _summary ?? const DashboardSummary.empty(),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Évolution 30j vs 90j
          EvolutionComparisonWidget(
            data: _evolutionComparison,
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Corrélation Points/Groupement
          CorrelationScatterChart(
            data: _correlationData,
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Points - 1 main
          EvolutionChart(
            data: _oneHandPointsData ?? const EvolutionData.empty('Points - 1 main', 'pts'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Groupement - 1 main
          EvolutionChart(
            data: _oneHandGroupSizeData ?? const EvolutionData.empty('Groupement - 1 main', 'cm'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Points - 2 mains
          EvolutionChart(
            data: _twoHandsPointsData ?? const EvolutionData.empty('Points - 2 mains', 'pts'),
            isLoading: _isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Groupement - 2 mains
          EvolutionChart(
            data: _twoHandsGroupSizeData ?? const EvolutionData.empty('Groupement - 2 mains', 'cm'),
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}