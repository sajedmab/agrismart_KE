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
  return n % 1 == 0 ? n.toStringAsFixed(0) : n.toString();
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

  final humidite =
      ancienne?.humidite ?? _lireNombre(_humiditeCtrl.text)!;

  final nouvelleZone = Zone(
   _nomCtrl.text.trim(),
   _cultureCtrl.text.trim(),
   humidite,
   _lireNombre(_seuilCtrl.text)!,
   vanneOuverte: ancienne?.vanneOuverte ?? false,
  );

  widget.onEnregistrer(nouvelleZone);
 }

 InputDecoration _decorationChamp({
  required String label,
  required String hint,
  required IconData icone,
  Color couleurIcone = const Color(0xFF3E7B3A),
  String? suffixText,
 }) {
  return InputDecoration(
   labelText: label,
   hintText: hint,
   suffixText: suffixText,
   labelStyle: const TextStyle(
    color: Color(0xFF3E4A40),
    fontSize: 14,
    fontWeight: FontWeight.w500,
   ),
   hintStyle: const TextStyle(
    color: Color(0xFF8A978C),
    fontSize: 13.5,
   ),
   prefixIcon: Icon(icone, color: couleurIcone, size: 21),
   filled: true,
   fillColor: const Color(0xFFF9FCF8),
   contentPadding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
   ),
   enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFC8D7C6), width: 1.2),
   ),
   focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFF56A832), width: 1.8),
   ),
   errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.3),
   ),
   focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.8),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  return Form(
   key: _formKey,
   child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
     Row(
      children: [
       Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
         color: const Color(0xFFE1ECE0),
         borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
         _modeEdition ? 'Édition de parcelle' : 'Paramètres de la parcelle',
         style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF285226),
         ),
        ),
       ),
      ],
     ),
     const SizedBox(height: 16),

     TextFormField(
      controller: _nomCtrl,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A221B)),
      decoration: _decorationChamp(
       label: 'Nom de la zone',
       hint: 'Ex : Parcelle Nord',
       icone: Icons.map_outlined,
      ),
      textInputAction: TextInputAction.next,
      validator: _validerNom,
     ),
     const SizedBox(height: 14),

     TextFormField(
      controller: _cultureCtrl,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A221B)),
      decoration: _decorationChamp(
       label: 'Culture',
       hint: 'Ex : Tomates, Oliviers...',
       icone: Icons.eco_outlined,
      ),
      textInputAction: TextInputAction.next,
      validator: _validerTexte,
     ),
     const SizedBox(height: 14),

     if (!_modeEdition) ...[
      TextFormField(
       controller: _humiditeCtrl,
       style: const TextStyle(fontSize: 15, color: Color(0xFF1A221B)),
       decoration: _decorationChamp(
        label: 'Humidité actuelle (%)',
        hint: 'Ex : 42',
        icone: Icons.water_drop_outlined,
        couleurIcone: const Color(0xFF3A94D6),
        suffixText: '%',
       ),
       keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
       ),
       textInputAction: TextInputAction.next,
       validator: _validerPourcentage,
      ),
      const SizedBox(height: 14),
     ],

     TextFormField(
      controller: _seuilCtrl,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A221B)),
      decoration: _decorationChamp(
       label: 'Seuil d\'irrigation (%)',
       hint: 'Ex : 35',
       icone: Icons.speed_outlined,
       couleurIcone: const Color(0xFFE88D2A),
       suffixText: '%',
      ),
      keyboardType: const TextInputType.numberWithOptions(
       decimal: true,
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _soumettre(),
      validator: _validerPourcentage,
     ),
     const SizedBox(height: 22),

     SizedBox(
      height: 50,
      child: ElevatedButton.icon(
       style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF56A832),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF56A832).withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(16),
        ),
       ),
       onPressed: _soumettre,
       icon: Icon(
        _modeEdition ? Icons.check_circle_outline : Icons.add_circle_outline,
        size: 20,
       ),
       label: Text(
        _modeEdition ? 'Enregistrer les modifications' : 'Ajouter la parcelle',
        style: const TextStyle(
         fontSize: 15.5,
         fontWeight: FontWeight.w600,
        ),
       ),
      ),
     ),
    ],
   ),
  );
 }
}