import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

class _DiagnosticPlantePageState extends State<DiagnosticPlantePage> {
  static const _vert = Color(0xFF276738);
  static const _vertClair = Color(0xFF56A832);
  static const _fond = Color(0xFFE7EFE6);
  static const _surface = Color(0xFFF2F7F1);

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

  File? selectedImage;
  List<_Item> results = [];
  bool isLoading = false;
  String? errorMessage;

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Erreur lors de l'analyse de l'image.";
      });
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

  @override
  void dispose() {
    _imageLabeler.close();
    super.dispose();
  }

  String _phrase(_Item i) {
    switch (i.type) {
      case 'Fruit':
        return "C'est un fruit";
      case 'Légume':
        return "C'est un légume";
      default:
        return "C'est une plante";
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = results.isNotEmpty ? results.first : null;
    final zonesProvider = context.watch<ZonesProvider>();
    final nbZonesAIrriguer = _lireNbZonesAIrriguer(zonesProvider);
    final peutReinitialiser = !isLoading &&
        (selectedImage != null || results.isNotEmpty || errorMessage != null);

    return Scaffold(
      backgroundColor: _fond,
      appBar: AppBar(
        title: const Text(
          'Diagnostic de plante',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF171E18)),
        ),
        backgroundColor: _fond,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (peutReinitialiser)
            IconButton(
              tooltip: 'Réinitialiser',
              onPressed: _reinitialiser,
              icon: const Icon(Icons.refresh, color: _vert),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(),
            const SizedBox(height: 16),
            _buildBoutonsActions(peutReinitialiser, top),
            const SizedBox(height: 20),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: _vert),
                    SizedBox(height: 12),
                    Text('Analyse en cours...'),
                  ],
                ),
              ),
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Color(0xFFB71C1C)),
                      ),
                    ),
                  ],
                ),
              ),
            if (top != null) ...[
              _buildHero(top),
              if (results.length > 1) ...[
                const SizedBox(height: 18),
                const Text(
                  'Autres possibilités',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _vert,
                  ),
                ),
                const SizedBox(height: 10),
                ...results.skip(1).map(_buildLigne),
              ],
            ],
            const SizedBox(height: 18),
            const Text(
              'Résultat donné à titre indicatif par ML Kit.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFE7EFE6),
        indicatorColor: const Color(0xFFD6E5D4),
        selectedIndex: 0,
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

  Widget _buildBoutonsActions(bool peutReinitialiser, _Item? top) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  elevation: 2,
                  shadowColor: _vert.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                  backgroundColor: _surface,
                  foregroundColor: _vert,
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFC8D7C6), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (peutReinitialiser || top != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (peutReinitialiser)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reinitialiser,
                    icon: const Icon(Icons.delete_outline, size: 19),
                    label: const Text('Effacer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3E4A40),
                      backgroundColor: _surface,
                      side: const BorderSide(color: Color(0xFFC8D7C6)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (peutReinitialiser && top != null && widget.onDemanderIa != null)
                const SizedBox(width: 10),
              if (top != null && widget.onDemanderIa != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onDemanderIa!(
                      "Conseils d'entretien et d'irrigation pour ${top.label} (${top.type})",
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 19),
                    label: const Text('Conseil IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vertClair,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImage() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD2DFD0)),
      ),
      child: selectedImage == null
          ? const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 65, color: _vert),
          SizedBox(height: 12),
          Text(
            'Aucune image sélectionnée',
            style: TextStyle(color: Color(0xFF3E4A40)),
          ),
        ],
      )
          : ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          selectedImage!,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHero(_Item top) {
    final pct = (top.confiance * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_vertClair, _vert],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phrase(top),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  top.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    top.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: top.confiance,
                    strokeWidth: 7,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLigne(_Item i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2DFD0)),
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: i.confiance,
                minHeight: 8,
                backgroundColor: const Color(0xFFD7E6D3),
                color: _vertClair,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(i.confiance * 100).round()}%',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}