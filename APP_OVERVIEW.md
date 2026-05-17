# Priclo — Vue d'ensemble complète

## Contexte & Mission

**Priclo** (anciennement PrixKlo) est une app citoyenne de surveillance des prix en Côte d'Ivoire, centrée sur Abidjan.

---

## Le problème

### Situation réelle
L'État ivoirien publie périodiquement des **bulletins officiels de prix plafonds** pour les produits de première nécessité : riz, huile, lait concentré, farine, sucre, etc. Ces bulletins existent légalement — ils ont force de loi — mais leur application est quasi nulle sur le terrain.

### Pourquoi ça ne marche pas sans app
| Obstacle | Conséquence pour le citoyen |
|----------|-----------------------------|
| Le bulletin est publié en PDF, sur des sites officiels peu connus | Personne ne le lit |
| Aucun outil pour vérifier en temps réel au moment de l'achat | Le client paie sans savoir s'il est arnaqué |
| Signaler un abus = aller dans un bureau administratif | Personne ne le fait |
| Les commerçants savent que rien ne sera vérifié | Ils pratiquent ce qu'ils veulent |
| Les victimes sont isolées | Impossible de savoir si le problème est local ou généralisé |

### Impact concret
Un ménage moyen à Abidjan peut payer **15 à 40% de trop** sur des produits du quotidien sans le savoir. Multiplié par plusieurs achats par semaine, sur des millions de ménages, l'impact économique est massif et touche en priorité les ménages les plus modestes qui n'ont pas d'alternative.

---

## Comment Priclo résout ce problème

### 1. Rendre le plafond officiel accessible en 3 secondes
**Problème :** Le bulletin de prix existe mais personne ne le consulte.

**Solution :** Priclo synchronise le bulletin actif depuis le backend (`GET /bulletins/active` + `GET /official-prices/active`) et le met en cache local. Résultat : dès qu'un utilisateur sélectionne un produit et son conditionnement dans l'app, **le prix plafond officiel s'affiche instantanément**, sans GPS, sans connexion si le cache est chaud. C'est disponible en 2 taps depuis l'accueil.

### 2. Vérification immédiate avant l'achat
**Problème :** Le citoyen est devant le rayon, il n'a pas le temps de chercher.

**Solution :** L'écran PriceCheck permet de saisir le prix vu en boutique et obtient **instantanément** un verdict : "✅ Prix conforme" ou "🚨 +X% au-dessus du plafond — Abus probable". La comparaison est locale, sans appel réseau. L'utilisateur sait en 10 secondes s'il se fait avoir.

### 3. Signalement en 30 secondes
**Problème :** Signaler un abus est trop compliqué, trop lent, sans retour visible.

**Solution :** Wizard 3 étapes conçu pour la vitesse :
- **Étape 1** : sélection produit + conditionnement (1 tap + 1 chip)
- **Étape 2** : saisie prix (clavier numérique, 1 champ)
- **Étape 3** : GPS capturé silencieusement en arrière-plan depuis l'étape 1, photo et nom d'enseigne optionnels — le bouton "Envoyer" est disponible même sans GPS

Le GPS démarre dès la sélection du produit pour être prêt à l'étape 3 sans bloquer l'utilisateur. Si GPS non disponible : le signalement part quand même.

### 4. Intelligence communautaire géolocalisée
**Problème :** Un citoyen seul ne sait pas si son problème est isolé ou systémique.

**Solution :** Dès qu'un packaging est sélectionné et que le GPS est disponible, Priclo interroge `GET /prices/summary` dans un rayon de 5 km. L'utilisateur voit :
- Le prix moyen **observé par ses voisins**
- La répartition ABUS / CONFORME / LIMITE
- Le graphique des prix sur 30 jours (tendance)

Si d'autres ont déjà signalé → le report devient une **CONFIRMATION** (+3 pts bonus). Si premier signaleur → **SIGNALEMENT** neuf. Le type est déterminé automatiquement.

### 5. Carte des abus pour éviter les marchands abusifs
**Problème :** Un citoyen informé veut savoir où aller (ou ne pas aller) acheter.

**Solution :** Carte OpenStreetMap avec tous les signalements géolocalisés, colorés par statut. Toggle "Abus uniquement" pour ne voir que les points chauds. Tap sur un marqueur → détail complet + bouton "Signaler ce produit ici" qui pré-remplit le wizard.

### 6. Fonctionne hors-ligne
**Problème :** Marchés, quartiers populaires — connexion instable ou absente.

**Solution :** Si l'utilisateur est hors-ligne au moment de l'envoi, le signalement est sérialisé en JSON et mis en file d'attente dans SharedPreferences. Il sera envoyé automatiquement dès la reconnexion (flush au démarrage + après chaque submit réussi). Badge visible sur l'onglet Signaler et dans le profil.

### 7. Gamification pour créer l'habitude
**Problème :** Sans motivation, les gens signalent une fois et oublient.

**Solution :** Chaque signalement rapporte des points (2 à 10 selon le statut), les confirmations donnent +3 pts bonus, des badges sont débloqués, un leaderboard classe les contributeurs par semaine/mois/global. L'impact personnel est visible dans le profil ("📢 X signalements · ~Y personnes informées").

### 8. Alertes push sur les abus proches
**Problème :** Le citoyen ne consulte pas l'app tous les jours.

**Solution :** Firebase Messaging (FCM) intégré pour recevoir des notifications push :
- `ABUS_NEARBY` → alerte si un abus est signalé près de l'utilisateur → tap ouvre la carte
- `REPORT_CONFIRMED` → notification si un autre utilisateur confirme votre signalement → tap ouvre l'historique

---

## La solution Priclo en une phrase

Transformer chaque citoyen en lanceur d'alerte de prix, en rendant le plafond officiel consultable en 2 taps et le signalement envoyable en 30 secondes, même sans connexion.

---

## Architecture technique

| Couche | Technologie |
|--------|------------|
| Framework | Flutter 3.x (SDK ^3.10.4) |
| State management | GetX 4.7.2 |
| Navigation | GetX routing (Cupertino transitions) |
| Backend | REST API — `https://prixklobackend.vercel.app/api` |
| Carte | flutter_map + OpenStreetMap |
| Stockage local | SharedPreferences (token, onboarding, offline queue, cache prix) |
| Firebase | Crashlytics + Analytics + Messaging (FCM) |
| Font | DM Sans via google_fonts |
| Thème | Material 3, couleur primaire `#F7374F` (rouge-orange) |

Pattern module : **Binding → Controller → View** (strict GetX)

---

## Flux de navigation

```
Démarrage
    │
    ▼
[Splash] — vérif token JWT
    ├── pas de token + onboarding non fait → [Onboarding] → [Login]
    ├── pas de token + onboarding fait    → [Login]
    └── token valide (getMe OK)           → [MainNav]
              token invalide (erreur réseau) → [MainNav] (optimiste)

[MainNav] — IndexedStack 4 onglets
    ├── 🏠 Accueil
    ├── 🗺️ Carte
    ├── ➕ Signaler
    └── 👤 Profil

Depuis MainNav :
    ├── [Notifications] ← icône cloche en AppBar Accueil
    ├── [PriceCheck]    ← barre de recherche Accueil
    ├── [History]       ← Profil → "Mes signalements"
    └── [Leaderboard]   ← Profil → "Classement"
```

---

## Écrans & UX

### 1. Splash `(/)`
- Logo centré, fond blanc
- `SplashController.onReady()` lance `GET /auth/me`
  - OK → hydrate `AuthController.user` → `/main`
  - 401 → clear token → onboarding ou login
  - Erreur réseau → `/main` (mode optimiste, l'overlay offline prend le relais)

---

### 2. Onboarding `(/onboarding)` — première ouverture uniquement
3 slides en `PageView` horizontal :

| # | Emoji | Titre | Message |
|---|-------|-------|---------|
| 1 | 🔍 | Vérifiez avant d'acheter | Scanner + comparer avec le plafond officiel |
| 2 | 🚨 | Signalez les abus en 30 secondes | Entrer prix, confirmer position, envoyer |
| 3 | 🏆 | Ensemble, on change les prix | Points, badges, héros de quartier |

- Bouton "Passer" en haut à droite (skip direct)
- Dots animés en bas (dot actif = 24px, inactif = 8px)
- Bouton "Suivant" → "Commencer" sur la dernière slide
- `finish()` → marque `onboarding_done = true` → `/login`

---

### 3. Login `(/login)` & Register `(/register)`
**Login :**
- Champ email + mot de passe (toggle visibilité)
- Bouton "Se connecter" → `POST /auth/login` → token JWT stocké → `/main`
- Lien "Créer un compte" → `/register`
- Erreur affichée en snackbar

**Register :**
- Champs : nom, email, mot de passe
- `POST /auth/register` → 201 → token + `/main`
- Erreur : snackbar avec message API

---

### 4. Accueil `(/main, tab 0)`

**AppBar flottante (floating SliverAppBar) :**
- Gauche : "Bonjour, [Prénom] 👋" + "Abidjan, Côte d'Ivoire"
- Droite : icône cloche avec badge `unreadCount` → `/notifications`

**Barre de recherche (non-éditable, tap = navigation) :**
- Container stylisé avec bordure orange, bouton "Vérifier" → `/price-check`

**Carte gamification (gradient orange → orange foncé) :**
- Points animés (`AnimatedCounter`)
- Niveau actuel
- Dernier badge débloqué (emoji + nom) ou étoile ⭐ par défaut
- Données depuis `GET /gamification/me`

**Section "Abus récents près de toi" :**
- Liste des 5 derniers abus (tous statuts `ABUS` depuis `GET /reports/map?onlyAbus=true`)
- Chaque carte : bordure gauche rouge, icône ⚠️, produit + conditionnement, prix observé vs max officiel, date relative
- Tap → navigue vers l'onglet Carte

**Pull-to-refresh** recharge toutes les données en parallèle.

**Cache bulletins + prix officiels :**
- `GET /bulletins/active` → `GET /official-prices/active`
- Si bulletin ID inchangé, charge depuis SharedPreferences
- Sinon, fetch réseau + mise à jour cache

---

### 5. Carte `(/main, tab 1)`

Carte OpenStreetMap via `flutter_map`, centrée sur Abidjan (5.35°N, 4.00°W), zoom initial 13.

**Marqueurs colorés :**

| Status | Couleur | Icône |
|--------|---------|-------|
| ABUS | Rouge `#DC2626` | ⚠️ |
| CONFORME | Vert `#16A34A` | ✓ |
| LIMITE | Orange | ℹ️ |
| UNKNOWN | Gris | ? |

Marqueurs sans GPS (`lat/lng == null`) filtrés côté client avant parsing.

**Contrôles :**
- Toggle "Abus uniquement" (top) → `ever(onlyAbus, fetchMarkers)` → recharge
- Boutons zoom +/- (bas droite) → `mapCtrl.move(center, zoom±1)`
- Spinner pendant le chargement

**Bottom sheet sur tap marqueur (`MapMarkerSheet`) :**
- Badge statut (couleur)
- Produit — Conditionnement
- Nom de l'enseigne (si renseigné)
- Prix observé vs Prix officiel max
- Date complète
- Bouton "Signaler ce produit ici" → `ReportController.preSelect(product, packaging)` + onglet Signaler

---

### 6. Wizard de signalement `(/main, tab 2)`

**Structure : `IndexedStack` 3 étapes + écran résultat**

AppBar : "Signaler — Étape X/3"
Barre de progression (cercles numérotés, ligne entre eux, check ✓ sur étapes passées)

#### Étape 1 — Produit `(Step1ProductView)`

- Champ recherche → filtre `filteredProducts` (nom ou catégorie)
- Liste scrollable de `ProductTile` (avatar initiale, nom, catégorie, check si sélectionné)
- Tap → `selectProduct(product)` (lance GPS en arrière-plan silencieusement) + `showModalBottomSheet`

**Bottom sheet packaging (`_PackagingSheet`) :**
1. **Chips conditionnement** (ex: "1kg", "500g", "2L") → `ChoiceChip`, sélection réactive
2. **Prix plafond officiel** — affiché immédiatement depuis le cache `HomeController.officialPrices` (pas besoin de GPS)
   - Source : `effectiveMaxPrice` = prix officiel en cache ou `priceSummary.officialMaxPrice` en fallback
3. **Résumé communautaire** (si GPS disponible) :
   - Localisation en cours → spinner
   - `count == 0` → "Soyez le premier !"
   - `count > 0` → badge "🚨 Abus fréquents" ou "✅ Prix conformes", prix moyen observé vs max officiel, nombre de signalements + rayon (km)
4. **Graphique 30 jours** (`fl_chart` LineChart) :
   - Axe X : dates semaine (jj/mm)
   - Courbe orange : prix moyen observé
   - Ligne pointillée rouge : prix plafond officiel
   - Visible uniquement si GPS + données disponibles
5. Bouton "Continuer" (actif seulement si packaging sélectionné)

**Logique `ever()` dans `ReportController` :**
- `ever(selectedPackaging, _)` → reset + fetch résumé + historique si GPS prêt
- `ever(hasLocation, _)` → fetch résumé + historique si packaging déjà sélectionné
- `ever(priceSummary, _)` → auto-détermine `reportType` : `CONFIRMATION` si `count > 0`, sinon `SIGNALEMENT`

#### Étape 2 — Prix `(Step2PriceView)`

- **Résumé produit sélectionné** (chip en haut, icône édition → retour étape 1)
- **Prix plafond officiel** (même affichage que step 1)
- **Champ prix** : clavier numérique, format entier FCFA, grande police
- **Bannière comparaison temps réel** (apparaît dès que `observedPrice > 0`) :
  - Abus → 🚨 "+X% au-dessus du plafond — Abus probable" (fond rouge)
  - Conforme → ✅ "Dans la limite du plafond — Prix conforme" (fond vert)
- **Carte "Prix dans ce quartier"** (`_PriceSummaryCard`) :
  - GPS en cours → spinner
  - Résumé : prix officiel max, prix moyen observé, chips ABUS/CONFORME/LIMITE
  - Lien "Voir la tendance" → bottom sheet avec graphique 30 jours pleine taille
- **Photo optionnelle** : boutons "Caméra" et "Galerie", préview 160px avec croix suppression
- Bouton "Suivant" (actif si `observedPrice > 0`)

#### Étape 3 — Envoi `(Step3SendView)`

- **Récapitulatif** (carte) : Produit, Conditionnement, Prix observé, Photo (✓ si ajoutée)
- **Type auto-déterminé** (non modifiable) :
  - CONFIRMATION → badge vert "+ 3 pts bonus"
  - SIGNALEMENT → badge orange "Nouveau signalement"
- **Nom de l'enseigne** (optionnel) : TextField libre
- **Localisation** (optionnel) :
  - Déjà obtenu → affiche coordonnées + bouton refresh
  - En cours → spinner "Récupération GPS…"
  - Non obtenu → bouton "Obtenir ma position"
  - Note : "Vous pouvez envoyer sans attendre"
- **Bouton d'envoi** : libellé adaptatif
  - Soumission → "Envoi en cours…" + spinner
  - Abus sans GPS → "Signaler cet abus (sans GPS)"
  - Conforme sans GPS → "Envoyer sans GPS"
  - Avec GPS → "Signaler cet abus" ou "Envoyer ✓"

**Logique de soumission :**
```
submitReport()
    ├── offline → enqueue PendingReport → snackbar → resetWizard()
    └── online
        ├── avec photo → POST /reports (multipart FormData)
        └── sans photo → POST /reports (JSON)
            ├── 201 → ReportResultSheet + refreshUserPoints() + flushOfflineQueue()
            └── erreur → snackbar
```

#### Écran résultat `(ReportResultSheet)`

Plein écran animé (ScaleTransition élastique) :

| Status | Emoji | Label | Points |
|--------|-------|-------|--------|
| ABUS | 🚨 | Abus détecté | +10 pts |
| LIMITE | ⚠️ | Prix à la limite | +7 pts |
| CONFORME | ✅ | Prix conforme | +5 pts |
| UNKNOWN | ❓ | Statut inconnu | +2 pts |
| (CONFIRMATION) | — | Confirmation enregistrée | +3 pts |

- Bandeau gradient orange "⭐ +X points gagnés !"
- Badge "+3 pts bonus" si CONFIRMATION
- Auto-dismiss après 4 secondes
- Actions : "Nouveau signalement" / "Retour à la vérification" / "Voir sur la carte" / "Fermer"

---

### 7. PriceCheck `(/price-check)`

Vérification standalone (sans intention de signaler, depuis la barre de recherche Accueil).

**Flux :**
1. Liste produits (même logique que Step 1 : recherche, tiles, bottom sheet packaging)
2. Affichage immédiat : prix plafond officiel (cache)
3. GPS déclenché en arrière-plan dès sélection du packaging
4. Quand GPS prêt : résumé communautaire (5 km) + graphique 30 jours
5. Champ "Prix vu en boutique" (optionnel) → comparaison temps réel
6. Bouton "Signaler ce prix" → `ReportController.preSelect()` :
   - Avec prix saisi → saute à l'étape 3 (GPS + envoi)
   - Sans prix → saute à l'étape 2 (saisie prix)

---

### 8. Profil `(/main, tab 3)`

**Section identité :**
- Avatar initiale (cercle orange, initiale en blanc)
- Nom + email

**Carte gamification (gradient orange) :**
- `AnimatedCounter` points
- Badge "Niveau X"
- Barre de progression `LinearProgressIndicator` (blanc)
- "X / Y pts pour le niveau suivant"
- Seuils : 0 / 50 / 150 / 350 / 700 / 1200 pts

**Mon impact :**
- 📢 N signalements (total depuis API pagination)
- 👥 ~N×3 personnes informées (approximation locale)
- ✅ N confirmations (page 1 seulement — approximation)

**Signalements en attente :**
- Visible seulement si `pendingCount > 0`
- Icône nuage + libellé + bouton "Envoyer" → `flushOfflineQueue()`

**Mes badges :** Grid 2 colonnes, emoji + nom

**Actions :**
- "Mes signalements" → `/history`
- "Classement" → `/leaderboard`
- Bouton logout (AppBar) → clear token → `/login`

---

### 9. Historique `(/history)`

- Liste paginée des signalements de l'utilisateur (`GET /reports/mine?page=N`)
- Infinite scroll : quand dernier item visible → `fetchReports()`
- Chaque item : bordure gauche colorée par statut, emoji statut, produit + conditionnement, prix observé vs max, date relative
- Pull-to-refresh (page 1)
- État vide : "Aucun signalement pour l'instant 📋"

---

### 10. Leaderboard `(/leaderboard)`

- `SegmentedButton` : Global / Semaine / Mois → `ever(period, fetchLeaderboard)`
- `GET /leaderboard?period=X`
- Liste : rang (🥇🥈🥉 puis chiffre), avatar initiale, nom, nombre signalements
- Ligne courante (utilisateur connecté) : fond orange clair, texte orange, "(moi)"

---

### 11. Notifications `(/notifications)`

- `GET /notifications` au `onInit`
- Badge `unreadCount` dans l'AppBar Accueil (via `Get.find<NotificationsController>()`)
- Bouton "Tout lire" (visible si `unreadCount > 0`) → `PATCH /notifications/read`
- Chaque notification : icône colorée par type, titre (gras si non lu), body, date relative, point bleu si non lu
- Fond légèrement bleu sur les non lus

**Types & routing sur tap :**
| Type | Icône | Action tap |
|------|-------|-----------|
| ABUS_NEARBY | ⚠️ rouge | Retourne à MainNav → onglet Carte |
| REPORT_CONFIRMED | ✓ vert | → `/history` |
| (autre) | 🔔 gris | Rien |

---

### 12. Overlay Offline (global)

`AnimatedSwitcher` dans `GetMaterialApp.builder` :
- `ConnectivityService.isOnline.value == false` → plein écran "Pas de connexion"
- Icône wifi_off dans un carré arrondi
- Bouton "Réessayer" avec spinner pendant la vérification
- Disparaît automatiquement quand connexion rétablie

---

## File d'attente hors-ligne

```
Offline → PendingReport {packagingId, observedPrice, lat?, lng?, shopName?, queuedAt}
       → encodé JSON → stocké dans SharedPreferences (clé: pending_reports)
       → pendingCount.obs mis à jour → badge sur l'onglet "Signaler"

Flush automatique :
  - ReportController.onInit()
  - Après chaque soumission réussie
  - Bouton "Envoyer" dans Profil

Flush : itère la liste, POST chaque item, retire les 201 uniquement
```

---

## Gamification — Système de points

| Action | Points |
|--------|--------|
| Nouveau signalement ABUS | +10 |
| Signalement LIMITE | +7 |
| Signalement CONFORME | +5 |
| Signalement UNKNOWN | +2 |
| Confirmation d'un prix existant | +3 |

Niveaux : 1→2 à 50pts, 2→3 à 150pts, 3→4 à 350pts, 4→5 à 700pts, 5→6 à 1200pts.

Points mis à jour localement sans re-fetch (`AuthController.updatePoints`), profil rechargé au prochain `fetchProfile`.

---

## Vérification — Ce que l'app fait vraiment

### ✅ Implémenté et fonctionnel

| Fonctionnalité | Détail |
|----------------|--------|
| Auth complète | Login, Register, auto-login au démarrage, logout, intercepteur 401 |
| Onboarding | 3 slides, skip, flag persistant |
| Home | Greeting, search shortcut, gamification card, 5 derniers abus |
| Carte | OpenStreetMap, marqueurs colorés, toggle abus, zoom ±1, bottom sheet marker |
| Report wizard | 3 étapes, prix plafond officiel immédiat (cache), résumé communautaire GPS, graphique 30j, photo camera/galerie, GPS optionnel, nom enseigne optionnel |
| Bannière comparaison temps réel | Abus/conforme calculé instantanément sur le champ prix |
| Type auto (SIGNALEMENT/CONFIRMATION) | Déterminé par `priceSummary.count > 0` |
| PriceCheck standalone | Recherche + vérification + pré-remplissage wizard |
| Résultat animé | ScaleTransition élastique, points, auto-dismiss 4s |
| Offline queue | Enqueue si hors-ligne, flush sur reconnexion |
| Badge pending | Onglet Signaler + section Profil réactifs |
| Profil | Points, niveau, barre progression, impact, badges, actions |
| Leaderboard | 3 périodes, highlight self |
| Historique | Pagination infinie, pull-to-refresh |
| Notifications | Liste, badge, mark-all-read, routing par type |
| Overlay offline | Global, AnimatedSwitcher, retry |
| Firebase | Crashlytics (fatal + non-fatal) + Analytics |
| Cache bulletin/prix | Bulletin ID → skip fetch réseau si inchangé |
| MapController conflict | Résolu par `hide MapController` + typedef |

---

### ❌ Fonctionnalités manquantes

| Manque | Impact |
|--------|--------|
| **FCM permission request absent** | Sur iOS = 0 notification push. Sur Android 13+ = pareil. `firebase_messaging` importé mais `FirebaseMessaging.instance.requestPermission()` jamais appelé. |
| **Pas de "Mot de passe oublié"** | Blocage utilisateur si oubli. Pas de lien sur l'écran login. |
| **Pas d'édition du profil** | Nom, email, mot de passe non modifiables depuis l'app. |
| **Pas de "Ma position" sur la carte** | Pas de bouton pour centrer la carte sur l'utilisateur. |
| **confirmationsCount approximatif** | Compte les CONFIRMATION sur la page 1 seulement, pas le total réel. |

---

### ⚠️ Points d'attention

| Point | Détail |
|-------|--------|
| `unreadCount` non-Rx | `NotificationsController.unreadCount` est un getter simple. L'`Obx` dans HomeView réagit quand `notifications` (RxList) change. Ça marche — mais un changement de `read` sur un item sans rebuild de la liste ne déclencherait pas de mise à jour. `markAllRead` remplace toute la liste → OK. |
| Marqueurs sans GPS filtrés client | `where(m['lat'] != null && m['lng'] != null)` avant parsing — correct. |
| Erreur réseau au splash = optimiste | Si `getMe` lève une exception (timeout, pas réseau), l'app va sur `/main`. L'overlay offline prendra le relais. Acceptable. |
| `peopleInformed = totalReports × 3` | Métrique cosmétique. Ne reflète pas une vraie portée. |
| Couleur primaire `#F7374F` vs CLAUDE.md `#F97316` | Le code source fait foi : `AppColors.primary = Color(0xFFF7374F)`. CLAUDE.md est obsolète sur ce point. |
