import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';

class StatistiquesPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const StatistiquesPage({super.key, this.onNavigate});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  int _selectedIndex = 1; // Statistiques est l'index 1 dans la Navbar

  void _showAddStatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF3F7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ajouter une mesure',
          style: TextStyle(color: Color(0xFF283D27), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Fonctionnalité pour ajouter des données statistiques.',
          style: TextStyle(color: Color(0xFF4E5B4D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF93E28C),
              foregroundColor: const Color(0xFF283D27),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesProvider = context.watch<ZonesProvider>();
    final zones = zonesProvider.zones;

    // تصفية الحقول التي تحتاج إلى تنبيه رطوبة منخفضة
    final zonesAlerte = zones.where((z) => z.humidite < 35.0 || z.besoinIrrigation).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE3ECE1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الرئيسي للصفحة بدون شريط علوي قديم
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'AgriSmart – Statistiques',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF283D27),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // المحتوى القابل للتمرير
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    children: [
                      // --- بطاقة المنحنى البياني الشامل لكل الحقول (Tout Parciel) ---
                      Container(
                        padding: const EdgeInsets.all(16),
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
                              "Évolution de l'humidité",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF283D27),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Comparaison de toutes les parcelles",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4E5B4D),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // رسم المنحنى البياني التفاعلي لكل الحقول
                            zones.isEmpty
                                ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Aucune parcelle disponible'),
                              ),
                            )
                                : SizedBox(
                              height: 180,
                              child: CustomPaint(
                                size: const Size(double.infinity, 180),
                                painter: ParcellesChartPainter(zones: zones),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // مفتاح توضيحي للمنحنى (أسماء الحقول ونسبها)
                            if (zones.isNotEmpty)
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: zones.map((zone) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: zone.humidite < 35 ? Colors.red : const Color(0xFF4C8046),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${zone.nom} (${zone.humidite.toStringAsFixed(0)}%)',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF283D27)),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- قسم سجل التنبيهات الحقيقي ---
                      const Text(
                        'Historique des alertes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF283D27),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (zonesAlerte.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F7F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Aucune alerte active sur vos parcelles. Tout fonctionne parfaitement.',
                            style: TextStyle(color: Color(0xFF4E5B4D)),
                          ),
                        )
                      else
                        ...zonesAlerte.map((zone) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE8E6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200, width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.priority_high, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${zone.nom} - Humidité basse',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF283D27),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Taux mesuré : ${zone.humidite.toStringAsFixed(1)}% (Seuil : 35%)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),

                  // زر الإضافة العائم (+)
                  Positioned(
                    bottom: 16,
                    right: 20,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: FloatingActionButton(
                        onPressed: _showAddStatDialog,
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

      // شريط التنقل السفلي (Navbar)
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
            NavigationDestination(
              icon: Badge(
                label: Text('${zones.where((z) => z.besoinIrrigation).length}'),
                backgroundColor: const Color(0xFF962D2D),
                child: const Icon(Icons.grass_outlined, color: Color(0xFF283D27)),
              ),
              selectedIcon: Badge(
                label: Text('${zones.where((z) => z.besoinIrrigation).length}'),
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

// رسم المنحنى البياني للمقارنة بين جميع الحقول (Tout Parciel)
class ParcellesChartPainter extends CustomPainter {
  final List<dynamic> zones;

  ParcellesChartPainter({required this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    if (zones.isEmpty) return;

    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // خطوط الشبكة الأفقية
    for (int i = 0; i <= 4; i++) {
      double y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // خط عتبة الإنذار عند 35%
    final paintThreshold = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // رسم خط منقط للعتبة
    double thresholdY = size.height - (35 / 100 * size.height);
    canvas.drawLine(Offset(0, thresholdY), Offset(size.width, thresholdY), paintThreshold);

    // رسم المنحنى البياني للرطوبة عبر الحقول
    final paintLine = Paint()
      ..color = const Color(0xFF4C8046)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    double stepX = zones.length > 1 ? size.width / (zones.length - 1) : size.width / 2;

    for (int i = 0; i < zones.length; i++) {
      double x = i * stepX;
      double humidite = zones[i].humidite.clamp(0.0, 100.0);
      double y = size.height - (humidite / 100 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // رسم نقاط على المنحنى لكل حقل
      final paintPoint = Paint()
        ..color = zones[i].humidite < 35 ? Colors.red : const Color(0xFF283D27)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5, paintPoint);
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}