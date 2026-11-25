import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zone_detail_page.dart';

enum _TypeNotification { critique, meteo, succes }

class _ItemNotification {
  final String id;
  final _TypeNotification type;
  final String titre;
  final String message;
  final String temps;
  final Zone? zoneAssociee;
  final bool dismissible;

  const _ItemNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.temps,
    this.zoneAssociee,
    this.dismissible = true,
  });
}

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onAllerZones;

  const NotificationsPage({
    super.key,
    this.onAllerZones,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<String> _masqueesIds = {};
  final List<_ItemNotification> _manuelles = [];

  dynamic _tryProp(dynamic obj, String name) {
    if (obj == null) return null;
    try {
      if (obj is Map) return obj[name];
      switch (name) {
        case 'zones': return obj.zones;
        case 'meteo': return obj.meteo;
        case 'currentMeteo': return obj.currentMeteo;
        case 'donnees': return obj.donnees;
        case 'ville': return obj.ville;
        case 'city': return obj.city;
        case 'description': return obj.description;
        case 'condition': return obj.condition;
        case 'temperature': return obj.temperature;
        default: return null;
      }
    } catch (_) {
      return null;
    }
  }

  List<_ItemNotification> _construireNotificationsReelles(
      List<Zone> zones,
      MeteoProvider meteoProvider,
      ) {
    final items = <_ItemNotification>[];

    // 1. تنبيهات حقيقية من المناطق التي رطوبتها أقل من العتبة (seuil)
    for (final zone in zones) {
      final double humidite = zone.humidite;
      final double seuil = _lireSeuil(zone);

      if (humidite < seuil) {
        final id = 'critique_${zone.nom}_$seuil';
        if (!_masqueesIds.contains(id)) {
          items.add(
            _ItemNotification(
              id: id,
              type: _TypeNotification.critique,
              titre: 'Seuil critique atteint',
              message: "La parcelle '${zone.nom}' a atteint un niveau d'humidité critique de ${humidite.round()}% (seuil : ${seuil.round()}%).",
              temps: 'Il y a 10 min',
              zoneAssociee: zone,
              dismissible: true,
            ),
          );
        }
      } else if (humidite >= seuil + 15) {
        final id = 'irrig_ok_${zone.nom}';
        if (!_masqueesIds.contains(id)) {
          items.add(
            _ItemNotification(
              id: id,
              type: _TypeNotification.succes,
              titre: 'Irrigation terminée',
              message: "L'irrigation automatique de la '${zone.nom}' s'est terminée avec succès. Humidité actuelle : ${humidite.round()}%.",
              temps: 'Il y a 3 h',
              zoneAssociee: zone,
              dismissible: false,
            ),
          );
        }
      }
    }

    // 2. تنبيه الطقس الحقيقي من MeteoProvider
    final dynamic meteoData = _tryProp(meteoProvider, 'meteo') ??
        _tryProp(meteoProvider, 'currentMeteo') ??
        _tryProp(meteoProvider, 'donnees');
    final String ville = (_tryProp(meteoData, 'ville') ??
        _tryProp(meteoData, 'city') ??
        _tryProp(meteoProvider, 'ville') ??
        'Kébili')
        .toString();
    final String desc = (_tryProp(meteoData, 'description') ??
        _tryProp(meteoData, 'condition') ??
        '')
        .toString()
        .toLowerCase();

    const meteoId = 'meteo_live';
    if (!_masqueesIds.contains(meteoId)) {
      if (desc.contains('pluie') || desc.contains('rain')) {
        items.add(
          _ItemNotification(
            id: meteoId,
            type: _TypeNotification.meteo,
            titre: 'Alerte météo - Pluie prévue',
            message: "Des précipitations sont prévues aujourd'hui à $ville. L'irrigation automatique sera suspendue pour économiser de l'eau.",
            temps: 'Il y a 1 h',
            dismissible: false,
          ),
        );
      } else {
        items.add(
          _ItemNotification(
            id: meteoId,
            type: _TypeNotification.meteo,
            titre: 'Suivi météo - $ville',
            message: "Conditions météo actuelles suivies à $ville. Vérifiez l'humidité des parcelles avant chaque cycle d'irrigation.",
            temps: 'Il y a 1 h',
            dismissible: false,
          ),
        );
      }
    }

    // 3. التنبيهات المضافة يدوياً أثناء الجلسة
    for (final item in _manuelles) {
      if (!_masqueesIds.contains(item.id)) {
        items.add(item);
      }
    }

    return items;
  }

  double _lireSeuil(Zone zone) {
    try {
      final dynamic z = zone;
      final val = z.seuil ?? z.seuilHumidite ?? 35.0;
      if (val is num) return val.toDouble();
    } catch (_) {}
    return 35.0;
  }

  Future<void> _ouvrirDetailZone(List<Zone> zones, Zone zone) async {
    await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(
          zone: zone,
          nomsAutres: zones.where((z) => z != zone).map((z) => z.nom).toList(),
        ),
      ),
    );
  }

  void _ajouterAlerteManuelle(List<Zone> zones) {
    final cible = zones.isNotEmpty ? zones.first.nom : 'Parcelle Nord';
    setState(() {
      _manuelles.insert(
        0,
        _ItemNotification(
          id: 'manuel_${DateTime.now().millisecondsSinceEpoch}',
          type: _TypeNotification.critique,
          titre: 'Vérification manuelle requise',
          message: "Contrôle de vanne et d'humidité programmé sur '$cible'.",
          temps: "À l'instant",
          zoneAssociee: zones.isNotEmpty ? zones.first : null,
          dismissible: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final zonesProvider = context.watch<ZonesProvider>();
    final meteoProvider = context.watch<MeteoProvider>();

    final rawZones = _tryProp(zonesProvider, 'zones');
    final List<Zone> zones = rawZones is List<Zone> ? rawZones : const [];
    final notifications = _construireNotificationsReelles(zones, meteoProvider);

    return Scaffold(
      // ✅ Fond dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الشريط العلوي
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AgriSmart',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: theme.colorScheme.onSurface, size: 24),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scanner QR')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: theme.colorScheme.onSurface, size: 24),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // العنوان الرئيسي للصفحة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Notifications & Alertes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // قائمة الكروت
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                child: Text(
                  'Aucune notification active',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _CarteNotification(
                    item: item,
                    onDismiss: () {
                      setState(() {
                        _masqueesIds.add(item.id);
                      });
                    },
                    onTap: () {
                      if (item.zoneAssociee != null) {
                        _ouvrirDetailZone(zones, item.zoneAssociee!);
                      } else if (widget.onAllerZones != null) {
                        widget.onAllerZones!();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF81C778), // On garde le vert
        foregroundColor: const Color(0xFF142115),
        onPressed: () => _ajouterAlerteManuelle(zones),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _CarteNotification extends StatelessWidget {
  final _ItemNotification item;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _CarteNotification({
    required this.item,
    required this.onDismiss,
    required this.onTap,
  });

  // On garde les couleurs d'accent (icône) pour identifier le type
  Color get _accentColor {
    switch (item.type) {
      case _TypeNotification.critique: return const Color(0xFFC94A38);
      case _TypeNotification.meteo: return const Color(0xFF4B79A1);
      case _TypeNotification.succes: return const Color(0xFF4C8C4A);
    }
  }

  IconData get _iconData {
    switch (item.type) {
      case _TypeNotification.critique: return Icons.warning_rounded;
      case _TypeNotification.meteo: return Icons.cloud_queue;
      case _TypeNotification.succes: return Icons.check_circle;
    }
  }

  // ✅ NOUVEAU : On adapte la couleur de fond de la carte selon le thème
  Color _getBgColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const Color(0xFF1E1E1E); // Gris très foncé en mode sombre
    }

    // Couleurs claires originales pour le mode clair
    switch (item.type) {
      case _TypeNotification.critique: return const Color(0xFFF6E7E7);
      case _TypeNotification.meteo: return const Color(0xFFE3ECF6);
      case _TypeNotification.succes: return const Color(0xFFE6F2E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      // ✅ Couleur du fond dynamique
      color: _getBgColor(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (!isDark) // On retire l'ombre en mode sombre
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconData, color: _accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.titre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface, // ✅ Texte dynamique
                      ),
                    ),
                  ),
                  if (item.dismissible)
                    InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant, // ✅ Icône dynamique
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant, // ✅ Icône dynamique
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.message,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: theme.colorScheme.onSurface, // ✅ Texte dynamique
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.temps,
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurfaceVariant, // ✅ Texte dynamique
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}