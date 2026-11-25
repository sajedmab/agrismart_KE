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
  int _selectedIndex = 0; // مؤشر الـ Navbar الافتراضي (مثلاً Accueil أو حسب الاختيار)
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
    final zonesProvider = context.watch<ZonesProvider>();
    final zones = zonesProvider.zones;
    final nomParcelle = zones.isNotEmpty ? zones.first.nom : 'Parcelle Nord';
    final aIrriguer = zonesProvider.nombreAIrriguer;

    return Scaffold(
      backgroundColor: const Color(0xFFE3ECE1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الشريط العلوي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF283D27), size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Journal des activités',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF283D27),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF283D27), size: 26),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Color(0xFF283D27), size: 26),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. عنوان Parcelle الحقيقي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                '$nomParcelle - Activités',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF283D27),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. المحتوى
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  Stack(
                    children: [
                      const Positioned(
                        top: 15,
                        bottom: 15,
                        left: 15,
                        child: VerticalDivider(
                          color: Color(0xFF568B50),
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF283D27),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F7F2),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              activite.titre,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF283D27),
                                              ),
                                            ),
                                            Icon(activite.icone, color: const Color(0xFF4C8046), size: 22),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${activite.titre} - ${activite.date}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4E5B4D),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          activite.description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7C69),
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

                  // 4. بطاقة إضافة ملاحظة جديدة
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7F2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ajouter une note',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF283D27),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Saisir une nouvelle note...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey.shade300),
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

      // 5. شريط التنقل السفلي (Navbar) المطابق تماماً لهيكل التطبيق
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (widget.onNavigate != null) {
            widget.onNavigate!(index);
          } else {
            Navigator.pop(context); // العودة للشاشة الرئيسية أو إغلاق الصفحة عند الضغط
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