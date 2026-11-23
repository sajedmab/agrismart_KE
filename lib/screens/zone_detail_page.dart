import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _nomZone = widget.zone.nom;
  }

  String _zoneDocId(Zone zone) {
    try {
      final dynamic z = zone;
      final id = z.id;
      if (id is String && id.trim().isNotEmpty) {
        return id.trim();
      }
    } catch (_) {}
    return Uri.encodeComponent(zone.nom.trim().toLowerCase());
  }

  CollectionReference _historiqueCollection(Zone zone) {
    return FirebaseFirestore.instance
        .collection('zones')
        .doc(_zoneDocId(zone))
        .collection('historique_irrigations');
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

  String _formatEntreeHistorique(Map<String, dynamic> data) {
    final rawTs = data['createdAt'];
    final ts = rawTs is Timestamp ? rawTs : null;
    final int duree = (data['dureeMinutes'] is num)
        ? (data['dureeMinutes'] as num).round()
        : 15;
    final humApres = data['humiditeApres'];

    String prefixDate;
    if (ts == null) {
      prefixDate = "Aujourd'hui, ${_formatHeureNow()}";
    } else {
      final dt = ts.toDate();
      final now = DateTime.now();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');

      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day;

      if (isToday) {
        prefixDate = "Aujourd'hui, $hh:$mm";
      } else if (isYesterday) {
        prefixDate = "Hier, $hh:$mm";
      } else {
        final dd = dt.day.toString().padLeft(2, '0');
        final mo = dt.month.toString().padLeft(2, '0');
        prefixDate = '$dd/$mo $hh:$mm';
      }
    }

    String texte = '$prefixDate - Irrigué pendant $duree min';
    if (humApres is num) {
      texte = '$texte (${humApres.toStringAsFixed(0)}%)';
    }
    return texte;
  }

  Future<void> _ajouterHistoriqueFirebase(
      Zone zone, {
        required int dureeMinutes,
        required double humiditeApres,
      }) async {
    await _historiqueCollection(zone).add({
      'zoneNom': zone.nom,
      'dureeMinutes': dureeMinutes,
      'humiditeApres': humiditeApres,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _effacerHistoriqueFirebase(Zone zone) async {
    final snapshot = await _historiqueCollection(zone).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique supprimé dans Firebase')),
    );
  }

  Future<void> _demarrerIrrigationReal(Zone zone) async {
    if (_enCours) return;
    setState(() => _enCours = true);

    const int dureeMinutes = 15;
    final double nouvelleHumidite = (zone.humidite + 20.0).clamp(0.0, 100.0);
    final dynamic zp = context.read<ZonesProvider>();
    bool ok = false;

    for (final action in [
          () async => await zp.irriguerZone(zone.nom),
          () async => await zp.irriguer(zone.nom),
          () async => await zp.basculerVanne(zone.nom),
          () async => await zp.mettreAJourHumidite(zone.nom, nouvelleHumidite),
          () async {
        final dynamic zDyn = zone;
        final Zone maj = zDyn.copyWith(
          humidite: nouvelleHumidite,
          vanneOuverte: true,
        );
        await zp.modifierZone(zone.nom, maj);
      },
    ]) {
      try {
        await action();
        ok = true;
        break;
      } catch (_) {}
    }

    try {
      await _ajouterHistoriqueFirebase(
        zone,
        dureeMinutes: dureeMinutes,
        humiditeApres: nouvelleHumidite,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Firebase : $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _enCours = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Irrigation lancée et enregistrée sur '${zone.nom}'"
              : "Irrigation enregistrée dans l'historique de '${zone.nom}'",
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique des irrigations',
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A221B),
                ),
              ),
              TextButton.icon(
                onPressed: () => _effacerHistoriqueFirebase(zone),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<QuerySnapshot>(
            stream: _historiqueCollection(zone)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Erreur Firestore : ${snapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Aucune irrigation enregistrée dans Firebase.',
                    style: TextStyle(fontSize: 14.5, color: Color(0xFF4B5563)),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final rawData = doc.data();
                  final data = rawData is Map<String, dynamic>
                      ? rawData
                      : <String, dynamic>{};
                  final texte = _formatEntreeHistorique(data);
                  return Padding(
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
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF47883A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              texte,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1F2820),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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