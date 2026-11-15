import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TutorialStage { loading, home, navigation, bookDetails, completed }

class TutorialState {
  final TutorialStage stage;
  final bool hasSeenHome;
  final bool hasSeenNav;
  final bool hasSeenDetails;

  TutorialState({
    required this.stage, 
    required this.hasSeenHome,
    required this.hasSeenNav,
    required this.hasSeenDetails,
  });
}

class TutorialNotifier extends StateNotifier<TutorialState> {
  TutorialNotifier() : super(TutorialState(
    stage: TutorialStage.loading, 
    // Iniciamos en false para que el sistema sepa que "falta info"
    hasSeenHome: false, 
    hasSeenNav: false,
    hasSeenDetails: false,
  )) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _updateStateFromPrefs(prefs);
  }

  Future<void> completeHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenHomeScreenTutorial', true);
    _updateStateFromPrefs(prefs);
  }

  Future<void> completeNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenNavTutorial', true);
    _updateStateFromPrefs(prefs);
  }

  Future<void> completeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenDetailsTutorial', true);
    _updateStateFromPrefs(prefs);
  }

  void _updateStateFromPrefs(SharedPreferences prefs) {
    // Si el valor es null, significa que es la primera vez (false)
    final homeSeen = prefs.getBool('hasSeenHomeScreenTutorial') ?? false;
    final navSeen = prefs.getBool('hasSeenNavTutorial') ?? false;
    final detailsSeen = prefs.getBool('hasSeenDetailsTutorial') ?? false;

    TutorialStage currentStage;
    
    // Máquina de estados: El orden importa
    if (!homeSeen) {
      currentStage = TutorialStage.home;
    } else if (!navSeen) {
      currentStage = TutorialStage.navigation;
    } else if (!detailsSeen) {
      currentStage = TutorialStage.bookDetails;
    } else {
      currentStage = TutorialStage.completed;
    }

    state = TutorialState(
      stage: currentStage,
      hasSeenHome: homeSeen,
      hasSeenNav: navSeen,
      hasSeenDetails: detailsSeen,
    );
  }

  Future<void> resetTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSeenHomeScreenTutorial');
    await prefs.remove('hasSeenNavTutorial');
    await prefs.remove('hasSeenDetailsTutorial');
    _updateStateFromPrefs(prefs);
  }
}

final tutorialProvider = StateNotifierProvider<TutorialNotifier, TutorialState>((ref) => TutorialNotifier());