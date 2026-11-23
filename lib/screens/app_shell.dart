import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/accueil_page.dart';
import 'package:agrismart/screens/notifications_page.dart';
import 'package:agrismart/screens/profil_page.dart';
import 'package:agrismart/screens/statistiques_page.dart';
import 'package:agrismart/screens/zones_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _onglet = 0;
  bool _voirNotifications = false;

  Future<void> _deconnecter() async {
    try {
      await context.read<AuthProvider>().deconnexion();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
        ),
      );
    }
  }

  void _allerVersOnglet(int index) {
    setState(() {
      _voirNotifications = false;
      _onglet = index;
    });
  }

  void _ouvrirNotifications() {
    setState(() {
      _voirNotifications = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aIrriguer = context.select<ZonesProvider, int>(
          (provider) => provider.nombreAIrriguer,
    );

    final int selectedNavIndex = _voirNotifications ? 0 : _onglet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSmart'),
        actions: [
          IconButton(
            tooltip: 'Notifications & Alertes',
            icon: Badge(
              label: Text('$aIrriguer'),
              isLabelVisible: aIrriguer > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: _ouvrirNotifications,
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: _deconnecter,
          ),
        ],
      ),
      body: _voirNotifications
          ? NotificationsPage(
        onAllerZones: () => _allerVersOnglet(1),
      )
          : IndexedStack(
        index: _onglet,
        children: [
          AccueilPage(
            onAllerZones: () => _allerVersOnglet(1),
            onAllerStatistiques: () => _allerVersOnglet(2),
            onAllerProfil: () => _allerVersOnglet(3),
            onOuvrirNotifications: _ouvrirNotifications,
          ),
          const ZonesPage(),
          const StatistiquesPage(),
          const ProfilPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedNavIndex,
        onDestinationSelected: _allerVersOnglet,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
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