
import 'package:flutter/foundation.dart';
import 'package:agrismart/models/meteo.dart';
import 'package:agrismart/services/meteo_service.dart';

// Les trois états du chargement
enum EtatMeteo { chargement, succes, erreur }

class MeteoProvider extends ChangeNotifier {
  final MeteoService _service;

  MeteoProvider({MeteoService? service})
      : _service = service ?? MeteoService();

  EtatMeteo _etat = EtatMeteo.chargement;

  Meteo? _meteo;
  String _erreur = '';

  EtatMeteo get etat => _etat;
  Meteo? get meteo => _meteo;
  String get erreur => _erreur;

  Future<void> charger() async {
    // TODO 1 : commencer le chargement
    _etat = EtatMeteo.chargement;
    notifyListeners();

    try {
      // TODO 2 : récupérer la météo
      _meteo = await _service.charger();
      _etat = EtatMeteo.succes;
      _erreur = '';
    } on MeteoException catch (e) {
      // TODO 3 : gérer l'erreur
      _erreur = e.message;
      _etat = EtatMeteo.erreur;
    } catch (_) {
      _erreur = 'Erreur inattendue';
      _etat = EtatMeteo.erreur;
    }

    notifyListeners();
  }
}
