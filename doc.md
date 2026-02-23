# PrixKlo API — Documentation

> API de signalement et surveillance des prix pour la zone Abidjan (Côte d'Ivoire)
> Version : 1.0 — MVP
> Base URL : `http://localhost:3000` (dev) · `https://votre-domaine.vercel.app` (prod)

---

## Authentification

Toutes les routes protégées nécessitent un header :

```
Authorization: Bearer <token>
```

Le token JWT est obtenu via `/api/auth/register` ou `/api/auth/login`.
Durée de validité : **7 jours**.

---

## Codes d'erreur communs

| Code | Signification |
|------|---------------|
| `400` | Données invalides (Zod) |
| `401` | Non authentifié / token invalide |
| `403` | Accès refusé (rôle insuffisant) |
| `404` | Ressource introuvable |
| `409` | Conflit (ex: email déjà utilisé) |
| `429` | Trop de requêtes (rate limit) |

---

## Auth

### `POST /api/auth/register`

Crée un compte citoyen.

**Body**
```json
{
  "email": "user@example.ci",
  "password": "motdepasse123",
  "name": "Kouamé Konan"
}
```

**Réponse 201**
```json
{
  "token": "eyJ...",
  "user": { "id": "...", "email": "...", "name": "...", "role": "CITIZEN" }
}
```

---

### `POST /api/auth/login`

**Body**
```json
{ "email": "user@example.ci", "password": "motdepasse123" }
```

**Réponse 200**
```json
{
  "token": "eyJ...",
  "user": { "id": "...", "email": "...", "name": "...", "role": "CITIZEN", "points": 15, "level": 1 }
}
```

---

### `GET /api/auth/me`

> Auth requise

Retourne le profil de l'utilisateur connecté (sans le mot de passe).

**Réponse 200**
```json
{
  "user": { "id": "...", "email": "...", "name": "...", "role": "CITIZEN", "points": 15, "level": 1, "createdAt": "..." }
}
```

---

## Catalogue

### `GET /api/products`

Liste tous les produits avec leurs packagings.

**Réponse 200**
```json
{
  "products": [
    {
      "id": "...",
      "name": "Riz local",
      "category": "Céréales",
      "packagings": [
        { "id": "...", "label": "Sac 25kg" },
        { "id": "...", "label": "Sac 50kg" }
      ]
    }
  ]
}
```

---

### `GET /api/bulletins/active`

Retourne le bulletin officiel actuellement actif avec tous ses prix.

**Réponse 200**
```json
{
  "bulletin": {
    "id": "...",
    "title": "Bulletin Officiel Janvier 2025",
    "periodMonth": 1,
    "periodYear": 2025,
    "isActive": true,
    "prices": [...]
  }
}
```

**Réponse 404** si aucun bulletin actif.

---

### `GET /api/official-prices`

| Paramètre | Type | Description |
|-----------|------|-------------|
| `packagingId` | string | Filtre par packaging |
| `productId` | string | Filtre par produit |

**Réponse 200**
```json
{ "prices": [{ "id": "...", "maxPrice": 12500, "currency": "FCFA", "zone": "ABIDJAN_30KM", "bulletin": {...}, "packaging": {...} }] }
```

---

### `GET /api/official-prices/active`

Version simplifiée pour les applications mobiles — retourne uniquement les prix du bulletin actif.

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `zone` | string | `ABIDJAN_30KM` | Zone géographique |

**Réponse 200**
```json
{
  "prices": [
    {
      "packagingId": "...",
      "productName": "Riz local",
      "packagingLabel": "Sac 25kg",
      "maxPrice": 12500,
      "currency": "FCFA",
      "zone": "ABIDJAN_30KM"
    }
  ]
}
```

---

## Signalements

### `POST /api/reports`

> Auth requise · Rate limit : 10/min par IP

Crée un signalement. Le serveur calcule automatiquement le statut en comparant `observedPrice` au prix officiel actif.

**Body (JSON)**
```json
{
  "packagingId": "clxxx...",
  "observedPrice": 15000,
  "lat": 5.3599,
  "lng": -4.0083,
  "type": "SIGNALEMENT",
  "shopName": "Supermarché Hayat Cocody",
  "photoUrl": "https://..."
}
```

> `shopName` est **optionnel** — nom de l'enseigne ou du marché où le prix a été observé.
> `type` est optionnel — `"SIGNALEMENT"` (défaut) ou `"CONFIRMATION"` (pour confirmer un prix déjà signalé).

**Body (multipart/form-data)** — avec photo (Cloudinary requis)
```
packagingId=clxxx...
observedPrice=15000
lat=5.3599
lng=-4.0083
type=SIGNALEMENT
shopName=Supermarché Hayat Cocody
photo=<fichier image>
```

> **Photo optionnelle** : le champ `photo` n'est pas obligatoire. Sans Cloudinary configuré, envoyer simplement le body JSON sans photo — l'API fonctionne normalement et `photoUrl` sera `null`.

**Réponse 201**
```json
{
  "report": {
    "id": "...",
    "status": "ABUS",
    "type": "SIGNALEMENT",
    "observedPrice": 15000,
    "maxPrice": 12500,
    "lat": 5.3599,
    "lng": -4.0083,
    "shopName": "Supermarché Hayat Cocody",
    "photoUrl": null,
    "createdAt": "...",
    "packaging": { "label": "Sac 25kg", "product": { "name": "Riz local" } }
  }
}
```

**Règles de calcul du statut** (basé sur le prix officiel du bulletin actif)

| Condition | Statut | Points gagnés |
|-----------|--------|---------------|
| `observedPrice > maxPrice × 1.05` | `ABUS` | +10 pts |
| `maxPrice × 0.95 ≤ observedPrice ≤ maxPrice × 1.05` | `LIMITE` | +7 pts |
| `observedPrice < maxPrice × 0.95` | `CONFORME` | +5 pts |
| Aucun prix officiel trouvé | `UNKNOWN` | +2 pts |
| `type = "CONFIRMATION"` | — | +3 pts (indépendant du statut) |

---

### `GET /api/reports/mine`

> Auth requise

Retourne les signalements de l'utilisateur connecté.

| Paramètre | Type | Défaut |
|-----------|------|--------|
| `page` | number | `1` |

**Réponse 200**
```json
{
  "reports": [{ "id": "...", "status": "ABUS", "observedPrice": 15000, "maxPrice": 12500, "createdAt": "...", "packaging": {...} }]
}
```

---

### `GET /api/reports/map`

Retourne les markers pour la carte.

| Paramètre | Type | Description |
|-----------|------|-------------|
| `onlyAbus` | `true/false` | Filtrer uniquement les abus |

**Réponse 200**
```json
{
  "markers": [
    {
      "id": "...",
      "lat": 5.3599,
      "lng": -4.0083,
      "status": "ABUS",
      "productName": "Riz local",
      "packagingLabel": "Sac 25kg",
      "observedPrice": 15000,
      "maxPrice": 12500,
      "shopName": "Supermarché Hayat Cocody",
      "createdAt": "..."
    }
  ]
}
```

> `shopName` est `null` si l'auteur du signalement n'a pas renseigné l'enseigne.

---

## Prix observés

### `GET /api/prices/summary`

Résumé des prix observés récemment pour un packaging donné dans un rayon géographique. Point d'entrée principal du flux "vérifier ce prix" côté mobile.

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `packagingId` | string | — | **Requis** |
| `lat` | number | — | **Requis** — latitude de l'utilisateur |
| `lng` | number | — | **Requis** — longitude de l'utilisateur |
| `radius` | number | `5` | Rayon en km |

**Réponse 200**
```json
{
  "packaging": {
    "id": "...",
    "label": "Sac 25kg",
    "product": { "id": "...", "name": "Riz Papillon", "category": "Riz" }
  },
  "officialMaxPrice": 12500,
  "observed": {
    "count": 8,
    "avg": 13200,
    "min": 12000,
    "max": 14500,
    "statusBreakdown": { "CONFORME": 2, "LIMITE": 3, "ABUS": 3 }
  },
  "dominantStatus": "ABUS",
  "radiusKm": 5
}
```

> - `observed` est `{ count: 0, avg: null, min: null, max: null, statusBreakdown: {} }` si aucun signalement dans la zone.
> - `dominantStatus` est calculé sur la moyenne observée et peut être `null` si `officialMaxPrice` est indisponible.
> - Les données couvrent les 30 derniers jours.

---

### `GET /api/prices/history`

Historique hebdomadaire des prix observés pour un packaging dans un rayon (30 derniers jours). Utilisé pour afficher un graphique de tendance.

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `packagingId` | string | — | **Requis** |
| `lat` | number | — | **Requis** |
| `lng` | number | — | **Requis** |
| `radius` | number | `5` | Rayon en km |

**Réponse 200**
```json
{
  "packagingId": "...",
  "radiusKm": 5,
  "history": [
    { "weekStart": "2025-05-26", "avg": 12800, "count": 3 },
    { "weekStart": "2025-06-02", "avg": 13500, "count": 5 }
  ]
}
```

> `weekStart` est le lundi de chaque semaine ISO (format `YYYY-MM-DD`). Le tableau est trié chronologiquement. Peut être vide si aucun signalement.

---

## Notifications

> Auth requise sur toutes les routes

### `POST /api/notifications/token`

Enregistre ou met à jour le token FCM de l'appareil de l'utilisateur connecté.

**Body**
```json
{ "token": "fcm_device_token_ici", "platform": "android" }
```

> `platform` : `"android"` ou `"ios"`

**Réponse 200**
```json
{ "deviceToken": { "id": "...", "token": "...", "platform": "android", "userId": "..." } }
```

---

### `GET /api/notifications`

Retourne les 50 dernières notifications de l'utilisateur. Les non-lues apparaissent en premier.

**Réponse 200**
```json
{
  "notifications": [
    {
      "id": "...",
      "title": "Abus signalé près de vous",
      "body": "Un nouveau signalement d'abus de prix a été détecté dans votre quartier.",
      "type": "ABUS_NEARBY",
      "read": false,
      "data": { "reportId": "...", "lat": "5.36", "lng": "-4.00" },
      "createdAt": "..."
    }
  ]
}
```

**Types de notification**

| Type | Déclencheur |
|------|-------------|
| `ABUS_NEARBY` | Un abus signalé dans un rayon de 5 km |
| `REPORT_CONFIRMED` | 3, 5 ou 10 personnes ont signalé le même abus dans un rayon de 2 km |

---

### `PATCH /api/notifications/read`

Marque toutes les notifications non lues de l'utilisateur comme lues.

**Réponse 200**
```json
{ "updated": 3 }
```

---

## Gamification

### `GET /api/gamification/me`

> Auth requise

**Réponse 200**
```json
{
  "points": 20,
  "level": 1,
  "badges": [
    { "code": "PREMIER_SIGNALEMENT", "name": "Premier Signalement", "description": "...", "earnedAt": "..." },
    { "code": "CHASSEUR_ABUS", "name": "Chasseur d'Abus", "description": "...", "earnedAt": "..." }
  ]
}
```

**Système de niveaux**

| Niveau | Points requis |
|--------|--------------|
| 1 | 0+ |
| 2 | 50+ |
| 3 | 150+ |
| 4 | 350+ |
| 5 | 700+ |
| 6 | 1200+ |

---

### `GET /api/leaderboard`

| Paramètre | Type | Description |
|-----------|------|-------------|
| `period` | `week / month` | Période (optionnel — global si absent) |

**Réponse 200 (global)**
```json
{ "period": "all", "leaderboard": [{ "id": "...", "name": "...", "email": "...", "points": 20, "level": 1 }] }
```

**Réponse 200 (period=week)**
```json
{ "period": "week", "leaderboard": [{ "id": "...", "email": "...", "reportCount": 5 }] }
```

---

## Admin

> Toutes les routes Admin nécessitent `role=ADMIN`

---

### `POST /api/admin/bulletins`

Crée ou met à jour un bulletin. Si `isActive: true`, tous les autres bulletins sont automatiquement désactivés.

**Body**
```json
{
  "periodYear": 2025,
  "periodMonth": 3,
  "title": "Bulletin Mars 2025",
  "isActive": true,
  "sourcePdfUrl": "https://exemple.ci/bulletins/mars-2025.pdf"
}
```

**Réponse 201**
```json
{ "bulletin": { "id": "...", "title": "...", "isActive": true, ... } }
```

---

### `GET /api/admin/bulletins`

Liste tous les bulletins avec le nombre de prix associés.

**Réponse 200**
```json
{ "bulletins": [{ "id": "...", "title": "...", "isActive": true, "_count": { "prices": 10 } }] }
```

---

### `POST /api/admin/official-prices/import`

Import des prix officiels depuis un CSV. Deux modes supportés :

**Mode 1 — JSON body**
```json
{ "content": "period,zone,category,product_name,packaging_label,max_price\n2025-01,ABIDJAN_30KM,Céréales,Riz local,Sac 25kg,12500" }
```

**Mode 2 — Multipart form**
```
Content-Type: multipart/form-data
file: <fichier .csv>
```

**Format CSV obligatoire**

| Colonne | Format | Exemple |
|---------|--------|---------|
| `period` | `YYYY-MM` | `2025-01` |
| `zone` | `ABIDJAN_30KM` | `ABIDJAN_30KM` |
| `category` | string | `Céréales` |
| `product_name` | string | `Riz local` |
| `packaging_label` | string | `Sac 25kg` |
| `max_price` | integer (FCFA) | `12500` |

**Réponse 200**
```json
{
  "stats": {
    "processed": 4,
    "created": 3,
    "updated": 1,
    "errors": ["Ligne 5: Invalid enum value"]
  }
}
```

> **Comportement** : `product_name + packaging_label` identifient un Packaging (upsert). Si `period` est nouveau, un bulletin est créé (inactif). Pour l'activer, utiliser `POST /api/admin/bulletins`.

---

### `GET /api/admin/reports`

Liste tous les signalements (paginé, 50/page).

| Paramètre | Type | Description |
|-----------|------|-------------|
| `page` | number | Page (défaut: 1) |
| `status` | `CONFORME / LIMITE / ABUS / UNKNOWN` | Filtre optionnel |

**Réponse 200**
```json
{
  "reports": [{ "id": "...", "status": "ABUS", "user": { "email": "..." }, "packaging": {...}, "observedPrice": 15000 }],
  "total": 42,
  "page": 1,
  "limit": 50
}
```

---

### `PATCH /api/admin/reports/:id/flag`

Marque un signalement comme utile ou frauduleux. Un bonus de **+5 points** est attribué à l'auteur si `isUseful: true` (une seule fois par signalement).

**Body**
```json
{ "isUseful": true }
```
ou
```json
{ "isFraudulent": true }
```

**Réponse 200**
```json
{ "report": { "id": "...", "isUseful": true, "isFraudulent": null, ... } }
```

---

---

## Référence App Mobile

Flux complet de l'application citoyen, dans l'ordre chronologique d'utilisation.

---

### Étape 1 — Authentification

**Première ouverture (nouveau compte)**
```
POST /api/auth/register
Body: { "email": "user@example.ci", "password": "...", "name": "Konan Kouamé" }
→ 201 : { "token": "eyJ...", "user": { id, email, name, role, points, level } }
```

**Ouvertures suivantes (connexion)**
```
POST /api/auth/login
Body: { "email": "user@example.ci", "password": "..." }
→ 200 : { "token": "eyJ...", "user": { id, email, name, role, points, level } }
```

Stocker le `token` localement. L'envoyer sur chaque requête protégée :
```
Authorization: Bearer <token>
```

---

### Étape 2 — Initialisation au démarrage

Deux appels à effectuer **une seule fois au démarrage** (résultats à mettre en cache local) :

| Appel | Endpoint | Utilité |
|-------|----------|---------|
| Catalogue produits | `GET /api/products` | Alimente la recherche / sélection de produit |
| Prix plafond officiels | `GET /api/official-prices/active?zone=ABIDJAN_30KM` | Référence prix max par packaging |

> Recharger uniquement quand le bulletin change (vérifier via `GET /api/bulletins/active`).

**Enregistrer le token FCM** (après login, si notifications activées) :
```
POST /api/notifications/token   [Auth]
Body: { "token": "<fcm_token>", "platform": "android" }
```
```dart
// Flutter
String? token = await FirebaseMessaging.instance.getToken();

// → POST /api/notifications/token
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // → POST /api/notifications/token  (mise à jour)
});
```

---

### Étape 3 — Sélection du produit

L'utilisateur cherche un produit dans le catalogue chargé (Étape 2). Il obtient un `packagingId` pour les appels suivants.

---

### Étape 4 — Vérification des prix dans le quartier

Avant d'agir, l'app affiche les prix constatés par d'autres citoyens autour de l'utilisateur.

**Résumé local (écran principal prix)**
```
GET /api/prices/summary?packagingId=<id>&lat=5.3599&lng=-4.0083&radius=5
```
```json
{
  "packaging": { "label": "Sac 25kg", "product": { "name": "Riz Papillon" } },
  "officialMaxPrice": 12500,
  "observed": {
    "count": 8,
    "avg": 13200,
    "min": 12000,
    "max": 14500,
    "statusBreakdown": { "CONFORME": 2, "LIMITE": 3, "ABUS": 3 }
  },
  "dominantStatus": "ABUS",
  "radiusKm": 5
}
```

**Courbe de tendance (graphique historique — optionnel)**
```
GET /api/prices/history?packagingId=<id>&lat=5.3599&lng=-4.0083
```
```json
{
  "history": [
    { "weekStart": "2025-05-26", "avg": 12800, "count": 3 },
    { "weekStart": "2025-06-02", "avg": 13500, "count": 5 }
  ]
}
```

> `dominantStatus` est calculé sur la moyenne observée. Si `count = 0`, aucun signalement n'existe encore dans la zone — inviter l'utilisateur à être le premier à signaler.

---

### Étape 5 — Signalement ou confirmation

L'utilisateur a constaté un prix. Il choisit l'une des deux actions :

#### A. Nouveau signalement (`type: "SIGNALEMENT"` — défaut)

Utiliser quand l'utilisateur observe lui-même un prix pour la première fois dans ce commerce.

```
POST /api/reports   [Auth]   [Rate limit : 10/min]
```
```json
{
  "packagingId": "<id>",
  "observedPrice": 15000,
  "lat": 5.3599,
  "lng": -4.0083,
  "shopName": "Supermarché Hayat Cocody"
}
```

> `shopName` : optionnel mais recommandé (affiché sur la carte).
> `photoUrl` : URL Cloudinary (JSON) ou champ `photo` en multipart/form-data.

#### B. Confirmation d'un prix existant (`type: "CONFIRMATION"`)

Utiliser quand l'utilisateur constate le même prix qu'un signalement déjà visible — pour renforcer sa crédibilité.

```json
{
  "packagingId": "<id>",
  "observedPrice": 15000,
  "lat": 5.3599,
  "lng": -4.0083,
  "type": "CONFIRMATION"
}
```

**Réponse 201 (commune aux deux actions)**
```json
{
  "report": {
    "id": "...",
    "status": "ABUS",
    "type": "SIGNALEMENT",
    "observedPrice": 15000,
    "maxPrice": 12500,
    "lat": 5.3599,
    "lng": -4.0083,
    "shopName": "Supermarché Hayat Cocody",
    "photoUrl": null,
    "createdAt": "...",
    "packaging": { "label": "Sac 25kg", "product": { "name": "Riz Papillon" } }
  }
}
```

**Règles de statut et points attribués**

| Condition | Statut | Points |
|-----------|--------|--------|
| `observedPrice > maxPrice × 1.05` | `ABUS` | +10 pts |
| `maxPrice × 0.95 ≤ price ≤ maxPrice × 1.05` | `LIMITE` | +7 pts |
| `observedPrice < maxPrice × 0.95` | `CONFORME` | +5 pts |
| Pas de prix officiel disponible | `UNKNOWN` | +2 pts |
| `type = "CONFIRMATION"` (indépendant du statut) | — | +3 pts |

**Déclenchement automatique des notifications push (côté serveur)**
- Si `status = "ABUS"` → les utilisateurs dans un rayon de 5 km reçoivent une notification *"Abus signalé près de vous"*
- Quand 3, 5 ou 10 personnes ont signalé le même abus dans un rayon de 2 km → les auteurs reçoivent *"Votre signalement confirmé"*

---

### Étape 6 — Gamification

Après chaque signalement, l'app peut rafraîchir le profil de l'utilisateur pour afficher les points gagnés et les badges débloqués.

```
GET /api/gamification/me   [Auth]
```
```json
{
  "points": 47,
  "level": 1,
  "badges": [
    { "code": "PREMIER_SIGNALEMENT", "name": "Premier Signalement", "earnedAt": "..." },
    { "code": "CHASSEUR_ABUS", "name": "Chasseur d'Abus", "earnedAt": "..." }
  ]
}
```

**Système de niveaux**

| Niveau | Points requis |
|--------|--------------|
| 1 | 0+ |
| 2 | 50+ |
| 3 | 150+ |
| 4 | 350+ |
| 5 | 700+ |
| 6 | 1200+ |

**Badges disponibles**

| Code | Condition de déblocage |
|------|------------------------|
| `PREMIER_SIGNALEMENT` | Premier signalement de l'utilisateur |
| `CHASSEUR_ABUS` | Premier signalement avec statut ABUS |

**Classement**
```
GET /api/leaderboard               → classement global (points cumulés)
GET /api/leaderboard?period=week   → classement de la semaine (nb signalements)
GET /api/leaderboard?period=month  → classement du mois
```

---

### Étape 7 — Carte des signalements

Affiche tous les signalements géolocalisés (markers sur la carte).

```
GET /api/reports/map
GET /api/reports/map?onlyAbus=true   → filtre uniquement les abus
```
```json
{
  "markers": [
    {
      "id": "...",
      "lat": 5.3599,
      "lng": -4.0083,
      "status": "ABUS",
      "productName": "Riz Papillon",
      "packagingLabel": "Sac 25kg",
      "observedPrice": 15000,
      "maxPrice": 12500,
      "shopName": "Supermarché Hayat Cocody",
      "createdAt": "..."
    }
  ]
}
```

> Recommandation : charger uniquement les abus (`onlyAbus=true`) par défaut pour limiter le volume de données. Laisser l'utilisateur désactiver le filtre.

---

### Étape 8 — Historique personnel

```
GET /api/reports/mine?page=1   [Auth]
```

Retourne les signalements de l'utilisateur connecté, paginés (20/page), triés du plus récent au plus ancien.

---

### Étape 9 — Notifications

**Réception push (Flutter)**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Notification reçue en foreground
  // message.data contient : type, reportId, lat, lng
});
```

**Récupérer les notifications en-app**
```
GET /api/notifications   [Auth]
```
```json
{
  "notifications": [
    {
      "id": "...",
      "title": "Abus signalé près de vous",
      "body": "Un nouveau signalement d'abus a été détecté dans votre quartier.",
      "type": "ABUS_NEARBY",
      "read": false,
      "data": { "reportId": "...", "lat": "5.36", "lng": "-4.00" },
      "createdAt": "..."
    }
  ]
}
```

**Marquer toutes comme lues**
```
PATCH /api/notifications/read   [Auth]
→ { "updated": 3 }
```

**Types de notifications**

| Type | Déclencheur |
|------|-------------|
| `ABUS_NEARBY` | Un abus signalé dans un rayon de 5 km autour de l'utilisateur |
| `REPORT_CONFIRMED` | 3, 5 ou 10 personnes ont confirmé le même abus dans un rayon de 2 km |

---

### Résumé — endpoints mobile (15 routes)

```
POST  /api/auth/register                    ← inscription
POST  /api/auth/login                       ← connexion
GET   /api/auth/me                [Auth]    ← profil connecté

GET   /api/products                         ← catalogue (démarrage)
GET   /api/official-prices/active           ← prix plafond (démarrage) ?zone=ABIDJAN_30KM

GET   /api/prices/summary                   ← résumé prix locaux ?packagingId= &lat= &lng= &radius=
GET   /api/prices/history                   ← tendance hebdo ?packagingId= &lat= &lng= &radius=

POST  /api/reports                [Auth]    ← signaler ou confirmer un prix [Rate limit]
GET   /api/reports/mine           [Auth]    ← mes signalements ?page=
GET   /api/reports/map                      ← carte ?onlyAbus=true|false

GET   /api/gamification/me        [Auth]    ← points, niveau, badges
GET   /api/leaderboard                      ← classement ?period=week|month

POST  /api/notifications/token    [Auth]    ← enregistrer token FCM
GET   /api/notifications          [Auth]    ← lister les notifications
PATCH /api/notifications/read     [Auth]    ← marquer tout comme lu
```

---

## Référence Admin

Tout ce dont le panneau d'administration a besoin. Toutes ces routes nécessitent un compte `role=ADMIN`.

### Authentification admin

```
POST /api/auth/login   →  body: { email: "admin@prixklo.ci", password: "..." }
```

Le token obtenu doit être envoyé sur chaque route admin :
```
Authorization: Bearer <admin_token>
```

---

### Gestion des bulletins officiels

| Action | Endpoint | Description |
|--------|----------|-------------|
| Lister tous les bulletins | `GET /api/admin/bulletins` | Avec nombre de prix par bulletin |
| Créer un bulletin | `POST /api/admin/bulletins` | `isActive: false` par défaut |
| Activer un bulletin | `POST /api/admin/bulletins` | `isActive: true` → désactive les autres |

**Workflow typique (nouveau mois) :**
1. Convertir le PDF ministère en CSV (colonnes : `period,zone,category,product_name,packaging_label,max_price`)
2. Importer le CSV → crée le bulletin et les prix automatiquement
3. Activer le bulletin via `POST /api/admin/bulletins` avec `isActive: true`

---

### Import des prix officiels (CSV)

`POST /api/admin/official-prices/import`

Deux modes d'envoi :

**Mode A — Fichier (Postman / formulaire HTML)**
```
Content-Type: multipart/form-data
Champ: file → votre fichier .csv
```

**Mode B — Contenu texte (JSON)**
```json
{ "content": "period,zone,category,product_name,packaging_label,max_price\n2025-01,ABIDJAN_30KM,Céréales,Riz local,Sac 25kg,12500\n..." }
```

**Format CSV attendu :**
```csv
period,zone,category,product_name,packaging_label,max_price
2025-01,ABIDJAN_30KM,Céréales,Riz local,Sac 25kg,12500
2025-01,ABIDJAN_30KM,Céréales,Riz local,Sac 50kg,24500
2025-01,ABIDJAN_30KM,Huiles,Huile de palme,Bidon 5L,4500
```

**Réponse — rapport d'import :**
```json
{ "stats": { "processed": 10, "created": 8, "updated": 2, "errors": [] } }
```

> L'import est **idempotent** : relancer avec le même fichier met à jour les prix sans créer de doublons.

---

### Modération des signalements

| Action | Endpoint | Description |
|--------|----------|-------------|
| Lister tous les signalements | `GET /api/admin/reports` | Paginé (50/page), filtrable par statut |
| Filtrer par statut | `GET /api/admin/reports?status=ABUS` | `CONFORME`, `LIMITE`, `ABUS`, `UNKNOWN` |
| Marquer utile | `PATCH /api/admin/reports/:id/flag` | `{ "isUseful": true }` → +5 pts bonus à l'auteur |
| Marquer frauduleux | `PATCH /api/admin/reports/:id/flag` | `{ "isFraudulent": true }` |

---

### Résumé — endpoints admin (7 routes)

```
POST  /api/auth/login                               (connexion admin)
GET   /api/admin/bulletins                          [Admin]
POST  /api/admin/bulletins                          [Admin]
POST  /api/admin/official-prices/import             [Admin] multipart ou JSON
GET   /api/admin/reports                            [Admin] ?page= &status=
PATCH /api/admin/reports/:id/flag                   [Admin]
```

---

### Données disponibles en lecture seule pour le tableau de bord admin

Ces routes publiques/citoyen sont également utiles pour un dashboard admin :

| Endpoint | Utilité |
|----------|---------|
| `GET /api/bulletins/active` | Afficher le bulletin en cours |
| `GET /api/products` | Catalogue complet |
| `GET /api/reports/map?onlyAbus=true` | Carte des abus en temps réel |
| `GET /api/leaderboard` | Top citoyens |

---

## Zones supportées

| Code | Description |
|------|-------------|
| `ABIDJAN_30KM` | Zone Abidjan — rayon 30km (seule zone V1) |

---

## Comptes de test (seed)

| Email | Mot de passe | Rôle |
|-------|-------------|------|
| `admin@prixklo.ci` | `password123` | ADMIN |
| `citoyen1@prixklo.ci` | `password123` | CITIZEN |
| `citoyen2@prixklo.ci` | `password123` | CITIZEN |

**Données seed incluses :**
- **131 produits**, 242 packagings, 242 prix officiels (bulletin réel Juin 2022 — source : prixplafond.gouv.ci)
  - Catégories couvertes : Riz (91 marques), Sucre, Tomate concentrée, Pâtes alimentaires, Huile de palme, Viande de bœuf, Lait, Ciment
- **20 signalements d'abus** géolocalisés dans 10 quartiers d'Abidjan (Cocody, Plateau, Yopougon, Abobo, Adjamé, Marcory, Koumassi, Treichville, Port-Bouët, Attécoubé) — dont 14 avec nom d'enseigne

---

## Variables d'environnement

| Variable | Obligatoire | Description |
|----------|------------|-------------|
| `DATABASE_URL` | Oui | URL PostgreSQL Neon |
| `JWT_SECRET` | Oui | Clé secrète JWT (changer en prod) |
| `CLOUDINARY_CLOUD_NAME` | Non | Upload photo |
| `CLOUDINARY_API_KEY` | Non | Upload photo |
| `CLOUDINARY_API_SECRET` | Non | Upload photo |
| `FIREBASE_PROJECT_ID` | Non* | Notifications push FCM |
| `FIREBASE_PRIVATE_KEY` | Non* | Notifications push FCM |
| `FIREBASE_CLIENT_EMAIL` | Non* | Notifications push FCM |

> *Requis pour activer les notifications push. Obtenir depuis : Firebase Console → Project Settings → Service Accounts → Generate new private key

---

## Import Postman

1. Ouvrir Postman
2. **Import** → `postman/PrixKlo.postman_collection.json`
3. **Import** → `postman/PrixKlo.postman_environment.json`
4. Sélectionner l'environnement **PrixKlo — Local**
5. Lancer **Login (Admin)** et **Login (Citoyen)** pour auto-remplir les tokens
6. Lancer **Produits** pour auto-remplir le `packaging_id`
