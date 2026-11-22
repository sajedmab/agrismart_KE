
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/screens/app_shell.dart';
import 'package:agrismart/screens/connexion_page.dart';

// Choisit l'écran selon l'état d'authentification.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Attendre la première réponse du service
    if (!auth.initialise) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Aucun utilisateur connecté
    if (!auth.connecte) {
      return const ConnexionPage();
    }

    // 3. Utilisateur connecté
    return const AppShell();
  }
}
