import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';

class ExportRapportsPage extends StatefulWidget {
  final ValueChanged<int>? onSelectNavIndex;

  const ExportRapportsPage({
    super.key,
    this.onSelectNavIndex,
  });

  @override
  State<ExportRapportsPage> createState() => _ExportRapportsPageState();
}

class _ExportRapportsPageState extends State<ExportRapportsPage> {
  static const Color _bg = Color(0xFFE7EFE6);
  static const Color _cardBg = Color(0xFFF2F7F1);
  static const Color _vertFonce = Color(0xFF4E8A42);
  static const Color _vertBouton = Color(0xFF9CE08E);
  static const Color _textePrincipal = Color(0xFF1A221B);
  static const Color _texteSecondaire = Color(0xFF556256);

  String _periodeSelectionnee = 'Ce mois-ci';
  String _zoneSelectionnee = 'Toutes les parcelles';

  List<Zone> _extraireZones(ZonesProvider provider) {
    final dynamic dyn = provider;
    try {
      final list = dyn.zones;
      if (list is List<Zone>) return list;
    } catch (_) {}
    return const [];
  }

  String _genererResumeTexte(List<Zone> zones) {
    final zonesFiltrees = _zoneSelectionnee == 'Toutes les parcelles'
        ? zones
        : zones.where((z) => z.nom == _zoneSelectionnee).toList();

    final int nbZones = zonesFiltrees.isEmpty ? 4 : zonesFiltrees.length;
    final double humMoy = zonesFiltrees.isEmpty
        ? 38.5
        : zonesFiltrees.map((z) => z.humidite).reduce((a, b) => a + b) /
        zonesFiltrees.length;
    final int cycles = _periodeSelectionnee == 'Ce mois-ci'
        ? nbZones * 10 + 2
        : nbZones * 4;
    final int litres = cycles * 20;
    final int alertesResolues = zonesFiltrees.isEmpty
        ? 5
        : zonesFiltrees.where((z) => !z.besoinIrrigation).length;

    return 'Rapport : Novembre 2026\n'
        'Période : $_periodeSelectionnee\n'
        'Zone : $_zoneSelectionnee\n'
        'Irrigations : $cycles cycles (${litres}L)\n'
        'Humidité moy. : ${humMoy.toStringAsFixed(1)}%\n'
        'Alertes résolues : $alertesResolues';
  }

  Future<void> _choisirPeriodePersonnalisee() async {
    final DateTimeRange? plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _vertFonce,
              onPrimary: Colors.white,
              surface: _cardBg,
              onSurface: _textePrincipal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (plage != null && mounted) {
      final debut = '${plage.start.day}/${plage.start.month}';
      final fin = '${plage.end.day}/${plage.end.month}';
      setState(() {
        _periodeSelectionnee = '$debut - $fin';
      });
    }
  }

  Future<void> _exporter(String format, List<Zone> zones) async {
    final contenu = format == 'CSV'
        ? 'Periode;Zone;Irrigations;HumiditeMoyenne;AlertesResolues\n'
        '"$_periodeSelectionnee";"$_zoneSelectionnee";42;38.5;5'
        : _genererResumeTexte(zones);

    await Clipboard.setData(ClipboardData(text: contenu));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF285226),
        content: Text('Rapport $format préparé et copié dans le presse-papiers.'),
      ),
    );
  }

  void _naviguerBas(int index) {
    if (widget.onSelectNavIndex != null) {
      widget.onSelectNavIndex!(index);
    }
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final zonesProvider = context.watch<ZonesProvider>();
    final zones = _extraireZones(zonesProvider);

    final zonesFiltrees = _zoneSelectionnee == 'Toutes les parcelles'
        ? zones
        : zones.where((z) => z.nom == _zoneSelectionnee).toList();

    final int cycles = _periodeSelectionnee == 'Ce mois-ci' ? 42 : 14;
    final int litres = cycles * 20;
    final double humMoy = zonesFiltrees.isEmpty
        ? 38.5
        : zonesFiltrees.map((z) => z.humidite).reduce((a, b) => a + b) /
        zonesFiltrees.length;
    final int alertesResolues = zonesFiltrees.isEmpty
        ? 5
        : zonesFiltrees.where((z) => !z.besoinIrrigation).length;

    final optionsZones = <String>[
      'Toutes les parcelles',
      ...zones.map((z) => z.nom),
      if (zones.isEmpty) ...['Parcelle Nord', 'Parcelle Sud'],
    ].toSet().toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textePrincipal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Exportation des rapports',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: _textePrincipal,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Générer un Rapport',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: _textePrincipal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 15,
                  color: _texteSecondaire,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Période',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textePrincipal,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _FiltreChip(
                    label: 'Ce mois-ci',
                    selected: _periodeSelectionnee == 'Ce mois-ci',
                    onTap: () => setState(() => _periodeSelectionnee = 'Ce mois-ci'),
                  ),
                  _FiltreChip(
                    label: _periodeSelectionnee != 'Ce mois-ci'
                        ? _periodeSelectionnee
                        : 'Personnalisé',
                    selected: _periodeSelectionnee != 'Ce mois-ci',
                    onTap: _choisirPeriodePersonnalisee,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textePrincipal,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: optionsZones.map((nomZone) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _FiltreChip(
                        label: nomZone,
                        selected: _zoneSelectionnee == nomZone,
                        onTap: () => setState(() => _zoneSelectionnee = nomZone),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aperçu du Rapport',
                style: TextStyle(
                  fontSize: 15,
                  color: _texteSecondaire,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 12,
                      offset: Offset(0, 5),
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
                          const Text(
                            'Rapport : Novembre 2026',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textePrincipal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Irrigations : $cycles cycles (${litres}L)',
                            style: const TextStyle(
                              fontSize: 15.5,
                              color: _textePrincipal,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Humidité moy. : ${humMoy.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 15.5,
                              color: _textePrincipal,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Alertes résolues : $alertesResolues',
                            style: const TextStyle(
                              fontSize: 15.5,
                              color: _textePrincipal,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    const _ApercuDocumentIllustration(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _exporter('PDF', zones),
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: _textePrincipal,
                  ),
                  label: const Text(
                    'Exporter en PDF',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: _textePrincipal,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vertBouton,
                    foregroundColor: _textePrincipal,
                    elevation: 3,
                    shadowColor: const Color.fromRGBO(0, 0, 0, 0.14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _exporter('CSV', zones),
                  icon: const Icon(
                    Icons.table_chart_outlined,
                    color: _textePrincipal,
                  ),
                  label: const Text(
                    'Exporter en CSV',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: _textePrincipal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5EEE4),
                    foregroundColor: _textePrincipal,
                    side: const BorderSide(
                      color: Color(0xFF9EB59B),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _bg,
        indicatorColor: const Color(0xFFD6E5D4),
        selectedIndex: 0,
        onDestinationSelected: _naviguerBas,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass, color: Color(0xFF276738)),
            label: 'Zones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF276738)),
            label: 'Statistiques',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF276738)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF4E8A42) : const Color(0xFFF2F7F1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF1A221B),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check,
                  size: 17,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ApercuDocumentIllustration extends StatelessWidget {
  const _ApercuDocumentIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E2D7)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomPaint(
              painter: _MiniCourbePainter(),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            4,
                (index) => Container(
              height: 5,
              margin: EdgeInsets.only(bottom: index == 3 ? 0 : 5),
              decoration: BoxDecoration(
                color: const Color(0xFF9AA59B),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCourbePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF56A832)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.25, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.75, size.height * 0.2)
      ..lineTo(size.width, size.height * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}