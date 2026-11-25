import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zones_page.dart';

class DiagnosticPlantePage extends StatefulWidget {
  final ValueChanged<int>? onSelectNavIndex;
  final ValueChanged<String>? onDemanderIa;

  const DiagnosticPlantePage({
    super.key,
    this.onSelectNavIndex,
    this.onDemanderIa,
  });

  @override
  State<DiagnosticPlantePage> createState() => _DiagnosticPlantePageState();
}

class _Item {
  final String label;
  final double confiance;
  final String type;
  final int tier;
  _Item(this.label, this.confiance, this.type, this.tier);
}

class _DiagnosticPlantePageState extends State<DiagnosticPlantePage>
    with SingleTickerProviderStateMixin {
  static const _vert = Color(0xFF276738);
  static const _vertClair = Color(0xFF56A832);
  static const _scan = Color(0xFF7DF29B);
  static const _cleJournal = 'journal_diagnostics';
  static const double _hauteurImage = 380;

  static const Set<String> _fruits = {
    'banana', 'apple', 'orange', 'strawberry', 'lemon', 'grape', 'pear',
    'peach', 'watermelon', 'pineapple', 'mango', 'cherry', 'melon', 'fig',
    'pomegranate', 'kiwi', 'berry', 'blueberry', 'raspberry', 'grapefruit',
    'mandarin', 'tangerine', 'apricot', 'plum', 'coconut', 'avocado', 'lime',
    'citrus', 'papaya', 'date', 'olive', 'cranberry', 'blackberry',
  };
  static const Set<String> _legumes = {
    'tomato', 'cucumber', 'pumpkin', 'carrot', 'potato', 'onion', 'garlic',
    'pepper', 'bell pepper', 'broccoli', 'cabbage', 'lettuce', 'eggplant',
    'zucchini', 'corn', 'radish', 'cauliflower', 'spinach', 'squash',
  };
  static const Set<String> _plantes = {
    'flower', 'rose', 'tulip', 'sunflower', 'daisy', 'orchid', 'lily',
    'cactus', 'succulent', 'houseplant', 'flowerpot', 'tree', 'palm tree',
    'leaf', 'grass', 'herb', 'shrub', 'bonsai', 'fern', 'lavender', 'petal',
    'seedling', 'branch', 'twig', 'vine',
  };

  final ImagePicker _picker = ImagePicker();
  final ImageLabeler _imageLabeler =
  ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
  late final AnimationController _anim;

  File? selectedImage;
  List<_Item> results = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 0.5,
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  void _majAnimation() {
    if (isLoading) {
      _anim.repeat(reverse: true);
    } else {
      _anim.stop();
      _anim.value = 0.5;
    }
  }

  ({String type, int tier})? _classer(String label) {
    final k = label.toLowerCase();
    if (_fruits.contains(k)) return (type: 'Fruit', tier: 0);
    if (_legumes.contains(k)) return (type: 'Légume', tier: 0);
    if (_plantes.contains(k)) return (type: 'Plante', tier: 1);
    if (k == 'fruit') return (type: 'Fruit', tier: 2);
    if (k == 'vegetable') return (type: 'Légume', tier: 2);
    if (k == 'plant' || k == 'flowering plant') {
      return (type: 'Plante', tier: 2);
    }
    return null;
  }

  void _reinitialiser() {
    setState(() {
      selectedImage = null;
      results = [];
      errorMessage = null;
      isLoading = false;
    });
    _majAnimation();
  }

  Future<void> selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        selectedImage = File(image.path);
        results = [];
        errorMessage = null;
        isLoading = true;
      });
      _majAnimation();

      final inputImage = InputImage.fromFilePath(image.path);
      final labels = await _imageLabeler.processImage(inputImage);

      final items = <_Item>[];
      for (final l in labels) {
        final c = _classer(l.label);
        if (c != null) items.add(_Item(l.label, l.confidence, c.type, c.tier));
      }
      items.sort((a, b) {
        final t = a.tier.compareTo(b.tier);
        return t != 0 ? t : b.confiance.compareTo(a.confiance);
      });

      if (!mounted) return;
      setState(() {
        results = items.take(5).toList();
        isLoading = false;
        if (items.isEmpty) {
          errorMessage = 'Aucun fruit, légume ou plante détecté. Réessaie '
              'avec une photo plus proche et bien éclairée.';
        }
      });
      _majAnimation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Erreur lors de l'analyse de l'image.";
      });
      _majAnimation();
    }
  }

  // Enregistre le résultat dans le journal (stockage local)
  Future<void> _enregistrerJournal(_Item top) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final liste = prefs.getStringList(_cleJournal) ?? <String>[];
      liste.add(jsonEncode({
        'label': top.label,
        'type': top.type,
        'confiance': top.confiance,
        'date': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_cleJournal, liste);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostic enregistré dans le journal')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'enregistrer")),
      );
    }
  }

  int _lireNbZonesAIrriguer(ZonesProvider provider) {
    final dynamic dyn = provider;
    try {
      final val = dyn.nombreAIrriguer;
      if (val is int) return val;
    } catch (_) {}
    try {
      final list = dyn.zones;
      if (list is List) {
        return list.where((z) => z.besoinIrrigation == true).length;
      }
    } catch (_) {}
    return 0;
  }

  void _naviguerBas(int index) {
    if (widget.onSelectNavIndex != null) {
      widget.onSelectNavIndex!(index);
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ZonesPage()),
      );
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  String _etat(double c) {
    if (c >= 0.8) return 'Fiable';
    if (c >= 0.65) return 'Probable';
    return 'À vérifier';
  }

  String _statut(double c) {
    if (c >= 0.8) return 'Confiance élevée';
    if (c >= 0.65) return 'Confiance moyenne';
    return 'Confiance faible';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final top = results.isNotEmpty ? results.first : null;
    final zonesProvider = context.watch<ZonesProvider>();
    final nbZonesAIrriguer = _lireNbZonesAIrriguer(zonesProvider);
    final peutReinitialiser = !isLoading &&
        (selectedImage != null || results.isNotEmpty || errorMessage != null);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (peutReinitialiser)
            IconButton(
              tooltip: 'Réinitialiser',
              onPressed: _reinitialiser,
              icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Diagnostic Plante\n(ML Kit)',
              style: TextStyle(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            // Image + carte de résultat qui la chevauche
            Stack(
              children: [
                SizedBox(
                  height: _hauteurImage,
                  child: _buildImage(isDark, top),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: _hauteurImage - 50,
                    left: 14,
                    right: 14,
                  ),
                  child: _buildCarteResultat(top, isDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBoutonsPhoto(isDark),
            if (results.length > 1) ...[
              const SizedBox(height: 18),
              Text(
                'Autres possibilités',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : _vert,
                ),
              ),
              const SizedBox(height: 10),
              ...results.skip(1).map((item) => _buildLigne(item, isDark)),
            ],
            const SizedBox(height: 14),
            Text(
              'Résultat donné à titre indicatif par ML Kit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor:
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE7EFE6),
        indicatorColor:
        isDark ? const Color(0xFF3A5A3A) : const Color(0xFFCFE8CC),
        selectedIndex: 1,
        onDestinationSelected: _naviguerBas,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: _vert),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$nbZonesAIrriguer'),
              isLabelVisible: nbZonesAIrriguer > 0,
              backgroundColor: const Color(0xFFC93B2B),
              child: const Icon(Icons.grass_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$nbZonesAIrriguer'),
              isLabelVisible: nbZonesAIrriguer > 0,
              backgroundColor: const Color(0xFFC93B2B),
              child: const Icon(Icons.grass, color: _vert),
            ),
            label: 'Zones',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: _vert),
            label: 'Statistiques',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _vert),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ---------- Image avec cadre de scan ----------
  Widget _buildImage(bool isDark, _Item? top) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFCBDDC8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (selectedImage == null)
              InkWell(
                onTap: isLoading
                    ? null
                    : () => selectImage(ImageSource.gallery),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco,
                        size: 70, color: isDark ? Colors.white70 : _vert),
                    const SizedBox(height: 10),
                    Text(
                      'Aucune image sélectionnée',
                      style: TextStyle(
                        color:
                        isDark ? Colors.white54 : const Color(0xFF3E4A40),
                      ),
                    ),
                  ],
                ),
              )
            else
              Image.file(selectedImage!, fit: BoxFit.cover),
            // cadre + ligne de scan
            LayoutBuilder(
              builder: (context, c) {
                final cote = c.maxWidth * 0.48;
                final gauche = (c.maxWidth - cote) / 2;
                final haut = (c.maxHeight - 70 - cote) / 2;
                return AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final y = haut + cote * _anim.value;
                    return Stack(
                      children: [
                        Positioned(
                          left: gauche,
                          top: haut,
                          width: cote,
                          height: cote,
                          child: CustomPaint(painter: _CadrePainter(_scan)),
                        ),
                        Positioned(
                          left: gauche - cote * 0.15,
                          width: cote * 1.3,
                          top: y,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                _scan.withValues(alpha: 0),
                                _scan,
                                _scan.withValues(alpha: 0),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                  color: _scan.withValues(alpha: 0.7),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            // pastille « Détecté »
            Positioned(
              left: 0,
              right: 0,
              bottom: 66,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3A27).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    isLoading
                        ? 'Analyse en cours...'
                        : top != null
                        ? 'Détecté : ${top.label}'
                        : 'Prenez une photo pour analyser',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Carte de résultat ----------
  Widget _buildCarteResultat(_Item? top, bool isDark) {
    final theme = Theme.of(context);
    final fond = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F8EE);
    final vertTexte = isDark ? const Color(0xFF7DD88F) : const Color(0xFF3F8F3A);

    Widget contenu;
    if (errorMessage != null) {
      contenu = Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFFB71C1C),
              ),
            ),
          ),
        ],
      );
    } else if (top == null) {
      contenu = Text(
        isLoading
            ? 'Analyse en cours...'
            : 'Choisissez une photo (Caméra ou Galerie) pour lancer l\'analyse ML Kit.',
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      final pct = (top.confiance * 100).round();
      contenu = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyse ML Kit : ${top.label} ($pct%)',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Diagnostic',
                style: TextStyle(
                  fontSize: 19,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                width: 1.5,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: theme.colorScheme.onSurface,
              ),
              Text(
                top.type,
                style: TextStyle(fontSize: 19, color: vertTexte),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'État : ',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: _etat(top.confiance),
                            style: TextStyle(color: vertTexte),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.eco, size: 18, color: vertTexte),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Statut : ${_statut(top.confiance)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _enregistrerJournal(top),
                style: FilledButton.styleFrom(
                  backgroundColor:
                  isDark ? const Color(0xFF2E5A36) : const Color(0xFF93E8A5),
                  foregroundColor:
                  isDark ? Colors.white : const Color(0xFF1B4D2A),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enregistrer dans le journal',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: contenu,
    );
  }

  // ---------- Boutons Caméra / Galerie ----------
  Widget _buildBoutonsPhoto(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                isLoading ? null : () => selectImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text(
                  'Caméra',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vert,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                isLoading ? null : () => selectImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text(
                  'Galerie',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F8EE),
                  foregroundColor: isDark ? Colors.white70 : _vert,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color:
                      isDark ? Colors.white24 : const Color(0xFFC8D7C6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (results.isNotEmpty && widget.onDemanderIa != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onDemanderIa!(
                "Conseils d'entretien et d'irrigation pour ${results.first.label} (${results.first.type})",
              ),
              icon: const Icon(Icons.auto_awesome, size: 19),
              label: const Text('Conseil IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _vertClair,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLigne(_Item i, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFD2DFD0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            i.type == 'Plante' ? Icons.eco : Icons.local_florist,
            color: _vertClair,
            size: 22,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              i.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: i.confiance,
                minHeight: 8,
                backgroundColor:
                isDark ? Colors.white12 : const Color(0xFFD7E6D3),
                color: _vertClair,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(i.confiance * 100).round()}%',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

// Quatre coins arrondis du cadre de scan
class _CadrePainter extends CustomPainter {
  final Color couleur;
  _CadrePainter(this.couleur);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final l = size.width * 0.24;
    final r = 14.0;
    final w = size.width;
    final h = size.height;

    final path = Path()
    // haut gauche
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0)
    // haut droite
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l)
    // bas droite
      ..moveTo(w, h - l)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(w - l, h)
    // bas gauche
      ..moveTo(l, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, h - l);

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CadrePainter old) => old.couleur != couleur;
}