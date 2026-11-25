import 'package:flutter/material.dart';
import 'package:agrismart/models/zone.dart';

class ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback onAugmenter;
  final VoidCallback onDiminuer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.onAugmenter,
    required this.onDiminuer,
    this.onTap,
    this.onLongPress,
  });

  Color _couleurStatutHumidite(double hum) {
    if (hum < 30) {
      return const Color(0xFFD9534F); // Rouge (< 30)
    } else if (hum < 50) {
      return const Color(0xFFE88D2A); // Orange (30..50)
    } else {
      return const Color(0xFF2E7D32); // Vert (50+)
    }
  }

  Color _couleurClairStatut(double hum) {
    if (hum < 30) {
      return const Color(0xFFFFEFEA);
    } else if (hum < 50) {
      return const Color(0xFFFFF4E5);
    } else {
      return const Color(0xFFEAF8E6);
    }
  }

  Color _couleurBarre(double hum) {
    if (hum < 30) {
      return const Color(0xFFFF6B6B);
    } else if (hum < 50) {
      return const Color(0xFFFFB74D);
    } else {
      return const Color(0xFF9BE888);
    }
  }

  String _labelNiveau(double hum) {
    if (hum < 30) {
      return 'Critique (< 30%)';
    } else if (hum < 50) {
      return 'Modérée (30-50%)';
    } else {
      return 'Optimale (50%+)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool besoinEau = zone.humidite <= zone.seuil;
    final double ratio = (zone.humidite / 100.0).clamp(0.0, 1.0);

    final Color couleurPrincipale = _couleurStatutHumidite(zone.humidite);
    final Color couleurBadgeBg = _couleurClairStatut(zone.humidite);
    final Color couleurBarre = _couleurBarre(zone.humidite);

    final List<Color> gradientVert = besoinEau
        ? const [Color(0xFF296633), Color(0xFF3F8637)]
        : const [Color(0xFF337A35), Color(0xFF56A832)];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientVert,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: couleurBarre,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF235429).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              zone.nom,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              zone.culture,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Humidité : ${zone.humidite.toStringAsFixed(1)}%  |  Seuil : ${zone.seuil.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFEDF8EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor:
                          AlwaysStoppedAnimation<Color>(couleurBarre),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: couleurBadgeBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  zone.humidite < 30
                                      ? Icons.warning_amber_rounded
                                      : zone.humidite < 50
                                      ? Icons.water_drop_outlined
                                      : Icons.check_circle,
                                  size: 15,
                                  color: couleurPrincipale,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _labelNiveau(zone.humidite),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: couleurPrincipale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              besoinEau ? 'À irriguer' : 'Humidité suffisante',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BoutonHumidite(
                      icon: Icons.add,
                      tooltip: 'Augmenter',
                      onTap: onAugmenter,
                    ),
                    const SizedBox(height: 8),
                    _BoutonHumidite(
                      icon: Icons.remove,
                      tooltip: 'Diminuer',
                      onTap: onDiminuer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoutonHumidite extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BoutonHumidite({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}