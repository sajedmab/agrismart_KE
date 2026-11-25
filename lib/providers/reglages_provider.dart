import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReglagesProvider extends ChangeNotifier {
  static const String _cleTheme = 'theme';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  // La valeur initiale est lue dès la création
  ReglagesProvider(this._prefs) : _themeMode = _lireTheme(_prefs);

  ThemeMode get themeMode => _themeMode;

  // Relit le thème enregistré ('light', 'dark' ou 'system')
  static ThemeMode _lireTheme(SharedPreferences prefs) {
    // TODO 1 : récupère la valeur enregistrée (peut être null)
    final String? nom = prefs.getString(_cleTheme);

    // Si rien n'est enregistré, on garde le thème système par défaut
    if (nom == null) return ThemeMode.system;

    // On renvoie le ThemeMode correspondant, ou system par défaut
    return ThemeMode.values.firstWhere(
          (e) => e.name == nom,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> changerTheme(ThemeMode mode) async {
    // Évite un rebuild inutile si le thème est déjà celui demandé
    if (_themeMode == mode) return;

    // TODO 2 : met à jour l'état en mémoire et notifie l'UI
    _themeMode = mode;
    notifyListeners();

    // TODO 3 : enregistre le choix pour le prochain démarrage
    try {
      await _prefs.setString(_cleTheme, mode.name);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du thème : $e');
    }
  }
}