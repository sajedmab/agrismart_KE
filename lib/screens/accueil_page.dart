import 'package:flutter/material.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/screens/zone_detail_page.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => AccueilPageState();
}

class AccueilPageState extends State<AccueilPage> {
  final List<Zone> _zones = jeuDeDonnees();

  int _nombreZonesAIrriguer() {
    return _zones.where((z) => z.humidite < 35.0).length;
  }

  Future<void> _ouvrirFormulaire({Zone? zone}) async {
    final nouvelleZone = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneFormPage(
          zone: zone,
          nomsExistants: _zones
              .where((z) => z != zone)
              .map((z) => z.nom)
              .toList(),
        ),
      ),
    );

    if (nouvelleZone == null || !mounted) return;

    setState(() {
      if (zone == null) {
        _zones.add(nouvelleZone);
      } else {
        final index = _zones.indexOf(zone);
        if (index != -1) {
          _zones[index] = nouvelleZone;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(zone == null ? 'Zone ajoutée' : 'Zone modifiée'),
      ),
    );
  }

  Future<void> _ouvrirDetail(Zone zone) async {
    final zoneModifiee = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(
          zone: zone,
          nomsAutres: _zones
              .where((z) => z != zone)
              .map((z) => z.nom)
              .toList(),
        ),
      ),
    );

    if (zoneModifiee == null || !mounted) return;

    setState(() {
      final index = _zones.indexOf(zone);
      if (index != -1) {
        _zones[index] = zoneModifiee;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int zonesAIrriguer = _nombreZonesAIrriguer();
    final String zonePrincipale =
    _zones.isNotEmpty ? _zones.first.nom : 'Parcelle Nord';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: AgriSmart + icônes à droite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.eco, color: Color(0xFF4CAF50), size: 32),
                      SizedBox(width: 6),
                      Text(
                        'AgriSmart',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3E7B3A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFFE88D2A),
                          size: 24,
                        ),
                        onPressed: () {
                          // TODO: ouvrir notifications / alertes
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFFE88D2A),
                          size: 26,
                        ),
                        onPressed: () {
                          // TODO: ouvrir profil
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Carte "Aujourd'hui / Lundi 23 Nov" + nom & parcelle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Aujourd'hui",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Lundi 23 Nov',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ahmed Ben Ali',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '- $zonePrincipale',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 3. Deux cartes côte à côte: Météo Kébili + Alerte
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Météo Kébili',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '32°C',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: Color(0xFFEAB308),
                                size: 32,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (_zones.isNotEmpty) {
                          _ouvrirDetail(_zones.first);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alerte',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              zonesAIrriguer == 1
                                  ? '1 parcelle à\nirriguer'
                                  : '$zonesAIrriguer parcelles à\nirriguer',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Grille 2x3 des 6 boutons verts
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _BoutonVert(
                    icon: Icons.smart_toy_outlined,
                    label: 'Assistant IA',
                    onTap: () => _afficherMessage('Assistant IA'),
                  ),
                  _BoutonVert(
                    icon: Icons.center_focus_weak,
                    label: 'Scanner Étiquette',
                    onTap: () => _afficherMessage('Scanner Étiquette'),
                  ),
                  _BoutonVert(
                    icon: Icons.plumbing_outlined,
                    label: 'Équipements',
                    onTap: () => _afficherMessage('Équipements'),
                  ),
                  _BoutonVert(
                    icon: Icons.calendar_today_outlined,
                    label: 'Calendrier',
                    onTap: () => _afficherMessage('Calendrier'),
                  ),
                  _BoutonVert(
                    icon: Icons.menu_book_outlined,
                    label: "Journal d'activités",
                    onTap: () => _afficherMessage("Journal d'activités"),
                  ),
                  _BoutonVert(
                    icon: Icons.description_outlined,
                    label: 'Guides & Rapports',
                    onTap: () => _afficherMessage('Guides & Rapports'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Carte "Tâches à venir"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tâches à venir',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(
                          Icons.shopping_basket_outlined,
                          color: Color(0xFFC2410C),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Récolte Tomates - dans 5 jours',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF56A832),
        onPressed: () => _ouvrirFormulaire(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _afficherMessage(String nom) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ouverture : $nom')),
    );
  }
}

class _BoutonVert extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BoutonVert({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF56A832),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}