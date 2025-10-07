import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/shooting_session.dart';
import '../services/session_service.dart';
import '../services/stats_service.dart';
import '../services/rolling_stats_service.dart';
import '../repositories/hive_session_repository.dart';
import '../constants/session_constants.dart';
import '../services/stats_contract.dart';

/// Provider qui gère l'état et la logique métier de l'écran d'accueil (HomeScreen)
class HomeScreenProvider with ChangeNotifier {
  final SessionService _sessionService = SessionService();
  final RollingStatsService _rollingService = RollingStatsService(HiveSessionRepository());

  List<ShootingSession>? _sessions;
  StatsService? _statsService;
  bool _isLoading = true;
  String? _error;

  // Métriques calculées
  double _avgPoints30 = 0;
  double _avgGroup30 = 0;
  SeriesStat? _bestSerie;
  int _sessionsMonth = 0;
  double _consistency = 0;
  double _progression = 0;
  Map<double, int> _distDistrib = {};
  MapEntry<double, int>? _mostPlayedDistance;
  Map<String, int> _catDistrib = {};
  List<dynamic> _pointBuckets = [];
  int _streak = 0;
  bool _recordPoints = false;
  bool _recordGroup = false;
  int _loadDelta = 0;
  int _currentWeek = 0;
  double? _bestGroup;

  // Données pour les graphiques
  List<DateTime> _dates = [];
  List<FlSpot> _pointsSpots = [];
  List<FlSpot> _groupSizeSpots = [];
  List<FlSpot> _trendSpots = [];

  // Données pour les graphiques par type de prise
  List<DateTime> _dates1 = []; // 1 main
  List<FlSpot> _pts1 = []; // points 1 main
  List<FlSpot> _grp1 = []; // groupes 1 main
  List<DateTime> _dates2 = []; // 2 mains
  List<FlSpot> _pts2 = []; // points 2 mains
  List<FlSpot> _grp2 = []; // groupes 2 mains

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get avgPoints30 => _avgPoints30;
  double get avgGroup30 => _avgGroup30;
  SeriesStat? get bestSerie => _bestSerie;
  int get sessionsMonth => _sessionsMonth;
  double get consistency => _consistency;
  double get progression => _progression;
  Map<double, int> get distDistrib => _distDistrib;
  MapEntry<double, int>? get mostPlayedDistance => _mostPlayedDistance;
  Map<String, int> get catDistrib => _catDistrib;
  List<dynamic> get pointBuckets => _pointBuckets;
  int get streak => _streak;
  bool get recordPoints => _recordPoints;
  bool get recordGroup => _recordGroup;
  int get loadDelta => _loadDelta;
  int get currentWeek => _currentWeek;
  double? get bestGroup => _bestGroup;

  List<DateTime> get dates => _dates;
  List<FlSpot> get pointsSpots => _pointsSpots;
  List<FlSpot> get groupSizeSpots => _groupSizeSpots;
  List<FlSpot> get trendSpots => _trendSpots;

  List<DateTime> get dates1 => _dates1;
  List<FlSpot> get pts1 => _pts1;
  List<FlSpot> get grp1 => _grp1;
  List<DateTime> get dates2 => _dates2;
  List<FlSpot> get pts2 => _pts2;
  List<FlSpot> get grp2 => _grp2;

  HomeScreenProvider() {
    fetchSessions();
  }

  /// Récupère les sessions depuis le service et calcule les métriques
  Future<void> fetchSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allSessions = await _sessionService.getAllSessions();
      
      // Filtrer les sessions réalisées avec date non nulle
      _sessions = allSessions
          .where((s) => s.status == SessionConstants.statusRealisee && s.date != null)
          .toList();
      
      if (_sessions!.isEmpty) {
        _isLoading = false;
        _error = 'Aucune donnée pour les graphes.';
        notifyListeners();
        return;
      }

      _calculateMetrics();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Erreur lors du chargement des sessions: $e';
      notifyListeners();
    }
  }

  /// Calcule toutes les métriques pour l'affichage
  void _calculateMetrics() {
    if (_sessions == null || _sessions!.isEmpty) return;

    // Initialiser le service de stats
    _statsService = StatsService(_sessions!);

    // KPI & metrics de base (Synthèse)
    _avgPoints30 = _statsService!.averagePointsLast30Days();
    _avgGroup30 = _statsService!.averageGroupSizeLast30Days();
    _bestSerie = _statsService!.bestSeriesByPoints();
    _sessionsMonth = _statsService!.sessionsCountCurrentMonth();

    // Avancé metrics
    _consistency = _statsService!.consistencyIndexLast30Days();
    _progression = _statsService!.progressionPercent30Days();
    _distDistrib = _statsService!.distanceDistribution();
    _mostPlayedDistance = _distDistrib.isEmpty ? null : _distDistrib.entries.reduce((a,b)=> a.value>=b.value? a : b);
    _catDistrib = _statsService!.categoryDistribution();
    _pointBuckets = _statsService!.pointBuckets();
    _streak = _statsService!.currentDayStreak();
    _recordPoints = _statsService!.lastSeriesIsRecordPoints();
    _recordGroup = _statsService!.lastSeriesIsRecordGroup();
    _loadDelta = _statsService!.weeklyLoadDelta();
    _currentWeek = _statsService!.sessionsThisWeek();
    _bestGroup = _statsService!.bestGroupSize();

    // Séries: afficher les 30 dernières séries en ordre chrono ASC (ancien -> récent)
    final last30 = _statsService!.lastNSortedSeriesAsc(30);
    _dates = [];
    _pointsSpots = [];
    _groupSizeSpots = [];
    for (int i = 0; i < last30.length; i++) {
      final s = last30[i];
      _dates.add(s.date);
      _pointsSpots.add(FlSpot(i.toDouble(), s.points.toDouble()));
      _groupSizeSpots.add(FlSpot(i.toDouble(), s.groupSize.toDouble()));
    }

    // Préparation 1 main / 2 mains
    final List<Map<String, dynamic>> allSeriesFlatHand = [];
    final sessionsAsc = List<ShootingSession>.from(_sessions!)
      ..sort((a, b) => (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)));
    
    for (final session in sessionsAsc) {
      final d = session.date ?? DateTime(1970);
      for (final serie in session.series) {
        allSeriesFlatHand.add({
          'date': d,
          'points': serie.points.toDouble(),
          'group': serie.groupSize.toDouble(),
          'hand': serie.handMethod.name,
        });
      }
    }
    
    allSeriesFlatHand.sort((a,b)=> (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    final int nH = allSeriesFlatHand.length;
    final int startH = nH > 30 ? nH - 30 : 0;
    final last30Flat = allSeriesFlatHand.sublist(startH, nH);
    final oneHand = last30Flat.where((e)=> e['hand'] == 'oneHand').toList();
    final twoHands = last30Flat.where((e)=> e['hand'] == 'twoHands').toList();

    List<DateTime> _datesFrom(List<Map<String,dynamic>> list) => List.generate(list.length, (i)=> list[i]['date'] as DateTime);
    List<FlSpot> _pointsFrom(List<Map<String,dynamic>> list) => List.generate(list.length, (i)=> FlSpot(i.toDouble(), (list[i]['points'] as double)));
    List<FlSpot> _groupsFrom(List<Map<String,dynamic>> list) => List.generate(list.length, (i)=> FlSpot(i.toDouble(), (list[i]['group'] as double)));

    _dates1 = _datesFrom(oneHand);
    _pts1 = _pointsFrom(oneHand);
    _grp1 = _groupsFrom(oneHand);
    _dates2 = _datesFrom(twoHands);
    _pts2 = _pointsFrom(twoHands);
    _grp2 = _groupsFrom(twoHands);

    // Calculer la tendance (SMA3)
    final moving = _statsService!.movingAveragePoints(window: 3);
    _trendSpots = [];
    if (_pointsSpots.isNotEmpty && moving.isNotEmpty) {
      final take = _pointsSpots.length;
      final start = (moving.length - take) < 0 ? 0 : (moving.length - take);
      for (int i = 0; i < take && (start + i) < moving.length; i++) {
        _trendSpots.add(FlSpot(_pointsSpots[i].x, moving[start + i]));
      }
    }
  }

  /// Calcule les statistiques de progression sur 30/60 jours
  Future<RollingStatsSnapshot> getRollingStats() async {
    return await _rollingService.compute();
  }
}