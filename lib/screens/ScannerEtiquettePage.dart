import 'dart:io';

import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zone_detail_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:provider/provider.dart';

class ScannerEtiquettePage extends StatefulWidget {
  const ScannerEtiquettePage({super.key});

  @override
  State<ScannerEtiquettePage> createState() => _ScannerEtiquettePageState();
}

class _ScannerEtiquettePageState extends State<ScannerEtiquettePage>
    with SingleTickerProviderStateMixin {
  static const _vert = Color(0xFF56A832);
  static const _vertClair = Color(0xFF9BE58A);
  static const _fond = Color(0xFFDDE9DA);

  CameraController? _controller;
  final BarcodeScanner _scanner =
  BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  late final AnimationController _scanAnim;

  bool _busy = false;
  bool _done = false;
  String? _error;
  String? _code;
  Zone? _zone;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.startImageStream(_processFrame);
      if (!mounted) return;
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'Caméra indisponible : ${e.code}');
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final rotation = InputImageRotationValue.fromRawValue(
        _controller!.description.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_busy || _done) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final codes = await _scanner.processImage(input);
      final value = codes
          .map((c) => c.rawValue)
          .firstWhere((v) => v != null && v.trim().isNotEmpty,
          orElse: () => null);
      if (value != null) {
        _done = true;
        HapticFeedback.mediumImpact();
        await _controller?.stopImageStream();
        if (!mounted) return;
        setState(() {
          _code = value.trim();
          _zone = _trouverZone(_code!);
        });
        _scanAnim.stop();
      }
    } catch (_) {
      // frame ignorée
    } finally {
      _busy = false;
    }
  }

  List<Zone> _zones() {
    try {
      final dynamic zp = context.read<ZonesProvider>();
      final dynamic raw = zp.zones;
      if (raw is List<Zone>) return raw;
    } catch (_) {}
    return const [];
  }

  Zone? _trouverZone(String code) {
    final c = code.toLowerCase();
    for (final z in _zones()) {
      if (z.nom.trim().toLowerCase() == c) return z;
    }
    for (final z in _zones()) {
      final n = z.nom.trim().toLowerCase();
      if (c.contains(n) || n.contains(c)) return z;
    }
    return null;
  }

  String? _culture(Zone z) {
    final dynamic d = z;
    for (final getter in <dynamic Function()>[
          () => d.culture,
          () => d.typeCulture,
          () => d.cultureType,
    ]) {
      try {
        final v = getter();
        if (v is String && v.trim().isNotEmpty) return v.trim();
      } catch (_) {}
    }
    return null;
  }

  Future<void> _reinitialiser() async {
    setState(() {
      _code = null;
      _zone = null;
      _done = false;
    });
    _scanAnim.repeat(reverse: true);
    try {
      await _controller?.startImageStream(_processFrame);
    } catch (_) {}
  }

  void _ouvrirDetails(Zone zone) {
    final autres =
    _zones().where((z) => z != zone).map((z) => z.nom).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(zone: zone, nomsAutres: autres),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller?.dispose();
    _scanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFF1F3A1F), size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scanner QR Parcelle\n',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F3A1F),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: _buildZoneCamera()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneCamera() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: Colors.black,
              child: _error != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white)),
                ),
              )
                  : _controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPreview(),
            ),
          ),
        ),
        if (_code != null) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: _zone != null ? 150 : 110,
            child: Center(child: _pastille()),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: _carteResultat(),
          ),
        ] else
          const Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Text(
              'Place le QR code dans le cadre',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
      ],
    );
  }

  Widget _buildPreview() {
    final c = _controller!;
    final ps = c.value.previewSize!;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ps.height,
            height: ps.width,
            child: CameraPreview(c),
          ),
        ),
        Center(
          child: SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CoinsPainter(_vertClair)),
                ),
                if (_code == null)
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (_, __) => Align(
                      alignment: Alignment(0, _scanAnim.value * 1.8 - 0.9),
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _vertClair,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: _vertClair.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pastille() {
    final ok = _zone != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (ok ? const Color(0xFF2F4A2F) : const Color(0xFF7A2B2B))
            .withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              ok
                  ? 'Code détecté : ${_zone!.nom}'
                  : 'Code non reconnu : $_code',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          Icon(ok ? Icons.check_circle : Icons.error,
              color: ok ? _vertClair : Colors.redAccent, size: 20),
        ],
      ),
    );
  }

  Widget _carteResultat() {
    final zone = _zone;
    final aIrriguer = zone != null && zone.humidite < 35.0;
    final culture = zone != null ? _culture(zone) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zone == null
                ? 'Parcelle introuvable'
                : (culture != null ? '${zone.nom} - $culture' : zone.nom),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          if (zone != null)
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
                children: [
                  if (culture != null) TextSpan(text: 'Culture : $culture | '),
                  TextSpan(
                    text: aIrriguer ? 'À irriguer' : 'Humidité OK',
                    style: TextStyle(
                      color: aIrriguer
                          ? const Color(0xFFC62828)
                          : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Aucune zone ne correspond à "$_code".',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _reinitialiser,
                child: const Text('Rescanner',
                    style: TextStyle(color: Color(0xFF3E7B3A))),
              ),
              if (zone != null) ...[
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vertClair,
                    foregroundColor: const Color(0xFF1F3A1F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => _ouvrirDetails(zone),
                  label: const Text('Ouvrir les détails'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinsPainter extends CustomPainter {
  final Color color;
  _CoinsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const l = 36.0;
    const r = 14.0;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0)
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l)
      ..moveTo(w, h - l)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(w - l, h)
      ..moveTo(l, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, h - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CoinsPainter old) => old.color != color;
}