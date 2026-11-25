import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/assistant_ia_page.dart';
import 'package:agrismart/screens/export_rapports_page.dart';
import 'package:agrismart/screens/notifications_page.dart';
import 'package:agrismart/screens/zone_detail_page.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/screens/ScannerEtiquettePage.dart';
import 'package:agrismart/screens/diagnostic_plante_page.dart';
import 'package:agrismart/screens/taches_a_venir_page.dart';
import 'package:agrismart/screens/equipements_page.dart';
import 'package:agrismart/screens/journal_activites_page.dart'; // تمت إضافة استيراد صفحة Journal d'activités هنا

class AccueilPage extends StatefulWidget {
  final VoidCallback? onAllerZones;
  final VoidCallback? onAllerStatistiques;
  final VoidCallback? onAllerProfil;
  final VoidCallback? onOuvrirNotifications;

  const AccueilPage({
    super.key,
    this.onAllerZones,
    this.onAllerStatistiques,
    this.onAllerProfil,
    this.onOuvrirNotifications,
  });

  @override
  State<AccueilPage> createState() => AccueilPageState();
}

class AccueilPageState extends State<AccueilPage> {
@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((_) {
if (!mounted) return;
_appelerMethodeSiExiste(context.read<MeteoProvider>(), [
'chargerMeteo',
'fetchMeteo',
'actualiser',
]);
_appelerMethodeSiExiste(context.read<ZonesProvider>(), [
'chargerZones',
'fetchZones',
'actualiser',
]);
});
}

void _appelerMethodeSiExiste(Object target, List<String> nomsMethodes) {
final dynamic dyn = target;
for (final nom in nomsMethodes) {
try {
if (nom == 'chargerMeteo') dyn.chargerMeteo();
if (nom == 'fetchMeteo') dyn.fetchMeteo();
if (nom == 'chargerZones') dyn.chargerZones();
if (nom == 'fetchZones') dyn.fetchZones();
if (nom == 'actualiser') dyn.actualiser();
return;
} catch (_) {}
}
}

String _dateFormatee() {
final now = DateTime.now();
const jours = [
'Lundi',
'Mardi',
'Mercredi',
'Jeudi',
'Vendredi',
'Samedi',
'Dimanche',
];
const mois = [
'Janv',
'Févr',
'Mars',
'Avril',
'Mai',
'Juin',
'Juil',
'Août',
'Sept',
'Oct',
'Nov',
'Déc',
];
final jourNom = jours[now.weekday - 1];
final moisNom = mois[now.month - 1];
return '$jourNom ${now.day} $moisNom';
}

String _nomUtilisateur(AuthProvider authProvider) {
final dynamic a = authProvider;
final dynamic user = _extractUser(a);

final candidates = <dynamic>[
_tryProperty(user, 'nomComplet'),
_tryProperty(user, 'nom'),
_tryProperty(user, 'displayName'),
_tryProperty(user, 'email'),
_tryProperty(a, 'nomUtilisateur'),
_tryProperty(a, 'nom'),
];

for (final val in candidates) {
if (val is String && val.trim().isNotEmpty) {
return val.trim();
}
}
return 'Utilisateur';
}

dynamic _extractUser(dynamic a) {
for (final prop in ['utilisateur', 'user', 'currentUser']) {
final res = _tryProperty(a, prop);
if (res != null) return res;
}
return null;
}

dynamic _tryProperty(dynamic obj, String name) {
if (obj == null) return null;
try {
if (obj is Map) return obj[name];
switch (name) {
case 'utilisateur':
return obj.utilisateur;
case 'user':
return obj.user;
case 'currentUser':
return obj.currentUser;
case 'nomComplet':
return obj.nomComplet;
case 'nom':
return obj.nom;
case 'displayName':
return obj.displayName;
case 'email':
return obj.email;
case 'nomUtilisateur':
return obj.nomUtilisateur;
case 'meteo':
return obj.meteo;
case 'currentMeteo':
return obj.currentMeteo;
case 'donnees':
return obj.donnees;
case 'ville':
return obj.ville;
case 'city':
return obj.city;
case 'temperature':
return obj.temperature;
case 'temp':
return obj.temp;
case 'description':
return obj.description;
case 'condition':
return obj.condition;
case 'zones':
return obj.zones;
case 'nombreAIrriguer':
return obj.nombreAIrriguer;
default:
return null;
}
} catch (_) {
return null;
}
}

dynamic _extractMeteoData(MeteoProvider meteoProvider) {
final dynamic m = meteoProvider;
for (final prop in ['meteo', 'currentMeteo', 'donnees']) {
final res = _tryProperty(m, prop);
if (res != null) return res;
}
return null;
}

String _villeMeteo(MeteoProvider meteoProvider) {
final dynamic m = meteoProvider;
final dynamic data = _extractMeteoData(meteoProvider);
final ville = _tryProperty(data, 'ville') ??
_tryProperty(data, 'city') ??
_tryProperty(m, 'ville');
if (ville is String && ville.trim().isNotEmpty) {
return ville.trim();
}
return 'Kébili';
}

String _temperatureMeteo(MeteoProvider meteoProvider) {
final dynamic m = meteoProvider;
final dynamic data = _extractMeteoData(meteoProvider);
final temp = _tryProperty(data, 'temperature') ??
_tryProperty(data, 'temp') ??
_tryProperty(m, 'temperature') ??
_tryProperty(m, 'temp');

if (temp is num) {
return '${temp.round()}°C';
}
if (temp is String && temp.trim().isNotEmpty) {
return temp.contains('°') ? temp.trim() : '${temp.trim()}°C';
}
return '--°C';
}

  Future<void> _ouvrirRapports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExportRapportsPage(),
      ),
    );
  }

  // ربط زر Tâches à venir بالصفحة الخاصة بها
  Future<void> _ouvrirTachesAVenir() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TachesAVenirPage(
          onNavigate: (index) {
            Navigator.pop(context);
            if (index == 0 && widget.onAllerZones != null) {
              widget.onAllerZones!();
            } else if (index == 1 && widget.onAllerStatistiques != null) {
              widget.onAllerStatistiques!();
            } else if (index == 2 && widget.onAllerProfil != null) {
              widget.onAllerProfil!();
            }
          },
        ),
      ),
    );
  }

  // ربط زر Équipements بصفحة الأجهزة الجديدة
  Future<void> _ouvrirEquipements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipementsPage(
          onNavigate: (index) {
            Navigator.pop(context);
            if (index == 0 && widget.onAllerZones != null) {
              widget.onAllerZones!();
            } else if (index == 1 && widget.onAllerStatistiques != null) {
              widget.onAllerStatistiques!();
            } else if (index == 2 && widget.onAllerProfil != null) {
              widget.onAllerProfil!();
            }
          },
        ),
      ),
    );
  }

  // ربط زر Journal d'activités بصفحة الأنشطة الحقيقية
  Future<void> _ouvrirJournalActivites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalActivitesPage(),
      ),
    );
  }

  Future<void> _ouvrirNotifications() async {
    if (widget.onOuvrirNotifications != null) {
      widget.onOuvrirNotifications!();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          onAllerZones: widget.onAllerZones,
        ),
      ),
    );
  }

if (desc.contains('pluie') || desc.contains('rain')) {
return Icons.grain;
}
if (desc.contains('nuage') || desc.contains('cloud')) {
return Icons.cloud_outlined;
}
return Icons.wb_sunny_outlined;
}

Future<void> _ouvrirAssistantIa(Zone? zoneCible) async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => AssistantIaPage(
zoneInitiale: zoneCible,
),
),
);
}

Future<void> _ouvrirNotifications() async {
if (widget.onOuvrirNotifications != null) {
widget.onOuvrirNotifications!();
return;
}
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => NotificationsPage(
onAllerZones: widget.onAllerZones,
),
),
);
}

Future<void> _ouvrirFormulaire(List<Zone> zones, {Zone? zone}) async {
final nouvelleZone = await Navigator.push<Zone>(
context,
MaterialPageRoute(
builder: (_) => ZoneFormPage(
zone: zone,
nomsExistants:
zones.where((z) => z != zone).map((z) => z.nom).toList(),
),
),
);

if (nouvelleZone == null || !mounted) return;

final dynamic zp = context.read<ZonesProvider>();
try {
await zp.ajouterZone(nouvelleZone);
} catch (_) {}

if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(zone == null ? 'Zone ajoutée' : 'Zone modifiée')),
);
}

Future<void> _ouvrirDetail(List<Zone> zones, Zone zone) async {
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

Future<void> _scannerEtiquette() async {
await Navigator.push(
context,
MaterialPageRoute(builder: (_) => const ScannerEtiquettePage()),
);
}

Future<void> _diagnosticPlante() async {
final resume = await Navigator.push<String>(
context,
MaterialPageRoute(builder: (_) => const DiagnosticPlantePage()),
);
if (resume == null || !mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Diagnostic enregistré : $resume')),
);
}
@override
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();
  final meteoProvider = context.watch<MeteoProvider>();
  final zonesProvider = context.watch<ZonesProvider>();

  final rawZones = _tryProperty(zonesProvider, 'zones');
  final List<Zone> zones = rawZones is List<Zone> ? rawZones : const [];

  final rawAlertes = _tryProperty(zonesProvider, 'nombreAIrriguer');
  final int zonesAIrriguer = rawAlertes is int
      ? rawAlertes
      : zones.where((z) => z.humidite < 35.0).length;

  final Zone? zoneCible = zones.isNotEmpty ? zones.first : null;
  final String nomUser = _nomUtilisateur(authProvider);
  final String zonePrincipale = zoneCible?.nom ?? 'Parcelle Nord';
  final String ville = _villeMeteo(meteoProvider);
  final String temperature = _temperatureMeteo(meteoProvider);

  final String detailSubtitle = zoneCible != null
      ? '${zoneCible.nom} · ${zoneCible.humidite.toStringAsFixed(0)}%'
      : 'Parcelle Nord · Détails';

  return Scaffold(
    backgroundColor: const Color(0xFFF1F5F0),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco, color: Color(0xFF4CAF50), size: 30),
                    SizedBox(width: 6),
                    Text(
                      'AgriSmart',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E7B3A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFFE88D2A),
                        size: 24,
                      ),
                      onPressed: _ouvrirNotifications,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.account_circle_outlined,
                        color: Color(0xFFE88D2A),
                        size: 26,
                      ),
                      onPressed: widget.onAllerProfil ??
                              () => _afficherMessage('Profil'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date et utilisateur
            _CarteBlanche(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Aujourd'hui",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _dateFormatee(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nomUser,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '- $zonePrincipale',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Météo et alertes
            Row(
              children: [
                Expanded(
                  child: _CarteBlanche(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Météo $ville',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              temperature,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Icon(
                              _iconeMeteo(meteoProvider),
                              color: const Color(0xFFEAB308),
                              size: 30,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CarteBlanche(
                    onTap: widget.onAllerZones ??
                            () {
                          if (zoneCible != null) {
                            _ouvrirDetail(zones, zoneCible);
                          }
                        },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alerte',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          zonesAIrriguer == 1
                              ? '1 parcelle à\nirriguer'
                              : '$zonesAIrriguer parcelles à\nirriguer',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grille des fonctionnalités
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.52,
              children: [
                _BoutonVert(
                  icon: Icons.smart_toy,
                  label: 'Assistant IA',
                  onTap: () => _ouvrirAssistantIa(zoneCible),
                ),
                _BoutonVert(
                  icon: Icons.qr_code_scanner,
                  label: 'Scanner Étiquette',
                  onTap: _scannerEtiquette,
                ),
                _BoutonVert(
                  icon: Icons.local_florist,
                  label: 'Diagnostic de plante',
                  onTap: _diagnosticPlante,
                ),
                _BoutonVert(
                  icon: Icons.build,
                  label: 'Équipements',
                  onTap: () => _afficherMessage('Équipements'),
                ),

                // Calendrier agricole connecté
                _BoutonVert(
                  icon: Icons.calendar_today,
                  label: 'Calendrier',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HarvestCalendarPage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Grille des cartes vertes
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.52,
                children: [
                  _BoutonVert(
                    icon: Icons.smart_toy,
                    label: 'Assistant IA',
                    onTap: () => _ouvrirAssistantIa(zoneCible),
                  ),
                  _BoutonVert(
                    icon: Icons.qr_code_scanner,
                    label: 'Scanner Étiquette',
                    onTap: _scannerEtiquette,
                  ),
                  _BoutonVert(
                    icon: Icons.local_florist,
                    label: 'Diagnostic de plante',
                    onTap: _diagnosticPlante,
                  ),
                  _BoutonVert(
                    icon: Icons.build,
                    label: 'Équipements',
                    onTap: _ouvrirEquipements,
                  ),
                  _BoutonVert(
                    icon: Icons.calendar_today,
                    label: 'Calendrier',
                    onTap: () => _afficherMessage('Calendrier'),
                  ),
                  _BoutonVert(
                    icon: Icons.menu_book,
                    label: "Journal d'activités",
                    onTap: _ouvrirJournalActivites, // تم ربط زر Journal d'activités بصفحته الحقيقية
                  ),
                  _BoutonVert(
                    icon: Icons.description,
                    label: 'Guides & Rapports',
                    onTap: _ouvrirRapports,
                  ),
                  _BoutonVert(
                    icon: Icons.shopping_basket,
                    label: 'Tâches à venir',
                    subtitle: 'Récolte Tomates (5j)',
                    onTap: _ouvrirTachesAVenir,
                  ),
                  _BoutonVert(
                    icon: Icons.notifications,
                    label: 'Notifications & Alertes',
                    subtitle: zonesAIrriguer > 0
                        ? '$zonesAIrriguer parcelle(s) à irriguer'
                        : 'Aucune alerte',
                    badgeCount: zonesAIrriguer > 0 ? zonesAIrriguer : null,
                    onTap: _ouvrirNotifications,
                  ),
                  _BoutonVert(
                    icon: Icons.water_drop,
                    label: 'Détails Parcelle',
                    subtitle: detailSubtitle,
                    onTap: () {
                      if (zoneCible != null) {
                        _ouvrirDetail(zones, zoneCible);
                      } else if (widget.onAllerZones != null) {
                        widget.onAllerZones!();
                      } else {
                        _afficherMessage('Aucune parcelle disponible');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF56A832),
      onPressed: () => _ouvrirFormulaire(zones),
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}

void _afficherMessage(String nom) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ouverture : $nom')),
  );
}
}

class _CarteBlanche extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CarteBlanche({
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}

class _BoutonVert extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final int? badgeCount;
  final VoidCallback onTap;

  const _BoutonVert({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF56A832),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (badgeCount != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Color(0xFF3E7B3A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}