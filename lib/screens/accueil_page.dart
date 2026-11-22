
import 'package:flutter/material.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/widgets/zone_card.dart';
import 'package:agrismart/widgets/fiche_exploitation.dart';
import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/screens/zone_detail_page.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => AccueilPageState();
}

class AccueilPageState extends State<AccueilPage> {
  final List<Zone> _zones = jeuDeDonnees();

  double _humiditeMoyenne() {
    if (_zones.isEmpty) return 0;

    final total = _zones.fold<double>(
      0,
          (somme, zone) => somme + zone.humidite,
    );

    return total / _zones.length;
  }

  void _modifierHumidite(Zone zone, double delta) {
    setState(() {
      zone.humidite =
          (zone.humidite + delta).clamp(0.0, 100.0);
    });
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
        content: Text(
          zone == null ? 'Zone ajoutée' : 'Zone modifiée',
        ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zone modifiée'),
      ),
    );
  }

  Future<void> _confirmerSuppression(Zone zone) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la zone'),
        content: Text(
          'Voulez-vous vraiment supprimer la zone "${zone.nom}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmer != true || !mounted) return;

    setState(() {
      _zones.remove(zone);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zone "${zone.nom}" supprimée'),
      ),
    );
  }

  Widget _carte(Zone zone) {
    return ZoneCard(
      zone: zone,
      onAugmenter: () => _modifierHumidite(zone, 5),
      onDiminuer: () => _modifierHumidite(zone, -5),
      onTap: () => _ouvrirDetail(zone),
      onLongPress: () => _confirmerSuppression(zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSmart'),
      ),
      body: Column(
        children: [
          FicheExploitation(
            humiditeMoyenne: _humiditeMoyenne(),
          ),
          ResumeExploitation(zones: _zones),
          Expanded(
            child: LayoutBuilder(
              builder: (context, contraintes) {
                if (contraintes.maxWidth >= 600) {
                  return GridView.builder(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 16,
                    ),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _zones.length,
                    itemBuilder: (context, index) {
                      return _carte(_zones[index]);
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 16,
                  ),
                  itemCount: _zones.length,
                  itemBuilder: (context, index) {
                    return _carte(_zones[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirFormulaire(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
