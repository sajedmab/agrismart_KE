import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/reglages_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';

import 'package:agrismart/screens/auth_gate.dart';

import 'package:agrismart/services/auth_service.dart';
import 'package:agrismart/services/firebase_auth_service.dart';
import 'package:agrismart/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initializeDateFormatting('fr_FR', null);

  final AuthService authService = FirebaseAuthService();

  // Ouverture unique du stockage local
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ReglagesProvider(prefs)),

        // ZonesProvider reçoit prefs ET auth
        ChangeNotifierProvider(
          create: (context) => ZonesProvider(prefs, context.read<AuthProvider>()),
        ),

        // MeteoProvider reçoit prefs
        ChangeNotifierProvider(
          create: (_) => MeteoProvider(prefs)..charger(),
        ),
      ],
      child: const AgriSmartApp(),
    ),
  );
}

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSmart',
      theme: AppTheme.clair(),
      darkTheme: AppTheme.sombre(),
      themeMode: context.watch<ReglagesProvider>().themeMode,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}