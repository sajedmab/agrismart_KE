
import 'package:flutter/material.dart';
import 'package:agrismart/models/zone.dart';

class ZoneForm extends StatefulWidget {
 final Zone? zone;
 final void Function(Zone) onEnregistrer;
 final List<String> nomsExistants;

 const ZoneForm({
  super.key,
  this.zone,
  required this.onEnregistrer,
  this.nomsExistants = const [],
 });

 @override
 State<ZoneForm> createState() => _ZoneFormState();
}

class _ZoneFormState extends State<ZoneForm> {
 final _formKey = GlobalKey<FormState>();
 final _nomCtrl = TextEditingController();
 final _cultureCtrl = TextEditingController();
 final _humiditeCtrl = TextEditingController();
 final _seuilCtrl = TextEditingController();

 bool get _modeEdition => widget.zone != null;

 @override
 void initState() {
  super.initState();

  final zone = widget.zone;
  if (zone != null) {
   _nomCtrl.text = zone.nom;
   _cultureCtrl.text = zone.culture;
   _seuilCtrl.text = _formater(zone.seuil);
  }
 }

 String _formater(double n) {
  return n % 1 == 0
      ? n.toStringAsFixed(0)
      : n.toString();
 }

 @override
 void dispose() {
  _nomCtrl.dispose();
  _cultureCtrl.dispose();
  _humiditeCtrl.dispose();
  _seuilCtrl.dispose();
  super.dispose();
 }

 double? _lireNombre(String? texte) {
  return double.tryParse(
   (texte ?? '').trim().replaceAll(',', '.'),
  );
 }

 String? _validerTexte(String? valeur) {
  if (valeur == null || valeur.trim().isEmpty) {
   return 'Ce champ est obligatoire';
  }
  if (valeur.trim().length < 2) {
   return 'Minimum 2 caractères';
  }
  return null;
 }

 String? _validerNom(String? valeur) {
  final erreur = _validerTexte(valeur);
  if (erreur != null) return erreur;

  final nom = valeur!.trim().toLowerCase();

  final existe = widget.nomsExistants.any(
       (n) => n.trim().toLowerCase() == nom,
  );

  if (existe) return 'Ce nom existe déjà';
  return null;
 }

 String? _validerPourcentage(String? valeur) {
  if (valeur == null || valeur.trim().isEmpty) {
   return 'Ce champ est obligatoire';
  }

  final nombre = _lireNombre(valeur);

  if (nombre == null) {
   return 'Entrez un nombre valide';
  }

  if (nombre < 0 || nombre > 100) {
   return 'Valeur entre 0 et 100';
  }

  return null;
 }

 void _soumettre() {
  if (!_formKey.currentState!.validate()) return;

  final ancienne = widget.zone;

  final humidite = ancienne?.humidite ??
      _lireNombre(_humiditeCtrl.text)!;

  final nouvelleZone = Zone(
   _nomCtrl.text.trim(),
   _cultureCtrl.text.trim(),
   humidite,
   _lireNombre(_seuilCtrl.text)!,
   vanneOuverte: ancienne?.vanneOuverte ?? false,
  );

  widget.onEnregistrer(nouvelleZone);
 }

 @override
 Widget build(BuildContext context) {
  return Padding(
   padding: const EdgeInsets.all(16),
   child: Form(
    key: _formKey,
    child: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.stretch,
     children: [
      Text(
       _modeEdition
           ? 'Modifier la zone'
           : 'Nouvelle zone',
       style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),

      TextFormField(
       controller: _nomCtrl,
       decoration: const InputDecoration(
        labelText: 'Nom de la zone',
        border: OutlineInputBorder(),
       ),
       textInputAction: TextInputAction.next,
       validator: _validerNom,
      ),
      const SizedBox(height: 12),

      TextFormField(
       controller: _cultureCtrl,
       decoration: const InputDecoration(
        labelText: 'Culture',
        border: OutlineInputBorder(),
       ),
       textInputAction: TextInputAction.next,
       validator: _validerTexte,
      ),
      const SizedBox(height: 12),

      if (!_modeEdition) ...[
       TextFormField(
        controller: _humiditeCtrl,
        decoration: const InputDecoration(
         labelText: 'Humidité (%)',
         border: OutlineInputBorder(),
        ),
        keyboardType:
        const TextInputType.numberWithOptions(
         decimal: true,
        ),
        validator: _validerPourcentage,
       ),
       const SizedBox(height: 12),
      ],

      TextFormField(
       controller: _seuilCtrl,
       decoration: const InputDecoration(
        labelText: 'Seuil (%)',
        border: OutlineInputBorder(),
       ),
       keyboardType:
       const TextInputType.numberWithOptions(
        decimal: true,
       ),
       validator: _validerPourcentage,
      ),
      const SizedBox(height: 16),

      FilledButton(
       onPressed: _soumettre,
       child: Text(
        _modeEdition ? 'Enregistrer' : 'Ajouter',
       ),
      ),
     ],
    ),
   ),
  );
 }
}
