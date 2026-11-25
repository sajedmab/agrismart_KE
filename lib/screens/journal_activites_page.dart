import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';

class ActiviteItem {
  final String titre;
  final String description;
  final String date;
  final IconData icone;

  ActiviteItem({
    required this.titre,
    required this.description,
    required this.date,
    required this.icone,
  });
}

class JournalActivitesPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const JournalActivitesPage({super.key, this.onNavigate});

  @override
  State<JournalActivitesPage> createState() => _JournalActivitesPageState();
}

class _JournalActivitesPageState extends State<JournalActivitesPage> {
  int _selectedIndex = 0;
  final TextEditingController _noteController = TextEditingController();

  final List<ActiviteItem> _activites = [
    ActiviteItem(
      titre: "Ajout d'engrais NPK",
      description: "Application d'engrais riche en azote. ✓ Optilla",
      date: "Aujourd'hui, 22/11 10:30",
      icone: Icons.eco,
    ),
    ActiviteItem(
      titre: "Taille des oliviers",
      description: "Taille de printemps et entretien.",
      date: "18/11",
      icone: Icons.content_cut,
    ),
    ActiviteItem(
      titre: "Traitement préventif",
      description: "Traitement bio contre les parasites.",
      date: "10/11",
      icone: Icons.shield_outlined,
    ),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _ajouterNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _activites.insert(
          0,
          ActiviteItem(
            titre: "Note personnelle",
            description: _noteController.text.trim(),
            date: "À l'instant",
            icone: Icons.note_add_outlined,
          ),
        );
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note ajoutée avec succès au journal !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Récupération du thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final zonesProvider = context.watch<ZonesProvider>();
    final zones = zonesProvider.zones;
    final nomParcelle = zones.isNotEmpty ? zones.first.nom : 'Parcelle Nord';
    final aIrriguer = zones.where((z) => z.besoinIrrigation).length;

    return Scaffold(
      // ✅ Fond dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Barre supérieure
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: theme.colorScheme.onSurface, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // ✅ Expanded + ellipsis : le titre se réduit au lieu de déborder
                  Expanded(
                    child: Text(
                      'Journal des activités',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner,
                        color: theme.colorScheme.onSurface, size: 26),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.logout,
                        color: theme.colorScheme.onSurface, size: 26),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 2. Titre Parcelle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                '$nomParcelle - Activités',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Contenu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  Stack(
                    children: [
                      Positioned(
                        top: 15,
                        bottom: 15,
                        left: 15,
                        child: VerticalDivider(
                          color: isDark ? Colors.white24 : const Color(0xFF568B50),
                          thickness: 2,
                        ),
                      ),
                      Column(
                        children: _activites.map((activite) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 16, right: 12),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    // ✅ Point de la timeline dynamique
                                    color: isDark ? Colors.white54 : const Color(0xFF283D27),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      // ✅ Fond de la carte de l'activité
                                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F7F2),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        if (!isDark)
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                activite.titre,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(activite.icone,
                                                color: const Color(0xFF4C8046), size: 22),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${activite.titre} - ${activite.date}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          activite.description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. Carte « Ajouter une note »
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // ✅ Fond de la carte "Ajouter une note"
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F7F2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajouter une note',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Saisir une nouvelle note...',
                            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            filled: true,
                            // ✅ Fond du champ de texte
                            fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Color(0xFF4C8046), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF93E28C),
                              foregroundColor: const Color(0xFF283D27),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: _ajouterNote,
                            child: const Text(
                              'Ajouter la note',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Barre de navigation
      bottomNavigationBar: NavigationBar(
        // ✅ Fond de la navbar dynamique
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : theme.scaffoldBackgroundColor,
        indicatorColor: isDark ? const Color(0xFF3A5A3A) : const Color(0xFFD6E5D4),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (widget.onNavigate != null) {
            widget.onNavigate!(index);
          } else {
            Navigator.pop(context);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$aIrriguer'),
              isLabelVisible: aIrriguer > 0,
              child: const Icon(Icons.grass_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$aIrriguer'),
              isLabelVisible: aIrriguer > 0,
              child: const Icon(Icons.grass),
            ),
            label: 'Zones',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
