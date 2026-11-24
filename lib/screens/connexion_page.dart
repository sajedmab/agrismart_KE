
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/screens/inscription_page.dart';

// Couleurs AgriSmart
const Color backgroundColor = Color(0xFFFAFCF5);
const Color primaryGreen = Color(0xFF3D7042);
const Color textColor = Color(0xFF414A40);
const Color borderColor = Color(0xFF858B80);

String? validerEmail(String? valeur) {
  final v = (valeur ?? '').trim();

  if (v.isEmpty) return "L'email est obligatoire";

  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
      .hasMatch(v);

  if (!ok) return 'Email invalide';

  return null;
}

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

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<AuthProvider>().connexion(
      _emailCtrl.text.trim(),
      _mdpCtrl.text,
    );
  }

  Future<void> _motDePasseOublie() async {
    final email = _emailCtrl.text.trim();

    if (validerEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saisissez d'abord votre email valide"),
        ),
      );
      return;
    }

    final ok = await context
        .read<AuthProvider>()
        .reinitialiserMotDePasse(email);

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

  InputDecoration _decorationChamp({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: textColor,
        fontSize: 19,
      ),
      prefixIcon: Icon(
        icon,
        color: textColor,
        size: 25,
      ),
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.18,
                      ),

                      // Logo tracteur
                      const Icon(
                        Icons.agriculture,
                        size: 58,
                        color: Color(0xFF20251F),
                      ),

                      const SizedBox(height: 12),

                      // Nom de l'application
                      const Text(
                        'AgriSmart',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF172119),
                          letterSpacing: -1.2,
                        ),
                      ),

                      const SizedBox(height: 27),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email
                            SizedBox(
                              height: 57,
                              child: TextFormField(
                                controller: _emailCtrl,
                                keyboardType:
                                TextInputType.emailAddress,
                                decoration: _decorationChamp(
                                  hint: 'Email',
                                  icon: Icons.mail_outline,
                                ),
                                validator: validerEmail,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Mot de passe
                            SizedBox(
                              height: 57,
                              child: TextFormField(
                                controller: _mdpCtrl,
                                obscureText: _masquer,
                                decoration: _decorationChamp(
                                  hint: 'Mot de passe',
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _masquer = !_masquer;
                                      });
                                    },
                                    icon: Icon(
                                      _masquer
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: textColor,
                                      size: 25,
                                    ),
                                  ),
                                ),
                                validator: validerMotDePasse,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Erreur
                      if (auth.erreur != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Text(
                            auth.erreur!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),

                      // Bouton connexion
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: FilledButton(
                          onPressed:
                          auth.occupe ? null : _connecter,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            primaryGreen.withValues(
                              alpha: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(40),
                            ),
                            elevation: 0,
                          ),
                          child: auth.occupe
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Mot de passe oublié
                      TextButton(
                        onPressed: auth.occupe
                            ? null
                            : _motDePasseOublie,
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Inscription
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            "Pas de compte ? ",
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 16,
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
                                  builder: (_) =>
                                  const InscriptionPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
