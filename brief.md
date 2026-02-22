BRIEF 2 — Mobile (Flutter Client)
1) Objectif
Construire une app Flutter simple et intuitive pour :
Consulter produits/prix
Signaler un prix en 30 secondes
Voir les abus sur une carte basique
Motiver l’usage via gamification (points, niveau, badges)
Fonctionner bien à Abidjan (connexion parfois instable)
2) Parcours utilisateur complet (simple + intuitif)
Parcours A — Onboarding (1 minute)
Splash → écran “Bienvenue sur PrixKlo”
3 écrans onboarding très courts :
“Vérifie les prix autour de toi”
“Signale en 30 secondes”
“Gagne des points en aidant ta communauté”
Choix : “Créer un compte” ou “Se connecter”
Permission localisation (optionnelle, expliquée simplement)
Si refus → l’app marche quand même (carte centrée par défaut Abidjan)
Parcours B — Home (2 onglets principaux)
Bottom nav très simple (4 tabs max) :
Accueil
Carte
Signaler
Profil
Astuce soutenance : 4 onglets = clair.
Parcours C — Signaler un prix (flow principal “30 secondes”)
Objectif : le flow doit être ultra simple, type “wizard” 3 étapes :
Étape 1 : Choisir produit
Search + liste catégories (grande conso)
L’utilisateur choisit “Produit”
Puis choisit “Conditionnement” (packaging_label)
Étape 2 : Entrer le prix
Champ prix (clavier numérique)
Bouton “Ajouter une photo (optionnel)”
Petit texte : “Ajoute une photo pour renforcer la fiabilité”
Étape 3 : Localisation & envoi
GPS auto (si autorisé)
Bouton “Envoyer”
Résultat instantané :
“✅ Conforme” ou “🚨 Abus détecté”
Récompense immédiate (gamification)
“+10 points” + confetti léger + badge si premier signalement
Parcours D — Carte (version basique)
Carte centrée sur utilisateur ou Abidjan par défaut
Marqueurs :
rouge = abus
vert = conforme
Switch : “Afficher seulement les abus”
Tap marker → bottom sheet :
produit + conditionnement
prix observé + prix officiel
date
photo (si existe)
Parcours E — Accueil (contenu simple mais motivant)
Carte mini (ou bloc “Abus récents”)
“Top abus autour de toi” (liste 5)
Bouton principal : “Signaler un prix”
Petit bloc gamification :
points, niveau, badge le plus récent
Parcours F — Profil (gamification)
Points + niveau (ex: Niveau 1 → 2)
Badges (3–6 max)
Historique “Mes signalements”
Leaderboard (option simple)
3) Gamification (simple, pas gadget)
Points
+10 points : signalement envoyé
+5 bonus : photo ajoutée
+10 bonus : si abus détecté
Niveaux (exemple)
Niveau 1 : 0–49 pts
Niveau 2 : 50–149 pts
Niveau 3 : 150–299 pts
(afficher une progress bar)
Badges (3 à 5)
“Premier signalement”
“Détecteur d’abus” (3 abus)
“Reporter régulier” (7 signalements)
“Héros du quartier” (10 signalements)
UX : feedback immédiat
mini animation + toast “+points”
pas trop d’effets, juste propre
4) Écrans à développer (MVP)
Splash + Onboarding
Login/Register
Home (tabs)
Screen Accueil
Screen Signaler (wizard 3 étapes)
Screen Carte
Screen Profil
Screen Historique signalements
(Option) Screen Leaderboard
5) API contract (données attendues)
Le client consomme :
/products (produits + packagings)
/bulletins/active
/official-prices/active
/reports/map
/reports (create)
/reports/mine
/gamification/me
/leaderboard
6) Offline & fiabilité (simple)
Si pas d’internet :
le signalement est sauvegardé localement (queue simple)
et envoyé plus tard quand réseau revient
(si tu n’as pas le temps : mets ça en “perspectives”, mais au moins gérer

Url Prod : prixklobackend.vercel.app