
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Future<void> _deconnecter() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
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
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
        ),
      );
    }
  }

  void _afficherInformations(String email, String uid) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(email),
            const SizedBox(height: 16),
            const Text(
              'User ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(uid),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _afficherQR(String uid) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 110,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Code غير مفعّل حاليًا',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'معرّف حسابك:',
              style: TextStyle(color: Colors.grey),
            ),
            SelectableText(
              uid,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _afficherMessage(String titre, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitre(String titre) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 10,
        left: 4,
      ),
      child: Text(
        titre,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? Colors.green).withValues(
            alpha: 0.10,
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.green.shade700,
          ),
        ),
        title: Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: sousTitre == null ? null : Text(sousTitre),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = context.select<AuthProvider, dynamic>(
          (provider) => provider.utilisateur,
    );

    final nombreZones = context.select<ZonesProvider, int>(
          (provider) => provider.nombre,
    );

    final email = utilisateur?.email ?? 'Email non disponible';
    final uid = utilisateur?.uid ?? 'ID non disponible';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 8),

          // Profile header
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 43,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'AgriSmart User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$nombreZones zones suivies',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _sectionTitre('ACCOUNT'),

          _option(
            icon: Icons.person_outline,
            titre: 'Personal Information',
            sousTitre: 'Email et identifiant du compte',
            onTap: () => _afficherInformations(email, uid),
          ),

          _option(
            icon: Icons.qr_code_2,
            titre: 'QR Codes',
            sousTitre: 'Consulter votre identifiant',
            onTap: () => _afficherQR(uid),
          ),

          _sectionTitre('PREFERENCES'),

          _option(
            icon: Icons.settings_outlined,
            titre: 'Settings',
            sousTitre: 'Paramètres de l’application',
            onTap: () => _afficherMessage(
              'Settings',
              'Les paramètres personnalisés seront ajoutés '
                  'dans une prochaine mise à jour.',
            ),
          ),

          _option(
            icon: Icons.notifications_outlined,
            titre: 'Notifications',
            sousTitre: 'Alertes et notifications',
            onTap: () => _afficherMessage(
              'Notifications',
              'Vous pouvez consulter vos alertes depuis '
                  'l’icône de notification en haut de l’application.',
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

          _sectionTitre('SESSION'),

          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1AFF0000),
                child: Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.red,
              ),
              onTap: _deconnecter,
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'AgriSmart • Version 1.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
