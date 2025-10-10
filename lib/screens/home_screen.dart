import 'package:flutter/material.dart';
import '../widgets/rules_bottom_sheet.dart';
import '../widgets/dashboard/dashboard_tab_view.dart';
import '../services/session_service.dart';
import '../models/shooting_session.dart';

/// Écran tableau de bord avec statistiques
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionService _sessionService = SessionService();
  List<ShootingSession> _sessions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }
  
  Future<void> _loadSessions() async {
    try {
      final sessions = await _sessionService.getAllSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Règles & fondamentaux',
            onPressed: () => RulesBottomSheet.show(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DashboardTabView(sessions: _sessions),
    );
  }
}