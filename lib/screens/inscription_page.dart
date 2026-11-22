
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/screens/connexion_page.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmationCtrl = TextEditingController();

  bool _masquer = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmationCtrl.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<AuthProvider>().inscription(
      _emailCtrl.text,
      _mdpCtrl.text,
    );

    // TODO 1 : revenir à l'application après inscription
    if (ok && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 64,
                    ),

                    const SizedBox(height: 24),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: validerEmail,
                    ),

                    const SizedBox(height: 16),

                    // Mot de passe
                    TextFormField(
                      controller: _mdpCtrl,
                      obscureText: _masquer,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _masquer
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _masquer = !_masquer;
                            });
                          },
                        ),
                      ),
                      validator: validerMotDePasse,
                    ),

                    const SizedBox(height: 16),

                    // Confirmation du mot de passe
                    TextFormField(
                      controller: _confirmationCtrl,
                      obscureText: _masquer,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),

                      // TODO 2 : vérifier que les deux mots de passe sont identiques
                      validator: (valeur) {
                        if (valeur != _mdpCtrl.text) {
                          return 'Les mots de passe sont différents';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Message d'erreur
                    if (auth.erreur != null)
                      Text(
                        auth.erreur!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // TODO 3 : bouton de création du compte
                    FilledButton(
                      onPressed: auth.occupe ? null : _inscrire,
                      child: auth.occupe
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Créer mon compte'),
                    ),
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
