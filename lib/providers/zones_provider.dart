import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/auth_provider.dart';

class ZonesProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AuthProvider _auth;
  final List<Zone> _zones = [];
  String? _uid;

  ZonesProvider(this._prefs, this._auth) {
    _auth.addListener(_surChangementUtilisateur);
    _actualiser();
  }

  List<Zone> get zones => List.unmodifiable(_zones);
  int get nombre => _zones.length;
  int get nombreAirriguer => _zones.where((z) => z.besoinIrrigation).length;

  List<String> noms({Zone? sauf}) {
    return _zones.where((z) => z != sauf).map((z) => z.nom).toList();
  }

  String _cle(String uid) => 'zones_$uid';

  List<Zone> _lire(String uid) {
    final texte = _prefs.getString(_cle(uid));
    if (texte == null) return jeuDeDonnees();
    try {
      final liste = jsonDecode(texte) as List<dynamic>;
      return liste.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return jeuDeDonnees();
    }
  }

  void _sauvegarder() {
    final uid = _uid;
    if (uid == null) return;
    final texte = jsonEncode(_zones.map((z) => z.toJson()).toList());
    _prefs.setString(_cle(uid), texte);
  }

  bool _actualiser() {
    final uid = _auth.utilisateur?.uid;
    if (uid == _uid) return false;
    _uid = uid;
    _zones.clear();
    if (uid != null) _zones.addAll(_lire(uid));
    return true;
  }

  void _surChangementUtilisateur() {
    if (_actualiser()) notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }

  void modifierHumidite(Zone zone, double delta) {
    zone.humidite = (zone.humidite + delta).clamp(0.0, 100.0).toDouble();
    _sauvegarder();
    notifyListeners();
  }

  void ajouter(Zone zone) {
    _zones.add(zone);
    _sauvegarder();
    notifyListeners();
  }

  void remplacer(Zone ancienne, Zone nouvelle) {
    final index = _zones.indexOf(ancienne);
    if (index == -1) return;
    _zones[index] = nouvelle;
    _sauvegarder();
    notifyListeners();
  }

  void supprimer(Zone zone) {
    _zones.remove(zone);
    _sauvegarder();
    notifyListeners();
  }
}