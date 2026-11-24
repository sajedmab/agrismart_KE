import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/screens/inscription_page.dart';

// Couleurs AgriSmart
const Color backgroundGreen = Color(0xFFE1EBDD);
const Color cardGreen = Color(0xFFF3F8EF);
const Color primaryGreen = Color(0xFF91E59A);
const Color darkGreen = Color(0xFF365B36);
const Color borderGreen = Color(0xFFB5C8AE);

// Validation email
String? validerEmail(String? valeur) {
  final v = (valeur ?? '').trim();

  if (v.isEmpty) return "L'email est obligatoire";

  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  if (!ok) return 'Email invalide';

  return null;
}

// Validation mot de passe
String? validerMotDePasse(String? valeur) {
  if (valeur == null || valeur.isEmpty) {
    return 'Le mot de passe est obligatoire';
  }

  if (valeur.length < 6) {
    return '6 caractères minimum';
  }

  return null;
}

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();

  bool _masquer = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  // Connexion Firebase
  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<AuthProvider>().connexion(
      _emailCtrl.text.trim(),
      _mdpCtrl.text,
    );
  }

  // Mot de passe oublié
  Future<void> _motDePasseOublie() async {
    final email = _emailCtrl.text.trim();

    if (validerEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saisissez d'abord votre email valide")),
      );
      return;
    }

    final ok = await context.read<AuthProvider>().reinitialiserMotDePasse(
      email,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Email de réinitialisation envoyé'
              : context.read<AuthProvider>().erreur ??
                    'Une erreur est survenue',
        ),
      ),
    );
  }

  // Face Authentication : en attente d'implémentation
  void _connexionFaciale() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Authentification faciale pas encore disponible'),
      ),
    );
  }

  // Champ personnalisé
  InputDecoration _decorationChamp({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF667563), fontSize: 18),
      filled: true,
      fillColor: cardGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: borderGreen, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: borderGreen, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: darkGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: backgroundGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Logo AgriSmart
                    const Icon(
                      Icons.spa_outlined,
                      size: 105,
                      color: Color(0xFF819C70),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'AgriSmart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 43,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF172719),
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 65),

                    // Card des champs
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decorationChamp(label: 'Email'),
                            validator: validerEmail,
                          ),

                          const SizedBox(height: 27),

                          // Mot de passe
                          TextFormField(
                            controller: _mdpCtrl,
                            obscureText: _masquer,
                            decoration: _decorationChamp(
                              label: 'Mot de passe',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _masquer = !_masquer;
                                  });
                                },
                                icon: Icon(
                                  _masquer
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: darkGreen,
                                  size: 25,
                                ),
                              ),
                            ),
                            validator: validerMotDePasse,
                          ),
                        ],
                      ),
                    ),

                    // Mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.occupe ? null : _motDePasseOublie,
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: Color(0xFF263B28),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Erreur Firebase
                    if (auth.erreur != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          auth.erreur!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Bouton connexion
                    SizedBox(
                      height: 65,
                      child: FilledButton(
                        onPressed: auth.occupe ? null : _connecter,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: const Color(0xFF172719),
                          disabledBackgroundColor: primaryGreen.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 5,
                        ),
                        child: auth.occupe
                            ? const SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: darkGreen,
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Face Authentication
                    SizedBox(
                      height: 62,
                      child: OutlinedButton.icon(
                        onPressed: auth.occupe ? null : _connexionFaciale,
                        icon: const Icon(
                          Icons.face_retouching_natural,
                          size: 28,
                        ),
                        label: const Text(
                          'Connexion faciale (ML Kit)',
                          style: TextStyle(fontSize: 17),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF263B28),
                          side: const BorderSide(color: borderGreen, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 65),

                    // Inscription
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            "Pas encore de compte ? ",
                            style: TextStyle(
                              color: Color(0xFF263B28),
                              fontSize: 17,
                            ),
                          ),
                          GestureDetector(
                            onTap: auth.occupe
                                ? null
                                : () {
                                    context
                                        .read<AuthProvider>()
                                        .effacerErreur();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InscriptionPage(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(
                                color: darkGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
