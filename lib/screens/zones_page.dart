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
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF285226),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          texte,
          style: const TextStyle(color: Colors.white),
        ),
      ),
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
    final theme = Theme.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // ✅ Fond de l'alerte dynamique
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Supprimer la zone',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${zone.nom}" ?',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC93B2B),
              foregroundColor: Colors.white,
            ),
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
    final theme = Theme.of(context);

    final zones = context.watch<ZonesProvider>().zones;
    final nbAlerte = zones.where((z) => z.besoinIrrigation).length;

    return Scaffold(
      // ✅ Fond de l'écran dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  // Le dégradé vert reste le même car il est très lisible
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A32), Color(0xFF478E39)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A32).withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AgriSmart - Zones',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${zones.length} parcelle(s) suivie(s)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDDF0DC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: nbAlerte > 0
                            ? const Color(0xFFFFEFEA)
                            : const Color(0xFFE9F7E6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        nbAlerte > 0 ? '$nbAlerte à irriguer' : 'Tout est OK',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: nbAlerte > 0
                              ? const Color(0xFFC93B2B)
                              : const Color(0xFF256029),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: zones.isEmpty
                  ? Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3E8438), Color(0xFF56A832)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 42,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aucune zone enregistrée',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Appuyez sur + pour ajouter une parcelle.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFE7F6E5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _carte(context, zones[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D6A32),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _ajouter(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}