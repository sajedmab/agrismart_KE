# AgriSmart_KE

Application Flutter de suivi d'exploitation agricole (Kébili) — mini-projet Atelier Framework Cross-Platform, ISET Kébili.

## Fonctionnalités
Authentification Firebase (AuthProvider + AuthGate : redirection automatique selon l'état de connexion)
Zones d'irrigation (CRUD), météo, statistiques
Diagnostic de plante par photo (ML Kit Image Labeling)
Scan terrain QR / code-barres :
chaque zone possède un QR code (écran détail > « QR code de la zone ») à fixer sur un piquet de la parcelle ;
le scan du QR identifie la parcelle, puis le scan du code-barres d'un produit (engrais, traitement) vérifie qu'il est prévu pour la culture, affiche dose et délai avant récolte, et enregistre l'intervention ;
journal d'interventions par zone + alerte « récolte déconseillée jusqu'au … » (traçabilité) ;
repli si la caméra est indisponible : lecture depuis une photo de la galerie ou saisie manuelle du code.
## Lancement
```bash
flutter pub get
flutter run 
```       


## Membres du groupe

Mouhib Boukadida

## Sécurité

Ne pas publier de secrets (clés d'API) : vérifier google-services.json / firebase_options.dart avant de rendre le dépôt public.
