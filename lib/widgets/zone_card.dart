
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

  @override
  Widget build(BuildContext context) {
    final couleur =
    zone.humidite <= zone.seuil
        ? Colors.red
        : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.nom,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Culture : ${zone.culture}'),
                    const SizedBox(height: 6),
                    Text(
                      'Humidité : '
                          '${zone.humidite.toStringAsFixed(1)}% '
                          '| Seuil : '
                          '${zone.seuil.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zone.humidite <= zone.seuil
                          ? 'À irriguer'
                          : 'Humidité suffisante',
                      style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onAugmenter,
                    tooltip: 'Augmenter',
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: onDiminuer,
                    tooltip: 'Diminuer',
                    icon: const Icon(Icons.remove),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
