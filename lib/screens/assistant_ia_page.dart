import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';

class AssistantIaPage extends StatefulWidget {
  final Zone? zoneInitiale;
  final String? apiKey;
  final ValueChanged<int>? onSelectNavIndex;

  const AssistantIaPage({
    super.key,
    this.zoneInitiale,
    this.apiKey,
    this.onSelectNavIndex,
  });

  @override
  State<AssistantIaPage> createState() => _AssistantIaPageState();
}

class _AssistantIaPageState extends State<AssistantIaPage> {
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_MessageChat> _messages = [];
  bool _initialise = false;
  bool _enCoursEnvoi = false;
  bool _enCoursAction = false;

  final List<String> _questionsRapides = [
    'Quand irriguer les tomates à Kébili ?',
    'Quelles parcelles ont besoin d\'eau ?',
    'Conseil météo et arrosage aujourd\'hui',
  ];

  String get _cleApi {
    if (widget.apiKey != null && widget.apiKey!.trim().isNotEmpty) {
      return widget.apiKey!.trim();
    }
    return _envApiKey.trim();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialise) return;
    _initialise = true;

    final zonesProvider = context.read<ZonesProvider>();
    final meteoProvider = context.read<MeteoProvider>();
    final zones = _extraireZones(zonesProvider);
    final zoneCible = _choisirZoneCible(zones);
    final ville = _extraireVille(meteoProvider);

    final questionInitiale =
        'Quand irriguer ${zoneCible != null ? 'les ${zoneCible.culture.toLowerCase()}' : 'les tomates'} à $ville ?';

    _messages.add(
      _MessageChat(
        estUtilisateur: true,
        texte: questionInitiale,
      ),
    );
    _demanderReponseIa(
      question: questionInitiale,
      zones: zones,
      meteoProvider: meteoProvider,
      zoneCible: zoneCible,
      ajouterMessageUtilisateur: false,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Zone> _extraireZones(ZonesProvider provider) {
    final dynamic dyn = provider;
    try {
      final list = dyn.zones;
      if (list is List<Zone>) return list;
    } catch (_) {}
    return const [];
  }

  Zone? _choisirZoneCible(List<Zone> zones) {
    if (widget.zoneInitiale != null) {
      for (final z in zones) {
        if (z.nom == widget.zoneInitiale!.nom) return z;
      }
      return widget.zoneInitiale;
    }
    if (zones.isEmpty) return null;
    for (final z in zones) {
      if (z.besoinIrrigation) return z;
    }
    return zones.first;
  }

  Map<String, dynamic>? _objetVersMap(dynamic obj) {
    if (obj == null) return null;
    if (obj is Map<String, dynamic>) return obj;
    if (obj is Map) {
      return obj.map((k, v) => MapEntry(k.toString(), v));
    }
    try {
      final json = obj.toJson();
      if (json is Map<String, dynamic>) return json;
      if (json is Map) {
        return json.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }

  dynamic _extraireMeteoObj(MeteoProvider provider) {
    final dynamic dyn = provider;
    for (final prop in ['meteo', 'currentMeteo', 'donnees']) {
      try {
        final val = _lireChampDyn(dyn, prop);
        if (val != null) return val;
      } catch (_) {}
    }
    return null;
  }

  dynamic _lireChampDyn(dynamic obj, String champ) {
    if (obj == null) return null;

    final map = _objetVersMap(obj);
    if (map != null && map.containsKey(champ)) {
      return map[champ];
    }

    try {
      switch (champ) {
        case 'meteo':
          return obj.meteo;
        case 'currentMeteo':
          return obj.currentMeteo;
        case 'donnees':
          return obj.donnees;
        case 'temperature':
          return obj.temperature;
        case 'temp':
          return obj.temp;
        case 'description':
          return obj.description;
        case 'condition':
          return obj.condition;
        case 'nombreAIrriguer':
          return obj.nombreAIrriguer;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  String _extraireVille(MeteoProvider provider) {
    final dynamic data = _extraireMeteoObj(provider);
    final map = _objetVersMap(data);
    final raw = map?['ville'] ?? map?['city'] ?? map?['location'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return 'Kébili';
  }

  String? _extraireTemperature(MeteoProvider provider) {
    final dynamic dyn = provider;
    final dynamic data = _extraireMeteoObj(provider);
    final raw = _lireChampDyn(data, 'temperature') ??
        _lireChampDyn(data, 'temp') ??
        _lireChampDyn(dyn, 'temperature') ??
        _lireChampDyn(dyn, 'temp');
    if (raw is num) return '${raw.round()}°C';
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.contains('°') ? raw.trim() : '${raw.trim()}°C';
    }
    return null;
  }

  String _extraireConditionMeteo(MeteoProvider provider) {
    final dynamic data = _extraireMeteoObj(provider);
    final raw =
        _lireChampDyn(data, 'description') ?? _lireChampDyn(data, 'condition');
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return 'ensoleillées et sèches';
  }

  String _construireContexteAgricole(
      List<Zone> zones,
      MeteoProvider meteoProvider,
      ) {
    final ville = _extraireVille(meteoProvider);
    final temp = _extraireTemperature(meteoProvider) ?? 'non disponible';
    final condition = _extraireConditionMeteo(meteoProvider);

    final lignesZones = zones.isEmpty
        ? 'Aucune parcelle enregistrée.'
        : zones
        .map(
          (z) =>
      '- ${z.nom}: culture=${z.culture}, humidite=${z.humidite.toStringAsFixed(1)}%, seuil=${z.seuil.toStringAsFixed(1)}%, vanne=${z.vanneOuverte ? "ouverte" : "fermee"}, besoinIrrigation=${z.besoinIrrigation}',
    )
        .join('\n');

    return '''
Tu es l'assistant agricole intelligent de l'application AgriSmart.
Réponds en français clair, concis et pratique pour un agriculteur.
Données météo actuelles :
- Ville : $ville
- Température : $temp
- Condition : $condition

Données des parcelles :
$lignesZones
''';
  }

  Future<String> _appelerGemini({
    required String question,
    required List<Zone> zones,
    required MeteoProvider meteoProvider,
  }) async {
    final apiKey = _cleApi;
    if (apiKey.isEmpty) {
      return _reponseSecours(
        zones: zones,
        meteoProvider: meteoProvider,
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final systemPrompt = _construireContexteAgricole(zones, meteoProvider);

    final historiqueRecent = _messages.length > 6
        ? _messages.sublist(_messages.length - 6)
        : _messages;

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {
            'text':
            'Compris. J\'analyserai vos parcelles et la météo pour vous donner des recommandations d\'irrigation précises.',
          },
        ],
      },
      ...historiqueRecent.map(
            (m) => {
          'role': m.estUtilisateur ? 'user' : 'model',
          'parts': [
            {'text': m.texte},
          ],
        },
      ),
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    try {
      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 500,
          },
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final candidates = decoded['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final first = candidates.first;
            if (first is Map<String, dynamic>) {
              final content = first['content'];
              if (content is Map<String, dynamic>) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final text = parts.first['text'];
                  if (text is String && text.trim().isNotEmpty) {
                    return text.trim();
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return _reponseSecours(
      zones: zones,
      meteoProvider: meteoProvider,
    );
  }

  String _reponseSecours({
    required List<Zone> zones,
    required MeteoProvider meteoProvider,
  }) {
    final ville = _extraireVille(meteoProvider);
    final temp = _extraireTemperature(meteoProvider);
    final condition = _extraireConditionMeteo(meteoProvider);

    if (zones.isEmpty) {
      return "À $ville${temp != null ? ' ($temp, $condition)' : ''}, aucune parcelle n'est enregistrée.";
    }

    final zone = _choisirZoneCible(zones) ?? zones.first;
    final humStr = zone.humidite.toStringAsFixed(1);
    final seuilStr = zone.seuil.toStringAsFixed(1);

    if (zone.humidite < zone.seuil) {
      return "D'après les données de la ${zone.nom} (${zone.culture}), l'humidité est actuellement à $humStr%, ce qui est inférieur au seuil recommandé de $seuilStr%.\n\n"
          "Il est conseillé d'irriguer dès maintenant à $ville${temp != null ? ' ($temp, $condition)' : ''} pour éviter un stress hydrique, idéalement en fin de journée.";
    }

    return "D'après les données de la ${zone.nom} (${zone.culture}), l'humidité est à $humStr% (seuil $seuilStr%) à $ville${temp != null ? ' ($temp, $condition)' : ''}. Aucune irrigation urgente n'est nécessaire.";
  }

  Future<void> _demanderReponseIa({
    required String question,
    required List<Zone> zones,
    required MeteoProvider meteoProvider,
    required Zone? zoneCible,
    required bool ajouterMessageUtilisateur,
  }) async {
    if (_enCoursEnvoi) return;

    setState(() {
      if (ajouterMessageUtilisateur) {
        _messages.add(_MessageChat(estUtilisateur: true, texte: question));
      }
      _enCoursEnvoi = true;
    });
    _defilerVersLeBas();

    final reponse = await _appelerGemini(
      question: question,
      zones: zones,
      meteoProvider: meteoProvider,
    );

    if (!mounted) return;
    setState(() {
      _enCoursEnvoi = false;
      _messages.add(
        _MessageChat(
          estUtilisateur: false,
          texte: reponse,
          zoneAction: zoneCible,
          afficherBoutonIrrigation:
          zoneCible != null && zoneCible.besoinIrrigation,
        ),
      );
    });
    _defilerVersLeBas();
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

  Future<void> _enregistrerIrrigationFirestore(
      Zone zone, {
        required int dureeMinutes,
        required double humiditeApres,
      }) async {
    await FirebaseFirestore.instance
        .collection('zones')
        .doc(_zoneDocId(zone))
        .collection('historique_irrigations')
        .add({
      'zoneNom': zone.nom,
      'dureeMinutes': dureeMinutes,
      'humiditeApres': humiditeApres,
      'source': 'assistant_ia',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _demarrerIrrigationDepuisIa(Zone zone) async {
    if (_enCoursAction) return;
    setState(() => _enCoursAction = true);

    const int dureeMinutes = 15;
    final double nouvelleHumidite = (zone.humidite + 20.0).clamp(0.0, 100.0);
    final dynamic zp = context.read<ZonesProvider>();

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
        break;
      } catch (_) {}
    }

    try {
      await _enregistrerIrrigationFirestore(
        zone,
        dureeMinutes: dureeMinutes,
        humiditeApres: nouvelleHumidite,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _enCoursAction = false;
      _messages.add(
        _MessageChat(
          estUtilisateur: false,
          texte:
          "Irrigation lancée pendant $dureeMinutes min sur '${zone.nom}' et enregistrée dans l'historique.",
          afficherBoutonIrrigation: false,
        ),
      );
    });

    _defilerVersLeBas();
  }

  void _envoyerMessage([String? texteForce]) {
    final texte = (texteForce ?? _messageController.text).trim();
    if (texte.isEmpty || _enCoursEnvoi) return;

    if (texteForce == null) {
      _messageController.clear();
    }

    final zonesProvider = context.read<ZonesProvider>();
    final meteoProvider = context.read<MeteoProvider>();
    final zones = _extraireZones(zonesProvider);
    final zoneCible = _choisirZoneCible(zones);

    _demanderReponseIa(
      question: texte,
      zones: zones,
      meteoProvider: meteoProvider,
      zoneCible: zoneCible,
      ajouterMessageUtilisateur: true,
    );
  }

  void _defilerVersLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  int _lireNombreAIrriguer(ZonesProvider provider, List<Zone> zones) {
    final dynamic dyn = provider;
    try {
      final val = dyn.nombreAIrriguer;
      if (val is int) return val;
    } catch (_) {}
    return zones.where((z) => z.besoinIrrigation).length;
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
    context.watch<MeteoProvider>();

    final zones = _extraireZones(zonesProvider);
    final aIrriguer = _lireNombreAIrriguer(zonesProvider, zones);

    return Scaffold(
      backgroundColor: const Color(0xFFE7EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7EFE6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A221B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Scanner',
            icon: const Icon(Icons.qr_code_2, color: Color(0xFF1A221B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner QR / parcelle')),
              );
            },
          ),
          IconButton(
            tooltip: 'Quitter',
            icon: const Icon(Icons.logout, color: Color(0xFF1A221B)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(
              'Assistant Agricole IA',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                color: Color(0xFF171E18),
              ),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  Text(
                    'Assistant IA AgriSmart 🤖',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A221B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Posez vos questions sur la gestion de vos\nparcelles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.3,
                      color: Color(0xFF3E4A40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _questionsRapides.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final q = _questionsRapides[i];
                return ActionChip(
                  backgroundColor: const Color(0xFFF3F8F2),
                  side: const BorderSide(color: Color(0xFFC8D7C6)),
                  label: Text(
                    q,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1F2B21),
                    ),
                  ),
                  onPressed: () => _envoyerMessage(q),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              itemCount: _messages.length + (_enCoursEnvoi ? 1 : 0),
              itemBuilder: (context, index) {
                if (_enCoursEnvoi && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                if (msg.estUtilisateur) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14, left: 60),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF63A843),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        msg.texte,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14, right: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7F1),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1ECE0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'IA AgriSmart 🤖',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2B21),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          msg.texte,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.38,
                            color: Color(0xFF1A221B),
                          ),
                        ),
                        if (msg.afficherBoutonIrrigation &&
                            msg.zoneAction != null) ...[
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDCE9DA),
                              foregroundColor: const Color(0xFF1F3A22),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _enCoursAction
                                ? null
                                : () => _demarrerIrrigationDepuisIa(
                              msg.zoneAction!,
                            ),
                            icon: const Icon(
                              Icons.water_drop,
                              color: Color(0xFF4BA3E3),
                              size: 18,
                            ),
                            label: const Text(
                              "Démarrer l'irrigation",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8F2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _envoyerMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Écrivez votre message...',
                        hintStyle: TextStyle(
                          color: Color(0xFF6B776D),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _envoyerMessage(),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFF559B38),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFE7EFE6),
        indicatorColor: const Color(0xFFD6E5D4),
        selectedIndex: 0,
        onDestinationSelected: _naviguerBas,
        destinations: [
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

class _MessageChat {
  final bool estUtilisateur;
  final String texte;
  final Zone? zoneAction;
  final bool afficherBoutonIrrigation;

  const _MessageChat({
    required this.estUtilisateur,
    required this.texte,
    this.zoneAction,
    this.afficherBoutonIrrigation = false,
  });
}