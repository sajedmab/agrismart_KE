
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:agrismart/config.dart';

import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';

import 'package:agrismart/screens/auth_gate.dart';

import 'package:agrismart/services/auth_service.dart';
import 'package:agrismart/services/auth_locale_service.dart';
import 'package:agrismart/services/firebase_auth_service.dart';

import 'package:agrismart/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AuthService authService;

  if (utiliserFirebase) {
    await Firebase.initializeApp();
    authService = FirebaseAuthService();
  } else {
    authService = AuthLocaleService();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ZonesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MeteoProvider()..charger(),
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
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
