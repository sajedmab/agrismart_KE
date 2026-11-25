import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zones_page.dart';

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
  // On garde les couleurs vertes de base qui fonctionnent bien
  static const Color _vertFonce = Color(0xFF4E8A42);
  static const Color _vertApp = Color(0xFF276738);
  static const Color _vertBouton = Color(0xFF9CE08E);
  static const Color _rougeAlerte = Color(0xFFC93B2B);

  String _periodeSelectionnee = 'Ce mois-ci';
  String _zoneSelectionnee = 'Toutes les parcelles';
  bool _isExporting = false;
  File? _dernierFichierPdf;
  List<File> _fichiersPdfDisponibles = [];

  @override
  void initState() {
    super.initState();
    _chargerFichiersPdf();
  }

  List<Zone> _extraireZones(ZonesProvider provider) {
    final dynamic dyn = provider;
    try {
      final list = dyn.zones;
      if (list is List<Zone>) return list;
    } catch (_) {}
    return const [];
  }

  int _lireNbZonesAIrriguer(ZonesProvider provider, List<Zone> zones) {
    final dynamic dyn = provider;
    try {
      final val = dyn.nombreAIrriguer;
      if (val is int) return val;
    } catch (_) {}
    return zones.where((z) => z.besoinIrrigation).length;
  }

  Future<Directory> _dossierRapports() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/rapports_agrismart');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _chargerFichiersPdf() async {
    try {
      final dir = await _dossierRapports();
      final entities = await dir.list().toList();
      final pdfs = entities
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (!mounted) return;
      setState(() {
        _fichiersPdfDisponibles = pdfs;
        if (_dernierFichierPdf == null && pdfs.isNotEmpty) {
          _dernierFichierPdf = pdfs.first;
        }
      });
    } catch (_) {}
  }

  String _nettoyerTextePdf(String input) {
    final sansAccents = input
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Ç', 'C')
        .replaceAll('°', ' deg ')
        .replaceAll('’', "'")
        .replaceAll('–', '-');

    return sansAccents
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)');
  }

  Uint8List _construireOctetsPdf(List<String> lignes) {
    final buffer = StringBuffer();
    buffer.writeln('BT');
    buffer.writeln('/F1 18 Tf');
    buffer.writeln('50 760 Td');
    buffer.writeln('(${_nettoyerTextePdf(lignes.first)}) Tj');

    buffer.writeln('/F1 12 Tf');
    buffer.writeln('0 -28 Td');
    for (int i = 1; i < lignes.length; i++) {
      buffer.writeln('(${_nettoyerTextePdf(lignes[i])}) Tj');
      buffer.writeln('0 -20 Td');
    }
    buffer.writeln('ET');

    final contentStream = buffer.toString();
    final contentBytes = latin1.encode(contentStream);

    final objects = <String>[
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n',
      '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
      '5 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n$contentStream\nendstream\nendobj\n',
    ];

    final pdfBuilder = StringBuffer();
    pdfBuilder.writeln('%PDF-1.4');

    final offsets = <int>[0];
    int currentOffset = latin1.encode('%PDF-1.4\n').length;

    for (final obj in objects) {
      offsets.add(currentOffset);
      pdfBuilder.write(obj);
      currentOffset += latin1.encode(obj).length;
    }

    final xrefOffset = currentOffset;
    pdfBuilder.writeln('xref');
    pdfBuilder.writeln('0 ${objects.length + 1}');
    pdfBuilder.writeln('0000000000 65535 f ');
    for (int i = 1; i < offsets.length; i++) {
      final padded = offsets[i].toString().padLeft(10, '0');
      pdfBuilder.writeln('$padded 00000 n ');
    }
    pdfBuilder.writeln('trailer');
    pdfBuilder.writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>');
    pdfBuilder.writeln('startxref');
    pdfBuilder.writeln('$xrefOffset');
    pdfBuilder.writeln('%%EOF');

    return Uint8List.fromList(latin1.encode(pdfBuilder.toString()));
  }

  List<String> _lignesRapport(
      List<Zone> zones,
      int cycles,
      int litres,
      double humMoy,
      int alertesResolues,
      ) {
    return [
      'AgriSmart - Rapport : Novembre 2026',
      'Periode : $_periodeSelectionnee',
      'Zone : $_zoneSelectionnee',
      'Irrigations : $cycles cycles (${litres}L)',
      'Humidite moy. : ${humMoy.toStringAsFixed(1)}%',
      'Alertes resolues : $alertesResolues',
      'Nombre de zones analysees : ${zones.length}',
    ];
  }

  Future<void> _exporterPdf(
      List<Zone> zones,
      int cycles,
      int litres,
      double humMoy,
      int alertesResolues,
      ) async {
    setState(() => _isExporting = true);
    try {
      final dir = await _dossierRapports();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fichier = File('${dir.path}/rapport_agrismart_$ts.pdf');

      final lignes =
      _lignesRapport(zones, cycles, litres, humMoy, alertesResolues);
      final bytes = _construireOctetsPdf(lignes);
      await fichier.writeAsBytes(bytes, flush: true);

      await _chargerFichiersPdf();
      if (!mounted) return;
      setState(() {
        _dernierFichierPdf = fichier;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF285226),
          content: Text('Fichier PDF créé : ${fichier.path.split('/').last.split('\\').last}'),
          action: SnackBarAction(
            label: 'Choisir PDF',
            textColor: Colors.white,
            onPressed: _ouvrirSelecteurFichierPdf,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la création du fichier PDF."),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exporterCsv(
      List<Zone> zones,
      int cycles,
      int litres,
      double humMoy,
      int alertesResolues,
      ) async {
    setState(() => _isExporting = true);
    try {
      final dir = await _dossierRapports();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fichier = File('${dir.path}/rapport_agrismart_$ts.csv');

      final csvBuffer = StringBuffer();
      csvBuffer.writeln(
          'Periode,Zone,Irrigations_Cycles,Volume_Litres,Humidite_Moyenne,Alertes_Resolues');
      csvBuffer.writeln(
          '"$_periodeSelectionnee","$_zoneSelectionnee",$cycles,$litres,${humMoy.toStringAsFixed(1)},$alertesResolues');

      if (zones.isNotEmpty) {
        csvBuffer.writeln('');
        csvBuffer.writeln('Parcelle,Culture,Humidite_Pct,Seuil_Pct,Statut');
        for (final z in zones) {
          final statut = z.besoinIrrigation ? 'A irriguer' : 'Suffisante';
          csvBuffer.writeln(
              '"${z.nom}","${z.culture}",${z.humidite.toStringAsFixed(1)},${z.seuil.toStringAsFixed(1)},"$statut"');
        }
      }

      await fichier.writeAsString(csvBuffer.toString(), flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF285226),
          content: Text(
            'Fichier CSV créé : ${fichier.path.split('/').last.split('\\').last}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la création du fichier CSV."),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _ouvrirSelecteurFichierPdf() async {
    await _chargerFichiersPdf();
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F7F1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: _vertApp),
                    const SizedBox(width: 8),
                    Text(
                      'Choisir un fichier PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_fichiersPdfDisponibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Aucun fichier PDF trouvé. Clique sur "Exporter en PDF" pour en créer un.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _fichiersPdfDisponibles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _fichiersPdfDisponibles[index];
                        final nom = file.path.split('/').last.split('\\').last;
                        final tailleKo =
                        (file.lengthSync() / 1024).toStringAsFixed(1);
                        final estSelectionne =
                            _dernierFichierPdf?.path == file.path;

                        return ListTile(
                          leading: Icon(
                            Icons.picture_as_pdf_outlined,
                            color: estSelectionne ? _vertApp : _vertFonce,
                          ),
                          title: Text(
                            nom,
                            style: TextStyle(
                              fontWeight: estSelectionne
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '$tailleKo Ko · ${file.path}',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          trailing: estSelectionne
                              ? const Icon(Icons.check_circle, color: _vertApp)
                              : null,
                          onTap: () async {
                            setState(() => _dernierFichierPdf = file);
                            await Clipboard.setData(
                              ClipboardData(text: file.path),
                            );
                            if (context.mounted) Navigator.pop(context);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('PDF sélectionné : $nom'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _choisirPeriodePersonnalisee() async {
    final theme = Theme.of(context);
    final DateTimeRange? plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _vertFonce,
              onPrimary: Colors.white,
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

  void _naviguerBas(int index) {
    if (widget.onSelectNavIndex != null) {
      widget.onSelectNavIndex!(index);
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ZonesPage()),
      );
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Récupération du thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final zonesProvider = context.watch<ZonesProvider>();
    final zones = _extraireZones(zonesProvider);
    final nbZonesAIrriguer = _lireNbZonesAIrriguer(zonesProvider, zones);

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

    final nomPdfActuel = _dernierFichierPdf != null
        ? _dernierFichierPdf!.path.split('/').last.split('\\').last
        : null;

    return Scaffold(
      // ✅ Fond dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Exportation des rapports',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Choisir un fichier PDF',
            icon: const Icon(Icons.folder_open, color: _vertApp),
            onPressed: _ouvrirSelecteurFichierPdf,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Générer un Rapport',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Période',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
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
                    isDark: isDark, // ✅ On passe le thème
                  ),
                  _FiltreChip(
                    label: _periodeSelectionnee != 'Ce mois-ci'
                        ? _periodeSelectionnee
                        : 'Personnalisé',
                    selected: _periodeSelectionnee != 'Ce mois-ci',
                    onTap: _choisirPeriodePersonnalisee,
                    isDark: isDark, // ✅ On passe le thème
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
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
                        isDark: isDark, // ✅ On passe le thème
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // ✅ Flexible : le nom du PDF se tronque au lieu de déborder (bande jaune)
              Row(
                children: [
                  Text(
                    'Aperçu du Rapport',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _ouvrirSelecteurFichierPdf,
                        icon: const Icon(Icons.picture_as_pdf,
                            size: 18, color: _vertApp),
                        label: Text(
                          nomPdfActuel ?? 'Choisir PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _vertApp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // ✅ Fond de la carte d'aperçu
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F7F1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(
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
                          Text(
                            'Rapport : Novembre 2026',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Irrigations : $cycles cycles (${litres}L)',
                            style: TextStyle(
                              fontSize: 15.5,
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Humidité moy. : ${humMoy.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 15.5,
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Alertes résolues : $alertesResolues',
                            style: TextStyle(
                              fontSize: 15.5,
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                          if (nomPdfActuel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Fichier PDF : $nomPdfActuel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _vertApp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ApercuDocumentIllustration(isDark: isDark), // ✅ On passe le thème
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () => _exporterPdf(zones, cycles, litres, humMoy, alertesResolues),
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF283D27)),
                  label: const Text(
                    'Exporter en PDF',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF283D27),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vertBouton,
                    foregroundColor: const Color(0xFF283D27),
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
                  onPressed: _isExporting
                      ? null
                      : () => _exporterCsv(zones, cycles, litres, humMoy, alertesResolues),
                  icon: Icon(Icons.table_chart_outlined, color: theme.colorScheme.onSurface),
                  label: Text(
                    'Exporter en CSV',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    // ✅ Fond du bouton CSV dynamique
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5EEE4),
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFF9EB59B),
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
        // ✅ Fond de la navbar dynamique
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : theme.scaffoldBackgroundColor,
        indicatorColor: isDark ? const Color(0xFF3A5A3A) : const Color(0xFFD6E5D4),
        selectedIndex: 0,
        onDestinationSelected: _naviguerBas,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurfaceVariant),
            selectedIcon: const Icon(Icons.home, color: _vertApp),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$nbZonesAIrriguer'),
              isLabelVisible: nbZonesAIrriguer > 0,
              backgroundColor: _rougeAlerte,
              child: Icon(Icons.grass_outlined, color: theme.colorScheme.onSurface),
            ),
            selectedIcon: Badge(
              label: Text('$nbZonesAIrriguer'),
              isLabelVisible: nbZonesAIrriguer > 0,
              backgroundColor: _rougeAlerte,
              child: const Icon(Icons.grass, color: _vertApp),
            ),
            label: 'Zones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: theme.colorScheme.onSurfaceVariant),
            selectedIcon: const Icon(Icons.bar_chart, color: _vertApp),
            label: 'Statistiques',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: theme.colorScheme.onSurfaceVariant),
            selectedIcon: const Icon(Icons.person, color: _vertApp),
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
  final bool isDark; // ✅ Ajout du paramètre

  const _FiltreChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      // ✅ Couleur du chip dynamique
      color: selected
          ? const Color(0xFF4E8A42)
          : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F7F1)),
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
                  // ✅ Texte dynamique
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
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
  final bool isDark; // ✅ Ajout du paramètre

  const _ApercuDocumentIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // ✅ Fond de la miniature dynamique
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFD8E2D7),
        ),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
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
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8F2),
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
                // ✅ Couleur des lignes de texte dynamique
                color: isDark ? Colors.white24 : const Color(0xFF9AA59B),
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
