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
  final ValueChanged<int>? onSelectNavIndex;

  const ZoneDetailPage({
    super.key,
    required this.zone,
    this.nomsAutres = const [],
    this.onSelectNavIndex,
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

  int _lireNombreAIrriguer(ZonesProvider provider, Zone zoneCourante) {
    final dynamic dyn = provider;
    try {
      final val = dyn.nombreAIrriguer;
      if (val is int) return val;
    } catch (_) {}
    return zoneCourante.besoinIrrigation ? 1 : 0;
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

  void _naviguerVersBas(int index) {
    if (widget.onSelectNavIndex != null) {
      widget.onSelectNavIndex!(index);
    }
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Récupération du thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final zonesProvider = context.watch<ZonesProvider>();
    final zone = _zoneReelle(zonesProvider);
    final int aIrriguer = _lireNombreAIrriguer(zonesProvider, zone);

    final Color couleurEtat =
    zone.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
    final int sigleLen = zone.culture.length < 4 ? zone.culture.length : 4;
    final String sigle =
    zone.culture.isNotEmpty ? zone.culture.substring(0, sigleLen) : 'Z';

    return Scaffold(
      // ✅ Fond dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, zone),
        ),
        title: Text(
          '${zone.nom} - Détails',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onSurface),
            onPressed: () => _modifierZoneReal(zone),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // ----------- CARTE D'INFORMATION PRINCIPALE -----------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              // ✅ Fond de la carte
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.nom,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Culture : ${zone.culture}',
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Humidité actuelle : ${zone.humidite.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
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
                  // ✅ Fond de l'avatar dynamique
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDDE8DC),
                  child: Text(
                    sigle,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF2E4E32),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ----------- BOUTON D'IRRIGATION -----------
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
          // ----------- IRRIGATION AUTOMATIQUE -----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Irrigation automatique',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "(Seuil d'irrigation : ${zone.seuil.toStringAsFixed(1)}%)",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
          // ----------- PLANIFICATION -----------
          Text(
            "Planification de l'irrigation",
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  "Horaires d'irrigation",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
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
                                // ✅ Couleur de sélection dynamique
                                color: sel
                                    ? (isDark ? const Color(0xFF2E4E32) : const Color(0xFFE6F1E4))
                                    : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF7FAF6)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFF47883A)
                                      : (isDark ? Colors.white24 : const Color(0xFFD0DBD0)),
                                  width: sel ? 1.8 : 1.0,
                                ),
                              ),
                              child: Text(
                                h,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                  color: theme.colorScheme.onSurface,
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
          // ----------- HISTORIQUE -----------
          Row(
            children: [
              // Expanded : le titre se réduit au lieu de déborder (bande jaune)
              Expanded(
                child: Text(
                  'Historique des irrigations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
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
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
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
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Aucune irrigation enregistrée dans Firebase.',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
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
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
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
      bottomNavigationBar: NavigationBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : null,
        indicatorColor: isDark ? const Color(0xFF3A5A3A) : null,
        selectedIndex: 1,
        onDestinationSelected: _naviguerVersBas,
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

class _BadgeInfo extends StatelessWidget {
  final String texte;
  const _BadgeInfo({required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // ✅ Fond du badge dynamique
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDCE7DA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : const Color(0xFF354237),
        ),
      ),
    );
  }
}