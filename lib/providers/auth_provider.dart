
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:agrismart/models/utilisateur.dart';
import 'package:agrismart/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  late final StreamSubscription<Utilisateur?> _abonnement;

  Utilisateur? _utilisateur;

  bool _initialise = false;
  bool _occupe = false;
  String? _erreur;

  AuthProvider(this._service) {
    // TODO 1 : Ecouter le Stream
    _abonnement = _service.utilisateur.listen((u) {
      _utilisateur = u;
      _initialise = true;
      notifyListeners();
    });
  }

  // Getters
  Utilisateur? get utilisateur => _utilisateur;

  bool get initialise => _initialise;

  bool get occupe => _occupe;

  String? get erreur => _erreur;

  bool get connecte => _utilisateur != null;

  // Connexion
  Future<bool> connexion(String email, String motDePasse) {
    return _executer(
          () => _service.connexion(email, motDePasse),
    );
  }

  // Inscription
  Future<bool> inscription(String email, String motDePasse) {
    return _executer(
          () => _service.inscription(email, motDePasse),
    );
  }

  // Reinitialisation du mot de passe
  Future<bool> reinitialiserMotDePasse(String email) {
    return _executer(
          () => _service.reinitialiserMotDePasse(email),
    );
  }

  // Deconnexion
  Future<void> deconnexion() => _service.deconnexion();

  // Effacer les erreurs
  void effacerErreur() {
    if (_erreur == null) return;

    _erreur = null;
    notifyListeners();
  }

  // Execution des operations
  Future<bool> _executer(
      Future<void> Function() operation) async {

    // TODO 2
    _occupe = true;
    _erreur = null;
    notifyListeners();

    var succes = false;

    try {
      // TODO 3
      await operation();
      succes = true;

    } on AuthException catch (e) {
      // TODO 4
      _erreur = e.message;

    } catch (_) {
      _erreur = 'Une erreur est survenue';
    }

    _occupe = false;
    notifyListeners();

    return succes;
  }

  // Nettoyage
  @override
  void dispose() {
    _abonnement.cancel();
    super.dispose();
  }
}
