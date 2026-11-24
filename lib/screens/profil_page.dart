import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/models/zone.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _notificationsActive = true;

  static const Color _vert = Color(0xFF218838);
  static const Color _fond = Color(0xFFF5F8F5);

  // Déconnexion avec confirmation
  Future<void> _deconnecter() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmer != true || !mounted) return;

    try {
      await context.read<AuthProvider>().deconnexion();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  // Informations du compte
  void _afficherInformations(String email, String uid) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            SelectableText(email),
            const SizedBox(height: 16),
            const Text(
              'Identifiant du compte',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            SelectableText(uid),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Données QR d'une parcelle
  String _donneesQR(Zone zone) {
    return jsonEncode({
      'nom': zone.nom,
      'culture': zone.culture,
      'humidite': zone.humidite,
      'seuil': zone.seuil,
      'vanneOuverte': zone.vanneOuverte,
      'besoinIrrigation': zone.besoinIrrigation,
    });
  }

  // Afficher les QR Codes de toutes les parcelles
  void _afficherQRCodes(List<Zone> zones) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: _vert, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'QR Codes des parcelles',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: zones.isEmpty
                    ? const Center(child: Text('Aucune parcelle disponible.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: zones.length,
                        itemBuilder: (context, index) {
                          final zone = zones[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 18),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Text(
                                    zone.nom,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Culture : ${zone.culture}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: QrImageView(
                                      data: _donneesQR(zone),
                                      version: QrVersions.auto,
                                      size: 190,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Humidité : ${zone.humidite.toStringAsFixed(1)} %',
                                  ),
                                  Text(
                                    zone.besoinIrrigation
                                        ? 'Besoin d’irrigation'
                                        : 'Sol correct',
                                    style: TextStyle(
                                      color: zone.besoinIrrigation
                                          ? Colors.orange.shade800
                                          : _vert,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Afficher un message
  void _afficherMessage(String titre, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitre(String titre) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String titre,
    String? sousTitre,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final couleur = iconColor ?? _vert;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.10),
          child: Icon(icon, color: couleur),
        ),
        title: Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: sousTitre == null ? null : Text(sousTitre),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = context.select<AuthProvider, dynamic>(
      (provider) => provider.utilisateur,
    );

    final zones = context.select<ZonesProvider, List<Zone>>(
      (provider) => provider.zones,
    );

    final email = utilisateur?.email ?? 'Email non disponible';
    final uid = utilisateur?.uid ?? 'ID non disponible';

    return Scaffold(
      backgroundColor: _fond,
      appBar: AppBar(
        backgroundColor: _fond,
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        actions: [
          IconButton(
            tooltip: 'QR Codes',
            onPressed: () => _afficherQRCodes(zones),
            icon: const Icon(Icons.qr_code_2, color: _vert, size: 27),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _deconnecter,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
        children: [
          // Carte du profil
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF218838), Color(0xFF146C35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _vert.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 43,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 48, color: _vert),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'AgriSmart User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Utilisateur AgriSmart',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.landscape_outlined,
                      color: Colors.white,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${zones.length} parcelle(s) suivie(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Informations du compte
          _sectionTitre('MON COMPTE'),

          _option(
            icon: Icons.person_outline,
            titre: 'Informations personnelles',
            sousTitre: 'Email et identifiant du compte',
            onTap: () => _afficherInformations(email, uid),
          ),

          // Paramètres
          _sectionTitre('PARAMÈTRES'),

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              secondary: CircleAvatar(
                backgroundColor: _vert.withValues(alpha: 0.10),
                child: const Icon(Icons.notifications_outlined, color: _vert),
              ),
              title: const Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _notificationsActive
                    ? 'Préférence activée'
                    : 'Préférence désactivée',
              ),
              value: _notificationsActive,
              activeThumbColor: _vert,
              onChanged: (value) {
                setState(() {
                  _notificationsActive = value;
                });
              },
            ),
          ),

          _option(
            icon: Icons.face_retouching_natural,
            titre: 'Face Authentication',
            sousTitre: 'Authentification faciale',
            onTap: () => _afficherMessage(
              'Face Authentication',
              'Cette fonctionnalité n’est pas encore activée.',
            ),
          ),

          // QR Codes des parcelles
          _sectionTitre('GESTION DES PARCELLES'),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _vert,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => _afficherQRCodes(zones),
              icon: const Icon(Icons.qr_code_2),
              label: const Text(
                'Générer les QR Codes des parcelles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),

          // Déconnexion
          _sectionTitre('SESSION'),

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0x1AFF0000),
                child: Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: _deconnecter,
            ),
          ),

          const SizedBox(height: 25),

          const Center(
            child: Text(
              'AgriSmart • Version 1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
