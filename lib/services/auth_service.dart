
import 'package:agrismart/models/utilisateur.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);
}

abstract class AuthService {
  Stream<Utilisateur?> get utilisateur;

  Future<void> connexion(
      String email, String motDePasse);

  Future<void> inscription(
      String email, String motDePasse);

  Future<void> reinitialiserMotDePasse(String email);

  Future<void> deconnexion();
}
