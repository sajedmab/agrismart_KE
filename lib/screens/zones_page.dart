
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zone_detail_page.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/widgets/zone_card.dart';

class ZonesPage extends StatelessWidget {
  const ZonesPage({super.key});

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  Future<void> _ajouter(BuildContext context) async {
    final noms = context.read<ZonesProvider>().noms();

    final nouvelle = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneFormPage(
          nomsExistants: noms,
        ),
      ),
    );

    if (nouvelle == null || !context.mounted) return;

    context.read<ZonesProvider>().ajouter(nouvelle);
    _message(context, 'Zone ajoutée');
  }

  Future<void> _ouvrirDetail(
      BuildContext context,
      Zone zone,
      ) async {
    final noms = context.read<ZonesProvider>().noms(sauf: zone);

    final modifiee = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(
          zone: zone,
          nomsAutres: noms,
        ),
      ),
    );

    if (modifiee == null || !context.mounted) return;

    context.read<ZonesProvider>().remplacer(zone, modifiee);
    _message(context, 'Zone modifiée');
  }

  Future<void> _confirmerSuppression(
      BuildContext context,
      Zone zone,
      ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la zone'),
        content: Text(
          'Voulez-vous vraiment supprimer "${zone.nom}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    context.read<ZonesProvider>().supprimer(zone);
    _message(context, 'Zone supprimée');
  }

  Widget _carte(BuildContext context, Zone zone) {
    final provider = context.read<ZonesProvider>();

    return ZoneCard(
      zone: zone,
      onAugmenter: () => provider.modifierHumidite(zone, 5),
      onDiminuer: () => provider.modifierHumidite(zone, -5),
      onTap: () => _ouvrirDetail(context, zone),
      onLongPress: () => _confirmerSuppression(context, zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ZonesProvider>().zones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSmart - Zones'),
      ),
      body: zones.isEmpty
          ? const Center(
        child: Text('Aucune zone enregistrée'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _carte(context, zones[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouter(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
