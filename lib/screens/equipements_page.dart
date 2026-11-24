import 'package:flutter/material.dart';

class EquipmentItem {
  final String name;
  final String type;
  final String statusInfo;
  final String batteryOrState;
  final String signal;
  final bool isOnline;
  final bool isSwitchType;
  bool switchValue;

  EquipmentItem({
    required this.name,
    required this.type,
    required this.statusInfo,
    required this.batteryOrState,
    required this.signal,
    required this.isOnline,
    required this.isSwitchType,
    this.switchValue = false,
  });
}

class EquipementsPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const EquipementsPage({super.key, this.onNavigate});

  @override
  State<EquipementsPage> createState() => _EquipementsPageState();
}

class _EquipementsPageState extends State<EquipementsPage> {
  int _selectedIndex = 0; // Accueil يأخذ Index 0

  final List<EquipmentItem> _equipments = [
    EquipmentItem(
      name: 'Capteur Humidité Sol #1',
      type: 'Type : Humidité du sol',
      statusInfo: 'Batterie : 88% | Signal : Excellent',
      batteryOrState: '#88%',
      signal: 'Excellent',
      isOnline: true,
      isSwitchType: false,
    ),
    EquipmentItem(
      name: 'Vanne Électrique Nord',
      type: 'Type : Irrigation (Parcelle Nord)',
      statusInfo: 'État : Fermée | Signal : Bon',
      batteryOrState: 'Fermée',
      signal: 'Bon',
      isOnline: true,
      isSwitchType: true,
      switchValue: false,
    ),
    EquipmentItem(
      name: 'Station Météo Kébili',
      type: 'Type : Climat & Environnement',
      statusInfo: 'Batterie : 95% | Signal : Excellent',
      batteryOrState: '#95%',
      signal: 'Excellent',
      isOnline: true,
      isSwitchType: false,
    ),
  ];

  void _showAddEquipmentDialog() {
    final nameController = TextEditingController();
    final typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF3F7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ajouter un équipement',
          style: TextStyle(color: Color(0xFF283D27), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom (ex: Capteur #2)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type (ex: Température)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF93E28C),
              foregroundColor: const Color(0xFF283D27),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _equipments.add(
                    EquipmentItem(
                      name: nameController.text.trim(),
                      type: 'Type : ${typeController.text.trim().isEmpty ? "Général" : typeController.text.trim()}',
                      statusInfo: 'Batterie : 100% | Signal : Bon',
                      batteryOrState: '#100%',
                      signal: 'Bon',
                      isOnline: true,
                      isSwitchType: false,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3ECE1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الشريط العلوي (Top Bar)
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
                        'AgriSmart',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF283D27),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF283D27), size: 28),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Color(0xFF283D27), size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // عنوان الصفحة
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'AgriSmart – Équipements',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF283D27),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // قائمة الأجهزة
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    itemCount: _equipments.length,
                    itemBuilder: (context, index) {
                      final eq = _equipments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eq.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF283D27),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    eq.type,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4E5B4D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    eq.statusInfo,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7C69),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'En ligne ',
                                        style: TextStyle(
                                          color: Color(0xFF4C8046),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4C8046),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                eq.isSwitchType
                                    ? Switch(
                                  value: eq.switchValue,
                                  activeColor: const Color(0xFF283D27),
                                  activeTrackColor: const Color(0xFF93E28C),
                                  onChanged: (val) {
                                    setState(() {
                                      eq.switchValue = val;
                                    });
                                  },
                                )
                                    : Column(
                                  children: [
                                    const Icon(Icons.battery_full, color: Color(0xFF4E5B4D), size: 26),
                                    Text(
                                      eq.batteryOrState,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E5B4D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(4, (i) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      width: 4,
                                      height: 6.0 + (i * 4),
                                      decoration: BoxDecoration(
                                        color: i < 3 ? const Color(0xFF283D27) : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 20,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: FloatingActionButton(
                        onPressed: _showAddEquipmentDialog,
                        backgroundColor: const Color(0xFF93E28C),
                        elevation: 4,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add, color: Color(0xFF283D27), size: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // شريط التنقل السفلي (Navbar) مع إضافة تبويب Accueil
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3F7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFD6E6D2),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (widget.onNavigate != null) {
              widget.onNavigate!(index);
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF4E5B4D)),
              selectedIcon: Icon(Icons.home, color: Color(0xFF283D27)),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Badge(
                label: const Text('3'),
                backgroundColor: const Color(0xFF962D2D),
                child: const Icon(Icons.grass_outlined, color: Color(0xFF283D27)),
              ),
              selectedIcon: Badge(
                label: const Text('3'),
                backgroundColor: const Color(0xFF962D2D),
                child: const Icon(Icons.grass, color: Color(0xFF283D27)),
              ),
              label: 'Zones',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded, color: Color(0xFF4E5B4D)),
              selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF283D27)),
              label: 'Statistiques',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline, color: Color(0xFF4E5B4D)),
              selectedIcon: Icon(Icons.person, color: Color(0xFF283D27)),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}