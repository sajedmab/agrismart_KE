
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/theme/app_theme.dart';

import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/widgets/meteo_card.dart';

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ZonesProvider>().zones;

    final tri = [...zones]
      ..sort((a, b) => a.humidite.compareTo(b.humidite));

    final aIrriguer =
        zones.where((zone) => zone.besoinIrrigation).length;

    final pourcentage = zones.isEmpty
        ? 0
        : (aIrriguer * 100 / zones.length).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Statistiques'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte météo de Kébili
          const MeteoCard(),

          const SizedBox(height: 16),

          if (zones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Aucune donnée à afficher'),
              ),
            )
          else ...[
            ResumeExploitation(zones: zones),

            const SizedBox(height: 16),

            Text(
              '$aIrriguer zone(s) sur ${zones.length} à irriguer ($pourcentage %)',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 24),

            Text(
              'Humidité par zone',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            ...tri.map(
                  (zone) => ListTile(
                title: Text(zone.nom),
                subtitle: LinearProgressIndicator(
                  value: zone.humidite / 100,
                  color: zone.besoinIrrigation
                      ? AppTheme.echec
                      : AppTheme.succes,
                ),
                trailing: Text(
                  '${zone.humidite.toStringAsFixed(0)} %',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
