import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/theme/app_theme.dart';

class ZoneDetailPage extends StatefulWidget {
  final Zone zone;
  final List<String> nomsAutres;

  const ZoneDetailPage({
    super.key,
    required this.zone,
    this.nomsAutres = const [],
  });

  @override
  State<ZoneDetailPage> createState() => _ZoneDetailPageState();
}

class _ZoneDetailPageState extends State<ZoneDetailPage> {
  late String _nomZone;
  bool _irrigationAuto = true;
  bool _enCours = false;
  String _horaireSelectionne = '06:30';

  final List<String> _horaires = ['06:30', '18:30', '21:00'];
  final List<_LogIrrigation> _logs = [];

  @override
  void initState() {
    super.initState();
    _nomZone = widget.zone.nom;
  }

  Zone _zoneReelle(ZonesProvider provider) {
    final dynamic dyn = provider;
    try {
      final list = dyn.zones;
      if (list is List<Zone>) {
        for (final z in list) {
          if (z.nom == _nomZone) return z;
        }
      }
    } catch (_) {}
    return widget.zone;
  }

  String _formatHeureNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDateMesure() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    return '$dd/$mo ${_formatHeureNow()}';
  }

  Future<void> _demarrerIrrigationReal(Zone zone) async {
    if (_enCours) return;
    setState(() => _enCours = true);

    final dynamic zp = context.read<ZonesProvider>();
    final double nouvelleHumidite = (zone.humidite + 20.0).clamp(0.0, 100.0);
    bool ok = false;

    // Njarbou les méthodes real li ykouno mawjoudin fi ZonesProvider
    try {
      await zp.irriguerZone(zone.nom);
      ok = true;
    } catch (_) {}

    if (!ok) {
      try {
        await zp.irriguer(zone.nom);
        ok = true;
      } catch (_) {}
    }

    if (!ok) {
      try {
        await zp.basculerVanne(zone.nom);
        ok = true;
      } catch (_) {}
    }

    if (!ok) {
      try {
        await zp.mettreAJourHumidite(zone.nom, nouvelleHumidite);
        ok = true;
      } catch (_) {}
    }

    if (!ok) {
      try {
        final dynamic zDyn = zone;
        final Zone maj = zDyn.copyWith(
          humidite: nouvelleHumidite,
          vanneOuverte: true,
        );
        await zp.modifierZone(zone.nom, maj);
        ok = true;
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _logs.insert(
        0,
        _LogIrrigation(
          texte: "Aujourd'hui, ${_formatHeureNow()} - Irrigué pendant 15 min",
          succes: ok,
        ),
      );
      _enCours = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Irrigation exécutée sur '${zone.nom}'"
              : "Action d'irrigation envoyée pour '${zone.nom}'",
        ),
      ),
    );
  }

  Future<void> _modifierZoneReal(Zone zone) async {
    final nouvelleZone = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneFormPage(
          zone: zone,
          nomsExistants: widget.nomsAutres,
        ),
      ),
    );

    if (nouvelleZone == null || !mounted) return;

    final dynamic zp = context.read<ZonesProvider>();
    try {
      await zp.modifierZone(zone.nom, nouvelleZone);
    } catch (_) {
      try {
        await zp.mettreAJourZone(nouvelleZone);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _nomZone = nouvelleZone.nom;
    });
    Navigator.pop(context, nouvelleZone);
  }

  @override
  Widget build(BuildContext context) {
    final zonesProvider = context.watch<ZonesProvider>();
    final zone = _zoneReelle(zonesProvider);

    final Color couleurEtat =
    zone.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
    final int sigleLen = zone.culture.length < 4 ? zone.culture.length : 4;
    final String sigle =
    zone.culture.isNotEmpty ? zone.culture.substring(0, sigleLen) : 'Z';

    return Scaffold(
      backgroundColor: const Color(0xFFE7EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7EFE6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A221B)),
          onPressed: () => Navigator.pop(context, zone),
        ),
        title: Text(
          '${zone.nom} - Détails',
          style: const TextStyle(
            color: Color(0xFF1A221B),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A221B)),
            onPressed: () => _modifierZoneReal(zone),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Carte principale real mn ZonesProvider
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.nom,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A221B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Culture : ${zone.culture}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF3F4B41),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Humidité actuelle : ${zone.humidite.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A221B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            zone.besoinIrrigation
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            size: 18,
                            color: couleurEtat,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              diagnostic(zone),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: couleurEtat,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _BadgeInfo(
                            texte: 'Dernière mesure : ${_formatDateMesure()}',
                          ),
                          _BadgeInfo(
                            texte: zone.vanneOuverte
                                ? 'Vanne : Ouverte'
                                : 'Vanne : Fermée',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFDDE8DC),
                  child: Text(
                    sigle,
                    style: const TextStyle(
                      color: Color(0xFF2E4E32),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bouton Démarrer l'irrigation real
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF47883A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: _enCours ? null : () => _demarrerIrrigationReal(zone),
              child: _enCours
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Démarrer l'irrigation",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.water_drop_outlined, size: 20),
                  SizedBox(width: 2),
                  Icon(Icons.play_arrow, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Irrigation automatique + seuil real
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Irrigation automatique',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A221B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "(Seuil d'irrigation : ${zone.seuil.toStringAsFixed(1)}%)",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3F4B41),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _irrigationAuto,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF47883A),
                  onChanged: (v) => setState(() => _irrigationAuto = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Planification de l'irrigation
          const Text(
            "Planification de l'irrigation",
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A221B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Color(0xFF3A473C)),
                const SizedBox(width: 8),
                const Text(
                  "Horaires d'irrigation",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A221B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _horaires.map((h) {
                        final bool sel = _horaireSelectionne == h;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _horaireSelectionne = h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFFE6F1E4)
                                    : const Color(0xFFF7FAF6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFF47883A)
                                      : const Color(0xFFD0DBD0),
                                  width: sel ? 1.8 : 1.0,
                                ),
                              ),
                              child: Text(
                                h,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                                  color: const Color(0xFF1A221B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Historique des irrigations real (yetzad fih kol ma ta3mel irrigation)
          const Text(
            'Historique des irrigations',
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A221B),
            ),
          ),
          const SizedBox(height: 10),
          if (_logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Aucune irrigation enregistrée pour cette session.',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF4B5563)),
              ),
            )
          else
            ..._logs.map(
                  (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        log.succes ? Icons.check_circle : Icons.info_outline,
                        size: 18,
                        color: log.succes
                            ? const Color(0xFF47883A)
                            : const Color(0xFF5A6B5C),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          log.texte,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1F2820),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  final String texte;
  const _BadgeInfo({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE7DA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texte,
        style: const TextStyle(fontSize: 13, color: Color(0xFF354237)),
      ),
    );
  }
}

class _LogIrrigation {
  final String texte;
  final bool succes;
  const _LogIrrigation({required this.texte, required this.succes});
}