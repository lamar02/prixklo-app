# PrixKlo — Documentation Technique

> Application Flutter de surveillance citoyenne des prix en Côte d'Ivoire.
> Les citoyens signalent les prix abusifs, gagnent des points et consultent une carte interactive des abus.

---

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Stack technique](#2-stack-technique)
3. [Structure du projet](#3-structure-du-projet)
4. [Architecture GetX](#4-architecture-getx)
5. [Démarrage de l'application](#5-démarrage-de-lapplication)
6. [Navigation et routes](#6-navigation-et-routes)
7. [Services globaux](#7-services-globaux)
8. [Modules](#8-modules)
9. [Modèles de données](#9-modèles-de-données)
10. [API Backend](#10-api-backend)
11. [Fonctionnalités clés](#11-fonctionnalités-clés)
12. [Gestion hors-ligne](#12-gestion-hors-ligne)
13. [Gamification](#13-gamification)
14. [Flux utilisateur complet](#14-flux-utilisateur-complet)

---

## 1. Vue d'ensemble

PrixKlo permet à des citoyens abidjanais de :

- **Signaler** un prix observé en magasin (produit + conditionnement + prix + photo optionnelle + GPS optionnel)
- **Consulter une carte** des signalements autour d'eux (ABUS en rouge, CONFORME en vert)
- **Voir leur historique** de signalements
- **Gagner des points et badges** via un système de gamification
- **Comparer** leur classement dans un leaderboard communautaire

---

## 2. Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter 3.x (SDK `^3.10.4`) |
| State management | GetX `^4.7.2` |
| Navigation | GetX routes nommées |
| HTTP | GetConnect (inclus dans GetX) |
| Stockage local | SharedPreferences `^2.3.2` |
| Carte | flutter_map `^7.0.2` + OpenStreetMap |
| Coordonnées | latlong2 `^0.9.1` |
| GPS | geolocator `^13.0.2` |
| Photo | image_picker `^1.1.2` |
| Images réseau | cached_network_image `^3.4.1` |
| Fonts | google_fonts `^6.2.1` (DM Sans) |
| Backend | REST API — `https://prixklobackend.vercel.app/api` |

---

## 3. Structure du projet

```
lib/
├── main.dart                          # Point d'entrée, init StorageService + GetMaterialApp
└── app/
    ├── core/
    │   ├── app_binding.dart           # Binding global (ApiService + AuthController permanents)
    │   ├── theme/
    │   │   └── app_theme.dart         # AppColors + AppTheme.light (Material 3)
    │   └── utils/
    │       ├── connectivity_util.dart # Vérification de la connexion internet
    │       └── date_formatter.dart    # Formatage des dates en français
    ├── data/
    │   ├── models/
    │   │   ├── user_model.dart        # Utilisateur connecté
    │   │   ├── product_model.dart     # Produit + PackagingModel
    │   │   ├── report_model.dart      # Signalement soumis
    │   │   ├── map_marker_model.dart  # Marqueur carte
    │   │   ├── gamification_model.dart# Points, niveau, badges
    │   │   └── leaderboard_entry_model.dart
    │   └── providers/
    │       └── offline_queue_model.dart # Signalement en attente (hors-ligne)
    ├── routes/
    │   ├── app_routes.dart            # Constantes des routes ('/login', '/main', ...)
    │   └── app_pages.dart             # GetPage[] avec bindings associés
    ├── services/
    │   ├── api_service.dart           # GetConnect : toutes les requêtes HTTP
    │   └── storage_service.dart       # SharedPreferences : token, onboarding, queue
    └── modules/
        ├── splash/                    # Écran de démarrage + redirection
        ├── onboarding/                # 3 pages d'introduction (première ouverture)
        ├── auth/                      # Login + Register
        ├── main_nav/                  # Scaffold avec BottomNavigationBar (4 onglets)
        ├── home/                      # Accueil : gamification + abus récents
        ├── map/                       # Carte interactive flutter_map
        ├── report/                    # Wizard de signalement en 3 étapes
        ├── profile/                   # Profil, badges, progression de niveau
        ├── history/                   # Historique paginé des signalements
        └── leaderboard/               # Classement (global / semaine / mois)
```

---

## 4. Architecture GetX

Chaque module suit le pattern **Binding / Controller / View** :

```
modules/<nom>/
├── bindings/<Nom>Binding.dart   → déclare les dépendances (Get.lazyPut / Get.put)
├── controllers/<Nom>Controller.dart → logique métier, état réactif (RxList, RxBool...)
└── views/<Nom>View.dart         → UI pure, GetView<Controller> donne accès à controller
```

### Règles

| Concept | Implémentation |
|---|---|
| État réactif | `final field = value.obs;` — mise à jour via `field.value = ...` |
| UI réactive | Wrap dans `Obx(() => ...)` |
| Injecter | `Get.lazyPut<T>(() => T())` (lazy) ou `Get.put<T>(T(), permanent: true)` |
| Récupérer | `Get.find<T>()` |
| Navigation | `Get.offAllNamed(AppRoutes.x)` / `Get.toNamed(AppRoutes.x)` |
| Réactions | `ever(observable, callback)` — déclenché à chaque changement |

### Controllers permanents

Deux controllers vivent pendant toute la durée de l'app (injectés dans `AppBinding`) :

- **`ApiService`** — singleton HTTP, ne doit jamais être recréé
- **`AuthController`** — maintient l'utilisateur connecté accessible partout

---

## 5. Démarrage de l'application

```
main()
 ├── WidgetsFlutterBinding.ensureInitialized()
 ├── StorageService().init()          ← SharedPreferences initialisé AVANT runApp
 └── runApp(PrixKloApp)
      └── GetMaterialApp
           ├── initialBinding: AppBinding()   ← ApiService + AuthController (permanents)
           ├── initialRoute: '/'              ← SplashView
           └── getPages: AppPages.pages
```

### SplashController — logique de redirection

```
onReady()
 └── _checkAndRedirect() après 1500ms
      ├── token == null → _redirectGuest()
      │    ├── onboardingDone == false → /onboarding
      │    └── onboardingDone == true  → /login
      ├── getMe() isOk → setUser() → /main
      ├── getMe() erreur HTTP → clearToken() → _redirectGuest()
      └── getMe() exception réseau → /main (token conservé, accès optimiste)
```

---

## 6. Navigation et routes

| Route | Écran | Binding |
|---|---|---|
| `/` | SplashView | SplashBinding |
| `/onboarding` | OnboardingView | OnboardingBinding |
| `/login` | LoginView | _(AuthController déjà permanent)_ |
| `/register` | RegisterView | _(idem)_ |
| `/main` | MainNavView | MainNavBinding |
| `/history` | HistoryView | HistoryBinding |
| `/leaderboard` | LeaderboardView | LeaderboardBinding |

### MainNavBinding — controllers chargés à l'entrée dans /main

```dart
Get.lazyPut<MainNavController>()
Get.lazyPut<HomeController>()
Get.lazyPut<MapController>()
Get.lazyPut<ReportController>()
Get.lazyPut<ProfileController>()
```

Les 4 onglets (`IndexedStack`) restent en mémoire une fois construits : `Home`, `Map`, `Report`, `Profile`.

---

## 7. Services globaux

### StorageService (`GetxService`)

Wrappeur autour de `SharedPreferences`. Initialisé de façon synchrone avant `runApp`.

| Méthode / Getter | Clé | Description |
|---|---|---|
| `token` / `saveToken` / `clearToken` | `auth_token` | JWT de session |
| `onboardingDone` / `markOnboardingDone` | `onboarding_done` | Premier lancement |
| `pendingReports` / `savePendingReports` | `pending_reports` | Queue hors-ligne |

### ApiService (`GetConnect`)

- **Base URL** : `https://prixklobackend.vercel.app/api`
- **Timeout** : 8 secondes
- **Intercepteur requête** : injecte `Authorization: Bearer <token>` si connecté
- **Intercepteur réponse** : si `401` → `clearToken()` + redirect `/login`

| Endpoint | Méthode | Description |
|---|---|---|
| `/auth/register` | POST | Inscription |
| `/auth/login` | POST | Connexion |
| `/auth/me` | GET | Vérifier le token au démarrage |
| `/products` | GET | Liste des produits + conditionnements |
| `/official-prices/active` | GET | Prix officiels (zone ABIDJAN_30KM) |
| `/reports` | POST | Créer un signalement (JSON ou multipart) |
| `/reports/mine` | GET | Historique paginé (`?page=N`) |
| `/reports/map` | GET | Marqueurs carte (`?onlyAbus=true/false`) |
| `/gamification/me` | GET | Points, niveau, badges |
| `/leaderboard` | GET | Classement (`?period=week/month`) |

---

## 8. Modules

### Splash

- Durée d'affichage : 1,5 s
- Vérifie la présence d'un token JWT et le valide via `/auth/me`
- Redirige selon l'état : onboarding / login / main

### Onboarding

- 3 pages défilantes (`PageView`)
- Bouton "Passer" disponible dès la première page
- À la fin : `markOnboardingDone()` → `/login`

### Auth (Login / Register)

- `StatefulWidget` : `TextEditingController` disposés correctement
- Champ mot de passe avec toggle visibilité (état local `RxBool`)
- En cas de succès : token sauvegardé + user stocké dans `AuthController` → `/main`

### MainNav

- `IndexedStack` à 4 onglets (Home, Map, Report, Profile)
- `MainNavController.selectedIndex` pilote l'onglet actif
- `goToReport()` : navigation programmatique vers l'onglet Signaler depuis Home

### Home

- Carte de gamification (points + niveau + badge le plus récent)
- Bouton CTA → onglet Signaler
- Liste des 5 derniers abus (pull-to-refresh)

### Map

- Carte OpenStreetMap via flutter_map
- Marqueurs : rouge (`ABUS`) / vert (`CONFORME`)
- Toggle "Abus uniquement" → refetch avec `onlyAbus=true`
- Tap sur marqueur → bottom sheet avec détails (prix observé, prix officiel max, date)
- Boutons **+** / **−** pour zoomer / dézoomer
- Les signalements **sans GPS** sont filtrés (non affichés)

### Report (Wizard 3 étapes)

**Étape 1 — Produit**
- Recherche filtrée en temps réel sur nom et catégorie
- Sélection du conditionnement (chips)

**Étape 2 — Prix + Photo**
- Champ numérique (FCFA)
- Photo optionnelle : caméra ou galerie (qualité 75%)
- Valeur pré-remplie si l'utilisateur revient en arrière

**Étape 3 — Localisation + Envoi**
- GPS optionnel via geolocator (demande de permission intégrée)
- Vérification de la connexion avant envoi
- Si hors-ligne : mise en file d'attente locale → envoi différé
- Résultat affiché en plein écran avec animation + points gagnés

### Profile

- Avatar initial (première lettre du nom)
- Barre de progression vers le niveau suivant
- Grille de badges obtenus
- Liens vers Historique et Classement
- Bouton de déconnexion

### History

- Liste paginée des signalements personnels (infinite scroll)
- Chargement de la page suivante automatique en fin de liste
- Pull-to-refresh

### Leaderboard

- Filtre par période : Global / Semaine / Mois
- L'utilisateur connecté est mis en évidence
- Top 3 avec médailles 🥇🥈🥉

---

## 9. Modèles de données

### UserModel
```
id, email, name, role, points, level, createdAt?
```

### ProductModel
```
id, name, category, packagings: List<PackagingModel>
PackagingModel: id, label
```

### ReportModel
```
id, status (ABUS|CONFORME|UNKNOWN), observedPrice, maxPrice?,
photoUrl?, createdAt, packagingLabel, productName
```

### MapMarkerModel
```
id, lat, lng, status, productName, packagingLabel,
observedPrice, maxPrice, createdAt
```

### GamificationModel
```
points, level, badges: List<BadgeModel>
BadgeModel: code, name, description, earnedAt, emoji (computed)
```

### PendingReport (queue hors-ligne)
```
packagingId, observedPrice, lat?, lng?, queuedAt
→ sérialisé en JSON string dans SharedPreferences
```

---

## 10. API Backend

### Authentification

L'API retourne un token JWT à la connexion / inscription :
```json
{ "token": "eyJ...", "user": { "id": "...", ... } }
```

Ce token est :
1. Sauvegardé dans `StorageService`
2. Injecté automatiquement dans chaque requête par l'intercepteur `ApiService`
3. Effacé si le serveur répond `401`

### Format signalement (multipart avec photo)

```
POST /reports (multipart/form-data)
  packagingId: string
  observedPrice: string (ex: "1500")
  lat?: string
  lng?: string
  photo?: File (JPEG, qualité 75%)
```

### Format signalement (JSON sans photo)

```
POST /reports (application/json)
  packagingId: string
  observedPrice: number
  lat?: number
  lng?: number
```

---

## 11. Fonctionnalités clés

### Vérification de connexion

`ConnectivityUtil.isOnline()` effectue un DNS lookup sur le domaine du backend avec un timeout de 5 s. Utilisé avant chaque soumission de signalement.

### Gestion des permissions GPS

```
isLocationServiceEnabled() → GPS activé ?
checkPermission() → déjà accordée ?
requestPermission() → demander si refusée
→ deniedForever → message avec lien vers les réglages
```

### Conflit de noms MapController

`flutter_map` et le module `map` définissent tous deux une classe `MapController`. Résolution :
- `map_view.dart` : `import 'flutter_map' hide MapController`
- `map_controller.dart` : `import 'flutter_map' as flutter_map` → accès via `flutter_map.MapController`
- `typedef AppMapController = app_map.MapController` pour la lisibilité dans la vue

---

## 12. Gestion hors-ligne

Quand `ConnectivityUtil.isOnline()` retourne `false` lors d'un signalement :

```
submitReport()
 └── online == false
      ├── PendingReport serialisé en JSON
      ├── Ajouté à StorageService.pendingReports (List<String>)
      ├── Snackbar "Sauvegardé, envoi différé"
      └── resetWizard()
```

À la prochaine ouverture de l'onglet Signaler (`ReportController.onInit`), et après chaque envoi réussi :

```
_flushOfflineQueue()
 ├── Pour chaque item en queue :
 │    ├── POST /reports
 │    ├── Succès (201) → retiré de la queue
 │    └── Échec → conservé pour le prochain essai
 └── savePendingReports(remaining)
```

---

## 13. Gamification

### Niveaux

| Niveau | Points requis |
|---|---|
| 1 | 0 |
| 2 | 50 |
| 3 | 150 |
| 4 | 350 |
| 5 | 700 |
| 6 | 1200 |

### Points par signalement

| Type | Points |
|---|---|
| CONFORME | +5 pts |
| ABUS | +10 pts |

### Badges

| Code | Emoji | Déclencheur |
|---|---|---|
| `PREMIER_SIGNALEMENT` | 🌟 | 1er signalement |
| `CHASSEUR_ABUS` | 🔍 | Plusieurs abus détectés |
| `REPORTER_REGULIER` | 📢 | Signalements réguliers |
| `HEROS_QUARTIER` | 🦸 | Fort engagement local |

Les points sont mis à jour localement (sans refetch) après chaque signalement réussi via `AuthController.updatePoints()`.

---

## 14. Flux utilisateur complet

```
Première ouverture
─────────────────
Splash (1.5s)
 └── pas de token → Onboarding (3 slides)
      └── "Commencer" → Login
           └── Connexion OK → Main Nav

Signalement
───────────
Onglet "Signaler"
 ├── Étape 1 : Choisir Produit → Sélectionner Conditionnement → Suivant
 ├── Étape 2 : Saisir Prix → (Photo optionnelle) → Suivant
 └── Étape 3 : (GPS optionnel) → Envoyer
      ├── Hors-ligne → Queue locale → Snackbar → reset
      └── En ligne   → POST /reports
           ├── 201 OK → Écran résultat animé (ABUS 🚨 / CONFORME ✅)
           │    ├── Points mis à jour (AuthController)
           │    ├── Flush de la queue hors-ligne
           │    └── "Nouveau signalement" → reset
           └── Erreur → Snackbar

Ouverture suivante (déjà connecté)
──────────────────────────────────
Splash (1.5s)
 ├── token présent → GET /auth/me
 │    ├── 200 OK → setUser() → Main Nav
 │    ├── 4xx   → clearToken() → Login
 │    └── réseau KO → Main Nav (accès optimiste)
 └── token absent → Login
```
