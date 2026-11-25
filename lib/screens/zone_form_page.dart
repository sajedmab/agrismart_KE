import 'package:flutter/material.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/widgets/zone_form.dart';

class ZoneFormPage extends StatelessWidget {
  final Zone? zone;
  final List<String> nomsExistants;
  final ValueChanged<int>? onSelectNavIndex;

  const ZoneFormPage({
    super.key,
    this.zone,
    this.nomsExistants = const [],
    this.onSelectNavIndex,
  });

  void _naviguerBas(BuildContext context, int index) {
    if (onSelectNavIndex != null) {
      onSelectNavIndex!(index);
    }
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool estModification = zone != null;

    return Scaffold(
      // ✅ Fond de l'écran dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          estModification ? 'Modifier la zone' : 'Nouvelle zone',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Accueil',
            icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurface),
            onPressed: () => _naviguerBas(context, 0),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------- CARTE D'EN-TÊTE -----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  // ✅ Fond de la carte dynamique
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F7F1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFD2DFD0),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // ✅ Fond de l'icône
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDCE9DA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        estModification
                            ? Icons.edit_location_alt
                            : Icons.add_location_alt,
                        color: const Color(0xFF4CAF50), // Un vert qui brille dans les deux modes
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estModification
                                ? 'Mise à jour — ${zone!.nom}'
                                : 'Configuration d\'une parcelle',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            estModification
                                ? 'Ajustez la culture, l\'humidité ou le seuil d\'irrigation'
                                : 'Renseignez les informations de la nouvelle zone agricole',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ----------- CONTENEUR DU FORMULAIRE -----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ✅ Fond du formulaire dynamique
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F7F1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: ZoneForm(
                  zone: zone,
                  nomsExistants: nomsExistants,
                  onEnregistrer: (nouvelle) {
                    Navigator.pop(context, nouvelle);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        // ✅ Fond de la navbar dynamique
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE7EFE6),
        indicatorColor: isDark ? const Color(0xFF3A5A3A) : const Color(0xFFD6E5D4),
        selectedIndex: 1,
        onDestinationSelected: (index) => _naviguerBas(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: 'Zones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}