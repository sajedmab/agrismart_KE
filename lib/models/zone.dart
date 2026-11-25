class Zone {
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  bool vanneOuverte;

  Zone(
      this.nom,
      this.culture,
      this.humidite,
      this.seuil, {
        this.vanneOuverte = false,
      });

  // Vrai si l'humidité est sous le seuil
  bool get besoinIrrigation => humidite < seuil;

  // ==========================================
  // AJOUT POUR LE TP 8 (Section 3.1)
  // ==========================================

  // Conversion en JSON (pour l'enregistrer sur l'appareil)
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'culture': culture,
      'humidite': humidite,
      'seuil': seuil,
      'vanneOuverte': vanneOuverte,
    };
  }

  // Reconstruit une zone a partir d'un JSON
  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      json['nom'] as String,
      json['culture'] as String,
      (json['humidite'] as num).toDouble(),
      (json['seuil'] as num).toDouble(),
      vanneOuverte: (json['vanneOuverte'] as bool?) ?? false,
    );
  }
}

// ==========================================
// FONCTIONS UTILITAIRES (en dehors de la classe)
// ==========================================

// Humidité moyenne d'une liste de zones (0 si la liste est vide)
double humiditeMoyenne(List<Zone> zones) {
  if (zones.isEmpty) return 0;
  double somme = 0;
  for (final z in zones) {
    somme += z.humidite;
  }
  return somme / zones.length;
}

// Message de diagnostic pour une zone
String diagnostic(Zone zone) {
  if (zone.besoinIrrigation) {
    return "Besoin d'irrigation";
  }
  return 'Sol correct';
}