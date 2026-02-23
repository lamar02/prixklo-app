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
  "shopName": "Supermarché Hayat Cocody",
  "photoUrl": "https://..."
}
```

> `shopName` est **optionnel** — nom de l'enseigne ou du marché où le prix a été observé.

**Body (multipart/form-data)** — avec photo (Cloudinary requis)
```
packagingId=clxxx...
observedPrice=15000
lat=5.3599
lng=-4.0083
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

**Règles de calcul du statut**

| Condition | Statut | Points gagnés |
|-----------|--------|---------------|
| `observedPrice > maxPrice` | `ABUS` | +10 pts |
| `observedPrice ≤ maxPrice` | `CONFORME` | +5 pts |
| Aucun prix officiel trouvé | `UNKNOWN` | +2 pts |

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
| `status` | `CONFORME / ABUS / UNKNOWN` | Filtre optionnel |

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

Tout ce dont l'application mobile (citoyen) a besoin, dans l'ordre d'utilisation.

### Flux d'authentification

| Étape | Endpoint | Auth |
|-------|----------|------|
| Inscription | `POST /api/auth/register` | — |
| Connexion | `POST /api/auth/login` | — |
| Profil connecté | `GET /api/auth/me` | Bearer token |

Stocker le `token` reçu et l'envoyer dans chaque requête suivante via `Authorization: Bearer <token>`.

---

### Flux consultation des prix

| Étape | Endpoint | Remarque |
|-------|----------|----------|
| Charger le catalogue | `GET /api/products` | Liste produits + packagings pour l'UI de sélection |
| Charger les prix max | `GET /api/official-prices/active?zone=ABIDJAN_30KM` | Version allégée, idéale pour mise en cache côté mobile |

> **Conseil** : appeler `/api/official-prices/active` au démarrage et mettre les résultats en cache local. Recharger uniquement si le bulletin change.

---

### Flux signalement

| Étape | Endpoint | Auth |
|-------|----------|------|
| Créer un signalement | `POST /api/reports` | Bearer token |
| Voir mes signalements | `GET /api/reports/mine?page=1` | Bearer token |
| Carte des abus | `GET /api/reports/map?onlyAbus=false` | — |

**Body minimum pour créer un signalement :**
```json
{
  "packagingId": "<id du packaging sélectionné>",
  "observedPrice": 15000,
  "lat": 5.3599,
  "lng": -4.0083,
  "shopName": "Marché Adjamé 220 Logements"
}
```

> `shopName` est optionnel mais recommandé — il apparaît sur la carte pour identifier l'enseigne.

Pour envoyer une **photo** (optionnel) : utiliser `multipart/form-data` avec le champ `photo` (fichier image) + les autres champs en texte. Nécessite Cloudinary configuré. Sans photo, le body JSON suffit.

**Statuts retournés automatiquement :**
- `CONFORME` → prix ok, +5 pts
- `ABUS` → prix trop élevé, +10 pts
- `UNKNOWN` → pas de prix officiel disponible, +2 pts

---

### Flux gamification

| Endpoint | Description |
|----------|-------------|
| `GET /api/gamification/me` | Points, niveau, badges de l'utilisateur connecté |
| `GET /api/leaderboard?period=week` | Classement de la semaine |
| `GET /api/leaderboard?period=month` | Classement du mois |
| `GET /api/leaderboard` | Classement global tous temps |

---

### Résumé — endpoints mobile (10 routes)

```
POST  /api/auth/register
POST  /api/auth/login
GET   /api/auth/me                          [Auth]
GET   /api/products
GET   /api/official-prices/active           ?zone=ABIDJAN_30KM
POST  /api/reports                          [Auth] [Rate limit]
GET   /api/reports/mine                     [Auth] ?page=
GET   /api/reports/map                      ?onlyAbus=true|false
GET   /api/gamification/me                  [Auth]
GET   /api/leaderboard                      ?period=week|month
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
| Filtrer par statut | `GET /api/admin/reports?status=ABUS` | `CONFORME`, `ABUS`, `UNKNOWN` |
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
- 5 produits, 10 packagings, 10 prix officiels (bulletin Janvier 2025)
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

---

## Import Postman

1. Ouvrir Postman
2. **Import** → `postman/PrixKlo.postman_collection.json`
3. **Import** → `postman/PrixKlo.postman_environment.json`
4. Sélectionner l'environnement **PrixKlo — Local**
5. Lancer **Login (Admin)** et **Login (Citoyen)** pour auto-remplir les tokens
6. Lancer **Produits** pour auto-remplir le `packaging_id`
