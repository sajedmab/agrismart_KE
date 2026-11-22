
import 'package:flutter/foundation.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';

class ZonesProvider extends ChangeNotifier {
  final List<Zone> _zones = jeuDeDonnees();

  List<Zone> get zones => List.unmodifiable(_zones);

  int get nombre => _zones.length;

  int get nombreAIrriguer =>
      _zones.where((zone) => zone.besoinIrrigation).length;

  List<String> noms({Zone? sauf}) {
    return _zones
        .where((zone) => zone != sauf)
        .map((zone) => zone.nom)
        .toList();
  }

  void modifierHumidite(Zone zone, double delta) {
    zone.humidite =
        (zone.humidite + delta).clamp(0.0, 100.0).toDouble();
    notifyListeners();
  }

  void ajouter(Zone zone) {
    _zones.add(zone);
    notifyListeners();
  }

  void remplacer(Zone ancienne, Zone nouvelle) {
    final index = _zones.indexOf(ancienne);
    if (index == -1) return;

    _zones[index] = nouvelle;
    notifyListeners();
  }

  void supprimer(Zone zone) {
    _zones.remove(zone);
    notifyListeners();
  }
}
