# NFC Pro - Document de Spécifications Techniques
## Application Mobile Professionnelle NFC/RFID

---

**Version:** 1.0
**Date:** 28 Novembre 2025
**Statut:** Draft pour validation
**Confidentialité:** Confidentiel

---

## Table des matières

1. [Vue d'ensemble du projet](#1-vue-densemble-du-projet)
2. [Spécifications fonctionnelles](#2-spécifications-fonctionnelles)
3. [Architecture technique](#3-architecture-technique)
4. [Spécifications NFC/RFID](#4-spécifications-nfcrfid)
5. [Backend Azure](#5-backend-azure)
6. [Sécurité et conformité](#6-sécurité-et-conformité)
7. [Modèle économique](#7-modèle-économique)
8. [UI/UX Design](#8-uiux-design)
9. [Planning et livrables](#9-planning-et-livrables)
10. [Annexes](#10-annexes)

---

# 1. Vue d'ensemble du projet

## 1.1 Résumé exécutif

**NFC Pro** est une application mobile professionnelle multiplateforme (Android/iOS) permettant la lecture, l'écriture, la copie et l'émulation de puces NFC/RFID. L'application intègre également un système complet de gestion de cartes de visite numériques avec intégration aux wallets natifs (Google Wallet / Apple Wallet).

## 1.2 Objectifs business

| Objectif | Indicateur de succès |
|----------|---------------------|
| Devenir la référence pro NFC/RFID | Top 5 des apps NFC sur les stores |
| Rentabilité via abonnement | 10 000 abonnés actifs à 12 mois |
| Satisfaction utilisateur | Note moyenne ≥ 4.5/5 |
| Fiabilité | Uptime backend ≥ 99.9% |

## 1.3 Public cible

### Utilisateurs primaires
- **Professionnels IT/Sécurité** : Audit, tests de pénétration autorisés, gestion d'accès
- **Entreprises** : Gestion d'inventaire, contrôle d'accès, asset tracking
- **Développeurs IoT** : Prototypage, tests de tags NFC
- **Commerciaux/Marketing** : Cartes de visite numériques, networking

### Utilisateurs secondaires
- Collectionneurs (Amiibo, figurines NFC)
- Domoticiens (automatisation maison)
- Professionnels de l'événementiel

## 1.4 Positionnement marché

```
┌─────────────────────────────────────────────────────────────────┐
│                    POSITIONNEMENT CONCURRENTIEL                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Fonctionnalités                                                │
│       ▲                                                         │
│       │                          ★ NFC Pro                      │
│       │                            (Notre position)             │
│  Pro  │     NFC Tools Pro                                       │
│       │         ●                                               │
│       │                    ● TagWriter                          │
│       │  ● NFC TagInfo                                          │
│       │                                                         │
│ Basic │────────────────────────────────────────────────► Prix   │
│       │  Gratuit          Freemium           Premium            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 1.5 Proposition de valeur unique

1. **Support exhaustif** : Toutes les puces NFC/RFID du marché (y compris les plus récentes)
2. **Tout-en-un** : Lecture, écriture, copie, émulation, cartes de visite
3. **Intégration Wallet** : Google Wallet et Apple Wallet natifs
4. **Cloud sync** : Synchronisation multi-appareils via Azure
5. **Interface pro** : UX pensée pour les professionnels

---

# 2. Spécifications fonctionnelles

## 2.1 Matrice des fonctionnalités

### 2.1.1 Module Lecture NFC/RFID

| ID | Fonctionnalité | Priorité | Android | iOS |
|----|----------------|----------|---------|-----|
| R001 | Détection automatique du type de tag | P0 | ✅ | ✅ |
| R002 | Lecture NDEF (tous formats) | P0 | ✅ | ✅ |
| R003 | Lecture données brutes (raw) | P0 | ✅ | ⚠️ Limité |
| R004 | Affichage UID/NUID | P0 | ✅ | ✅ |
| R005 | Lecture mémoire complète | P0 | ✅ | ⚠️ |
| R006 | Analyse structure du tag | P1 | ✅ | ✅ |
| R007 | Détection protections/locks | P1 | ✅ | ⚠️ |
| R008 | Export données (JSON/XML/Hex) | P1 | ✅ | ✅ |
| R009 | Historique des lectures | P2 | ✅ | ✅ |
| R010 | Lecture en lot (batch) | P2 | ✅ | ✅ |

### 2.1.2 Module Écriture NFC/RFID

| ID | Fonctionnalité | Priorité | Android | iOS |
|----|----------------|----------|---------|-----|
| W001 | Écriture NDEF standard | P0 | ✅ | ✅ |
| W002 | Écriture URL/URI | P0 | ✅ | ✅ |
| W003 | Écriture texte | P0 | ✅ | ✅ |
| W004 | Écriture vCard | P0 | ✅ | ✅ |
| W005 | Écriture données brutes | P0 | ✅ | ❌ |
| W006 | Écriture WiFi config | P1 | ✅ | ✅ |
| W007 | Écriture Bluetooth pairing | P1 | ✅ | ⚠️ |
| W008 | Écriture commandes personnalisées | P1 | ✅ | ❌ |
| W009 | Protection par mot de passe | P1 | ✅ | ⚠️ |
| W010 | Verrouillage permanent | P1 | ✅ | ⚠️ |
| W011 | Écriture en lot | P2 | ✅ | ✅ |
| W012 | Templates personnalisés | P2 | ✅ | ✅ |

### 2.1.3 Module Copie/Clone

| ID | Fonctionnalité | Priorité | Android | iOS |
|----|----------------|----------|---------|-----|
| C001 | Copie NDEF vers nouveau tag | P0 | ✅ | ✅ |
| C002 | Backup complet en fichier | P0 | ✅ | ⚠️ |
| C003 | Restauration depuis backup | P0 | ✅ | ⚠️ |
| C004 | Copie secteur par secteur | P1 | ✅ | ❌ |
| C005 | Détection tags clonables | P1 | ✅ | ⚠️ |
| C006 | Avertissement légal avant copie | P0 | ✅ | ✅ |

### 2.1.4 Module Émulation (HCE)

| ID | Fonctionnalité | Priorité | Android | iOS |
|----|----------------|----------|---------|-----|
| E001 | Émulation carte de visite | P0 | ✅ | ❌* |
| E002 | Émulation tag NDEF | P1 | ✅ | ❌ |
| E003 | Émulation UID configurable | P1 | ✅ | ❌ |
| E004 | Émulation Mifare (limité) | P2 | ⚠️ | ❌ |
| E005 | Profils d'émulation multiples | P1 | ✅ | ❌ |
| E006 | Activation rapide (widget) | P2 | ✅ | ❌ |

> *iOS : L'émulation HCE n'est pas autorisée par Apple. Alternative via Apple Wallet passes.

### 2.1.5 Module Cartes de visite

| ID | Fonctionnalité | Priorité | Android | iOS |
|----|----------------|----------|---------|-----|
| B001 | Création carte de visite | P0 | ✅ | ✅ |
| B002 | Import depuis contacts | P0 | ✅ | ✅ |
| B003 | Scan carte papier (OCR) | P1 | ✅ | ✅ |
| B004 | QR Code génération | P0 | ✅ | ✅ |
| B005 | Partage NFC | P0 | ✅ | ✅ |
| B006 | Partage lien/QR | P0 | ✅ | ✅ |
| B007 | Templates personnalisables | P1 | ✅ | ✅ |
| B008 | Carnet de contacts scanné | P1 | ✅ | ✅ |
| B009 | Analytics (vues, scans) | P2 | ✅ | ✅ |
| B010 | Page web personnelle | P1 | ✅ | ✅ |

### 2.1.6 Module Wallet

| ID | Fonctionnalité | Priorité | Android | iOS |
|----|----------------|----------|---------|-----|
| WL01 | Export vers Google Wallet | P0 | ✅ | N/A |
| WL02 | Export vers Apple Wallet | P0 | N/A | ✅ |
| WL03 | Mise à jour dynamique | P1 | ✅ | ✅ |
| WL04 | Notifications push | P2 | ✅ | ✅ |
| WL05 | Géolocalisation contextuelle | P2 | ✅ | ✅ |

## 2.2 User Stories détaillées

### Epic 1 : Lecture NFC

```
US-R001: Lecture automatique
En tant qu'utilisateur professionnel
Je veux scanner un tag NFC en approchant mon téléphone
Afin d'obtenir instantanément toutes les informations du tag

Critères d'acceptation:
- [ ] Détection en moins de 500ms
- [ ] Identification automatique du type de puce
- [ ] Affichage structuré des données NDEF
- [ ] Affichage UID et caractéristiques techniques
- [ ] Possibilité d'exporter les données
- [ ] Sauvegarde automatique dans l'historique
```

```
US-R002: Analyse technique avancée
En tant que développeur/technicien
Je veux voir le dump mémoire complet du tag
Afin d'analyser sa structure et son contenu brut

Critères d'acceptation:
- [ ] Vue hexadécimale de la mémoire
- [ ] Identification des secteurs/pages
- [ ] Détection des zones protégées
- [ ] Export en format binaire/hex
```

### Epic 2 : Écriture NFC

```
US-W001: Écriture rapide
En tant qu'utilisateur
Je veux écrire rapidement une URL sur un tag
Afin de créer un tag de redirection en quelques secondes

Critères d'acceptation:
- [ ] Sélection du type de contenu (URL, texte, vCard...)
- [ ] Validation du format avant écriture
- [ ] Confirmation de succès avec détails
- [ ] Option de verrouillage après écriture
```

```
US-W002: Templates d'écriture
En tant qu'utilisateur régulier
Je veux sauvegarder des modèles d'écriture
Afin de réutiliser des configurations fréquentes

Critères d'acceptation:
- [ ] Création de templates personnalisés
- [ ] Catégorisation des templates
- [ ] Synchronisation cloud des templates
- [ ] Partage de templates (export/import)
```

### Epic 3 : Cartes de visite

```
US-B001: Création de ma carte
En tant que professionnel
Je veux créer ma carte de visite numérique
Afin de la partager facilement lors de rencontres

Critères d'acceptation:
- [ ] Formulaire complet (nom, titre, entreprise, contacts...)
- [ ] Upload photo de profil
- [ ] Upload logo entreprise
- [ ] Choix du template visuel
- [ ] Prévisualisation en temps réel
- [ ] Liens réseaux sociaux
```

```
US-B002: Partage multi-canal
En tant qu'utilisateur
Je veux partager ma carte de plusieurs façons
Afin de m'adapter à chaque situation

Critères d'acceptation:
- [ ] Partage NFC (tap to share)
- [ ] QR Code dynamique
- [ ] Lien URL partageable
- [ ] Export vCard
- [ ] Ajout au Wallet (Google/Apple)
```

## 2.3 Parcours utilisateur (User Flows)

### Flow 1 : Premier lancement

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Splash    │────▶│  Onboarding │────▶│   Signup/   │────▶│    Home     │
│   Screen    │     │  (3 écrans) │     │    Login    │     │  Dashboard  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  Demande    │
                                        │ permissions │
                                        │    NFC      │
                                        └─────────────┘
```

### Flow 2 : Lecture d'un tag

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Home     │────▶│   Mode      │────▶│   Scan      │────▶│  Résultat   │
│  Dashboard  │     │   Lecture   │     │  (waiting)  │     │   Détails   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                          ┌────────────────────────────────────────┤
                          ▼                    ▼                   ▼
                   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                   │   Export    │     │   Copier    │     │ Sauvegarder │
                   │   Données   │     │   le tag    │     │  Historique │
                   └─────────────┘     └─────────────┘     └─────────────┘
```

### Flow 3 : Création carte de visite

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Cartes    │────▶│  Nouvelle   │────▶│  Formulaire │────▶│   Choix     │
│   de visite │     │   Carte     │     │   Infos     │     │  Template   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Partage   │◀────│   Ajouter   │◀────│   Preview   │◀────│  Upload     │
│   Options   │     │  au Wallet  │     │   Carte     │     │  Photo/Logo │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

# 3. Architecture technique

## 3.1 Vue d'ensemble de l'architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS MOBILES                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────────────────┐     ┌─────────────────────────────┐       │
│   │      Android App            │     │        iOS App              │       │
│   │  ┌───────────────────────┐  │     │  ┌───────────────────────┐  │       │
│   │  │    Flutter UI Layer   │  │     │  │    Flutter UI Layer   │  │       │
│   │  ├───────────────────────┤  │     │  ├───────────────────────┤  │       │
│   │  │  Business Logic Layer │  │     │  │  Business Logic Layer │  │       │
│   │  ├───────────────────────┤  │     │  ├───────────────────────┤  │       │
│   │  │   Platform Channels   │  │     │  │   Platform Channels   │  │       │
│   │  ├───────────────────────┤  │     │  ├───────────────────────┤  │       │
│   │  │ Native NFC/HCE Module │  │     │  │  Native CoreNFC Module│  │       │
│   │  └───────────────────────┘  │     │  └───────────────────────┘  │       │
│   └─────────────────────────────┘     └─────────────────────────────┘       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ HTTPS/REST + WebSocket
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AZURE CLOUD                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│   │  Azure API      │  │  Azure          │  │  Azure          │             │
│   │  Management     │──│  Functions      │──│  SignalR        │             │
│   │  (Gateway)      │  │  (Backend API)  │  │  (Real-time)    │             │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│            │                   │                    │                        │
│            ▼                   ▼                    ▼                        │
│   ┌─────────────────────────────────────────────────────────────┐           │
│   │                     Azure Services                           │           │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │           │
│   │  │ Cosmos   │  │  Blob    │  │   B2C    │  │  Key     │    │           │
│   │  │ DB       │  │ Storage  │  │  (Auth)  │  │  Vault   │    │           │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │           │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │           │
│   │  │ Notif.   │  │  CDN     │  │ App      │  │ Monitor  │    │           │
│   │  │ Hubs     │  │          │  │ Insights │  │ /Logs    │    │           │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │           │
│   └─────────────────────────────────────────────────────────────┘           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 3.2 Stack technique détaillé

### 3.2.1 Application Mobile

| Composant | Technologie | Version | Justification |
|-----------|-------------|---------|---------------|
| Framework | Flutter | 3.24+ | Cross-platform, performances natives, excellent support NFC |
| Langage | Dart | 3.5+ | Typage fort, async/await natif |
| State Management | Riverpod | 2.5+ | Scalable, testable, moderne |
| Navigation | GoRouter | 14+ | Declarative routing, deep links |
| HTTP Client | Dio | 5+ | Interceptors, retry, cache |
| Local Storage | Hive + SQLite | Latest | Rapide (Hive) + relationnel (SQLite) |
| NFC | nfc_manager + custom | Latest | Base + extensions natives |
| UI Components | Material 3 + Custom | Latest | Design system cohérent |

### 3.2.2 Modules natifs

**Android (Kotlin)**
```kotlin
// Modules natifs requis
- NfcAdapter (lecture/écriture standard)
- IsoDep, NfcA, NfcB, NfcF, NfcV (protocoles bas niveau)
- HostApduService (émulation HCE)
- MifareClassic, MifareUltralight (puces spécifiques)
```

**iOS (Swift)**
```swift
// Modules natifs requis
- CoreNFC (NFCNDEFReaderSession, NFCTagReaderSession)
- PassKit (Apple Wallet integration)
- Contacts (import contacts)
- Vision (OCR cartes de visite)
```

### 3.2.3 Backend Azure

| Service | Usage | Tier recommandé |
|---------|-------|-----------------|
| Azure Functions | API serverless | Premium (P1v2) |
| Azure Cosmos DB | Base de données | Serverless |
| Azure Blob Storage | Fichiers/médias | Standard |
| Azure B2C | Authentification | Standard |
| Azure API Management | Gateway API | Developer → Standard |
| Azure SignalR | Temps réel | Standard |
| Azure Notification Hubs | Push notifications | Standard |
| Azure Key Vault | Secrets | Standard |
| Azure CDN | Distribution contenu | Standard |
| Application Insights | Monitoring | Standard |

## 3.3 Architecture applicative (Clean Architecture)

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── routes.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── colors.dart
│       └── typography.dart
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── nfc_constants.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── interceptors/
│   │   └── network_info.dart
│   ├── utils/
│   │   ├── extensions/
│   │   ├── helpers/
│   │   └── validators/
│   └── di/
│       └── injection_container.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── nfc_reader/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── nfc_local_datasource.dart
│   │   │   │   └── nfc_native_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── tag_model.dart
│   │   │   │   ├── ndef_record_model.dart
│   │   │   │   └── memory_dump_model.dart
│   │   │   └── repositories/
│   │   │       └── nfc_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── nfc_tag.dart
│   │   │   │   ├── ndef_record.dart
│   │   │   │   └── tag_technology.dart
│   │   │   ├── repositories/
│   │   │   │   └── nfc_repository.dart
│   │   │   └── usecases/
│   │   │       ├── read_tag.dart
│   │   │       ├── get_tag_info.dart
│   │   │       └── export_tag_data.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── nfc_reader_provider.dart
│   │       ├── screens/
│   │       │   ├── reader_screen.dart
│   │       │   └── tag_details_screen.dart
│   │       └── widgets/
│   │           ├── scan_animation.dart
│   │           ├── tag_info_card.dart
│   │           └── memory_view.dart
│   │
│   ├── nfc_writer/
│   │   └── ... (structure similaire)
│   │
│   ├── nfc_copy/
│   │   └── ... (structure similaire)
│   │
│   ├── hce_emulation/
│   │   └── ... (structure similaire)
│   │
│   ├── business_cards/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── cards_remote_datasource.dart
│   │   │   │   └── cards_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── business_card_model.dart
│   │   │   │   └── card_template_model.dart
│   │   │   └── repositories/
│   │   │       └── cards_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── business_card.dart
│   │   │   │   ├── contact_info.dart
│   │   │   │   └── card_template.dart
│   │   │   ├── repositories/
│   │   │   │   └── cards_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_card.dart
│   │   │       ├── share_card.dart
│   │   │       ├── scan_paper_card.dart
│   │   │       └── add_to_wallet.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       │   ├── cards_list_screen.dart
│   │       │   ├── card_editor_screen.dart
│   │       │   ├── card_preview_screen.dart
│   │       │   └── card_share_screen.dart
│   │       └── widgets/
│   │           ├── card_preview.dart
│   │           ├── template_selector.dart
│   │           └── qr_code_widget.dart
│   │
│   ├── wallet_integration/
│   │   └── ... (structure similaire)
│   │
│   ├── subscription/
│   │   └── ... (structure similaire)
│   │
│   └── settings/
│       └── ... (structure similaire)
│
└── shared/
    ├── widgets/
    │   ├── buttons/
    │   ├── cards/
    │   ├── dialogs/
    │   └── inputs/
    ├── models/
    └── providers/
```

## 3.4 Diagramme de base de données

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COSMOS DB SCHEMA                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐       ┌─────────────────────┐
│       Users         │       │    Subscriptions    │
├─────────────────────┤       ├─────────────────────┤
│ id (PK)             │───┐   │ id (PK)             │
│ email               │   │   │ userId (FK)         │──┐
│ displayName         │   │   │ planType            │  │
│ photoUrl            │   │   │ status              │  │
│ createdAt           │   │   │ startDate           │  │
│ lastLoginAt         │   │   │ endDate             │  │
│ settings (JSON)     │   │   │ paymentProvider     │  │
│ deviceTokens[]      │   │   │ transactionId       │  │
└─────────────────────┘   │   └─────────────────────┘  │
                          │                            │
                          │   ┌─────────────────────┐  │
                          └──▶│   BusinessCards     │◀─┘
                              ├─────────────────────┤
                              │ id (PK)             │
                              │ userId (FK)         │
                              │ templateId          │
                              │ firstName           │
                              │ lastName            │
                              │ title               │
                              │ company             │
                              │ email               │
                              │ phone               │
                              │ website             │
                              │ address             │
                              │ socialLinks (JSON)  │
                              │ photoUrl            │
                              │ logoUrl             │
                              │ customFields (JSON) │
                              │ publicUrl           │
                              │ qrCodeUrl           │
                              │ walletPassId        │
                              │ isActive            │
                              │ createdAt           │
                              │ updatedAt           │
                              │ analytics (JSON)    │
                              └─────────────────────┘

┌─────────────────────┐       ┌─────────────────────┐
│    TagHistory       │       │     Templates       │
├─────────────────────┤       ├─────────────────────┤
│ id (PK)             │       │ id (PK)             │
│ userId (FK)         │       │ name                │
│ tagType             │       │ category            │
│ uid                 │       │ thumbnailUrl        │
│ technology          │       │ config (JSON)       │
│ ndefRecords (JSON)  │       │ isPremium           │
│ memoryDump          │       │ createdAt           │
│ readAt              │       └─────────────────────┘
│ location (GeoJSON)  │
│ notes               │       ┌─────────────────────┐
│ isFavorite          │       │   WriteTemplates    │
└─────────────────────┘       ├─────────────────────┤
                              │ id (PK)             │
┌─────────────────────┐       │ userId (FK)         │
│   ScannedContacts   │       │ name                │
├─────────────────────┤       │ type                │
│ id (PK)             │       │ data (JSON)         │
│ userId (FK)         │       │ createdAt           │
│ cardOwnerId (FK)    │       └─────────────────────┘
│ scannedAt           │
│ method              │       ┌─────────────────────┐
│ notes               │       │   EmulationProfiles │
│ tags[]              │       ├─────────────────────┤
└─────────────────────┘       │ id (PK)             │
                              │ userId (FK)         │
                              │ name                │
                              │ type                │
                              │ data (JSON)         │
                              │ isActive            │
                              │ createdAt           │
                              └─────────────────────┘
```

## 3.5 API REST Specifications

### Base URL
```
Production: https://api.nfcpro.app/v1
Staging:    https://api-staging.nfcpro.app/v1
```

### Authentification
```http
Authorization: Bearer <JWT_TOKEN>
X-API-Key: <API_KEY>
X-Device-Id: <DEVICE_UUID>
```

### Endpoints principaux

#### Auth
```
POST   /auth/register          # Inscription
POST   /auth/login             # Connexion
POST   /auth/refresh           # Refresh token
POST   /auth/logout            # Déconnexion
POST   /auth/forgot-password   # Mot de passe oublié
POST   /auth/verify-email      # Vérification email
DELETE /auth/account           # Suppression compte
```

#### Users
```
GET    /users/me               # Profil utilisateur
PATCH  /users/me               # Mise à jour profil
PUT    /users/me/photo         # Upload photo
GET    /users/me/settings      # Paramètres
PATCH  /users/me/settings      # Mise à jour paramètres
```

#### Business Cards
```
GET    /cards                  # Liste des cartes
POST   /cards                  # Créer une carte
GET    /cards/:id              # Détails carte
PATCH  /cards/:id              # Modifier carte
DELETE /cards/:id              # Supprimer carte
POST   /cards/:id/duplicate    # Dupliquer carte
GET    /cards/:id/qr           # Générer QR code
POST   /cards/:id/wallet       # Ajouter au wallet
GET    /cards/:id/analytics    # Statistiques carte
GET    /cards/public/:slug     # Carte publique (no auth)
```

#### Templates
```
GET    /templates              # Liste templates
GET    /templates/:id          # Détails template
```

#### Tags (History)
```
GET    /tags                   # Historique des tags
POST   /tags                   # Sauvegarder un tag
GET    /tags/:id               # Détails tag
DELETE /tags/:id               # Supprimer tag
POST   /tags/:id/favorite      # Ajouter aux favoris
GET    /tags/export            # Export historique
```

#### Write Templates
```
GET    /write-templates        # Liste templates écriture
POST   /write-templates        # Créer template
GET    /write-templates/:id    # Détails template
PATCH  /write-templates/:id    # Modifier template
DELETE /write-templates/:id    # Supprimer template
```

#### Subscription
```
GET    /subscription           # État abonnement
POST   /subscription/verify    # Vérifier achat
POST   /subscription/restore   # Restaurer achats
```

#### Contacts (Scanned)
```
GET    /contacts               # Contacts scannés
POST   /contacts               # Ajouter contact
GET    /contacts/:id           # Détails contact
PATCH  /contacts/:id           # Modifier contact
DELETE /contacts/:id           # Supprimer contact
POST   /contacts/:id/export    # Exporter vCard
```

---

# 4. Spécifications NFC/RFID

## 4.1 Technologies supportées

### 4.1.1 NFC Forum Types

| Type | Technologie | Capacité | Lecture | Écriture | Notes |
|------|-------------|----------|---------|----------|-------|
| Type 1 | Topaz 512 | 454 bytes | ✅ | ✅ | Peu courant |
| Type 2 | NTAG, Ultralight | 48-888 bytes | ✅ | ✅ | Le plus courant |
| Type 3 | Sony FeliCa | 1-9 KB | ✅ | ⚠️ | Japon principalement |
| Type 4 | DESFire, JCOP | 2-32 KB | ✅ | ✅ | Haute sécurité |
| Type 5 | ICODE SLIX | 256 bytes - 8 KB | ✅ | ✅ | ISO 15693 |

### 4.1.2 Puces NTAG (NXP)

| Puce | Mémoire | UID | Protection | Support |
|------|---------|-----|------------|---------|
| NTAG210 | 48 bytes | 7 bytes | Lecture seule optionnelle | ✅ Full |
| NTAG212 | 128 bytes | 7 bytes | Lecture seule optionnelle | ✅ Full |
| NTAG213 | 144 bytes | 7 bytes | Password (32-bit) | ✅ Full |
| NTAG215 | 504 bytes | 7 bytes | Password (32-bit) | ✅ Full |
| NTAG216 | 888 bytes | 7 bytes | Password (32-bit) | ✅ Full |
| NTAG413 DNA | 160 bytes | 7 bytes | AES-128 | ✅ Full |
| NTAG424 DNA | 416 bytes | 7 bytes | AES-128, SUN | ✅ Full |
| NTAG424 DNA TagTamper | 416 bytes | 7 bytes | AES-128, tamper detect | ✅ Full |
| NTAG5 Link | 2000 bytes | 8 bytes | AES, I²C | ✅ Full |

### 4.1.3 Puces MIFARE (NXP)

| Puce | Mémoire | Sécurité | Support Android | Support iOS |
|------|---------|----------|-----------------|-------------|
| MIFARE Classic 1K | 1024 bytes | Crypto-1 (vulnérable) | ✅ Full | ❌ |
| MIFARE Classic 4K | 4096 bytes | Crypto-1 (vulnérable) | ✅ Full | ❌ |
| MIFARE Classic EV1 | 1K/4K | Crypto-1 amélioré | ✅ Full | ❌ |
| MIFARE Ultralight | 64 bytes | Aucune | ✅ Full | ✅ NDEF only |
| MIFARE Ultralight C | 192 bytes | 3DES | ✅ Full | ⚠️ Limité |
| MIFARE Ultralight EV1 | 48-128 bytes | Password 32-bit | ✅ Full | ⚠️ Limité |
| MIFARE Plus S/X | 1K/2K/4K | AES-128 | ✅ Full | ⚠️ Limité |
| MIFARE DESFire EV1 | 2-8 KB | 3DES/AES | ✅ Full | ✅ Full |
| MIFARE DESFire EV2 | 2-8 KB | AES-128 | ✅ Full | ✅ Full |
| MIFARE DESFire EV3 | 2-8 KB | AES-128, SUN | ✅ Full | ✅ Full |

### 4.1.4 Autres puces supportées

| Fabricant | Puce | Technologie | Support |
|-----------|------|-------------|---------|
| STMicroelectronics | ST25TA | NFC Type 4 | ✅ Full |
| STMicroelectronics | ST25TV | NFC Type 5 | ✅ Full |
| STMicroelectronics | ST25DV | NFC Type 5 + I²C | ✅ Full |
| Infineon | SLE66R35 | ISO 14443A | ✅ Android only |
| EM Microelectronic | EM4200 | 125 kHz RFID | ⚠️ Lecteur externe |
| EM Microelectronic | EM4100 | 125 kHz RFID | ⚠️ Lecteur externe |
| HID | iCLASS | 13.56 MHz | ⚠️ Lecteur externe |
| Texas Instruments | Tag-it HF-I | ISO 15693 | ✅ Full |
| Sony | FeliCa Lite | 212 kbps | ✅ Full |
| Sony | FeliCa Lite-S | 212 kbps | ✅ Full |

### 4.1.5 Protocoles et normes

| Protocole | Fréquence | Usage | Support |
|-----------|-----------|-------|---------|
| ISO 14443-A | 13.56 MHz | MIFARE, NTAG | ✅ Full |
| ISO 14443-B | 13.56 MHz | Cartes bancaires | ⚠️ Lecture UID |
| ISO 15693 | 13.56 MHz | ICODE, Tag-it | ✅ Full |
| ISO 18092 | 13.56 MHz | NFC peer-to-peer | ✅ Full |
| FeliCa | 13.56 MHz | Sony, Japon | ✅ Full |
| NFC-A | 13.56 MHz | Type 1, 2, 4 | ✅ Full |
| NFC-B | 13.56 MHz | Type 4 | ✅ Full |
| NFC-F | 13.56 MHz | Type 3 (FeliCa) | ✅ Full |
| NFC-V | 13.56 MHz | Type 5 (ISO 15693) | ✅ Full |

## 4.2 Formats NDEF supportés

### 4.2.1 Types de records NDEF

| Type | TNF | Description | Exemple |
|------|-----|-------------|---------|
| URI | 0x01 | Liens web, tel, email | https://example.com |
| Text | 0x01 | Texte brut multi-langue | "Hello World" |
| Smart Poster | 0x01 | URI + métadonnées | URL avec titre/icône |
| vCard | 0x02 | Contact | Carte de visite complète |
| WiFi | 0x02 | Configuration WiFi | SSID + password |
| Bluetooth | 0x02 | Appairage Bluetooth | Adresse MAC + nom |
| Android App | 0x04 | Android Application Record | Package name |
| MIME | 0x02 | Données MIME | JSON, images, etc. |
| External | 0x04 | Type personnalisé | Données custom |

### 4.2.2 Actions supportées

| Action | Description | Implémentation |
|--------|-------------|----------------|
| Open URL | Ouvre navigateur | Intent/Universal Link |
| Dial Phone | Appel téléphone | tel: scheme |
| Send SMS | Envoie SMS | sms: scheme |
| Send Email | Ouvre email | mailto: scheme |
| Connect WiFi | Configure WiFi | WifiManager (Android) |
| Pair Bluetooth | Appairage BT | BluetoothAdapter |
| Add Contact | Ajoute contact | ContactsContract |
| Open App | Lance application | AAR / Universal Link |
| Navigate | GPS navigation | geo: scheme |
| Open File | Ouvre fichier | Content provider |

## 4.3 Fonctionnalités de sécurité

### 4.3.1 Authentification par mot de passe

```
┌─────────────────────────────────────────────────────────────────┐
│                    PASSWORD AUTHENTICATION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   NTAG21x (32-bit password)                                     │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  PWD (4 bytes) + PACK (2 bytes) = 6 bytes total          │  │
│   │  - Protection lecture et/ou écriture                      │  │
│   │  - Configuration AUTH0 pour début protection              │  │
│   │  - Compteur tentatives (optionnel)                        │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│   MIFARE Ultralight C (3DES)                                    │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Clé 3DES 128 bits (16 bytes)                            │  │
│   │  - Mutual authentication                                  │  │
│   │  - Protection pages configurables                         │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│   MIFARE DESFire (AES-128)                                      │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Clé AES-128 (16 bytes) par application                  │  │
│   │  - Jusqu'à 28 applications                                │  │
│   │  - Jusqu'à 14 clés par application                        │  │
│   │  - Droits d'accès granulaires                             │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3.2 Secure Unique NFC (SUN)

Support pour NTAG 424 DNA et DESFire EV3 :
- Messages authentifiés dynamiques
- Compteur anti-rejeu
- Validation backend
- Détection de clonage

### 4.3.3 Signature NFC (NXP)

```
Vérification d'authenticité :
1. Lecture signature ECDSA du tag
2. Vérification avec clé publique NXP
3. Confirmation que le tag est authentique
```

## 4.4 Lecteurs externes RFID (optionnel)

Pour les fréquences non supportées nativement :

| Type | Fréquence | Connexion | Usage |
|------|-----------|-----------|-------|
| ACR122U | 13.56 MHz | USB OTG | PC/Android |
| ACR1255U-J1 | 13.56 MHz | Bluetooth | Mobile |
| Proxmark3 | LF/HF | USB | Analyse avancée |
| ChameleonMini | 13.56 MHz | USB | Émulation |
| Lecteur 125 kHz | 125 kHz | Bluetooth/USB | Badges anciens |

---

# 5. Backend Azure

## 5.1 Architecture détaillée

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AZURE ARCHITECTURE                                   │
└─────────────────────────────────────────────────────────────────────────────┘

                                    Internet
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │   Azure Front Door  │
                            │   (CDN + WAF)       │
                            └─────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
           ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
           │ Static Web   │   │     API      │   │   SignalR    │
           │ Apps (Cards) │   │  Management  │   │   Service    │
           └──────────────┘   └──────────────┘   └──────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
           ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
           │   Function   │   │   Function   │   │   Function   │
           │   App: API   │   │  App: Jobs   │   │  App: Events │
           └──────────────┘   └──────────────┘   └──────────────┘
                    │                 │                 │
                    └─────────────────┼─────────────────┘
                                      ▼
                            ┌─────────────────────┐
                            │  Virtual Network    │
                            │  (Private Endpoints)│
                            └─────────────────────┘
                                      │
        ┌─────────────┬───────────────┼───────────────┬─────────────┐
        ▼             ▼               ▼               ▼             ▼
┌─────────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────┐
│  Cosmos DB  │ │   Blob   │ │   Azure      │ │  Notif.      │ │   Key   │
│             │ │ Storage  │ │   B2C        │ │  Hubs        │ │  Vault  │
└─────────────┘ └──────────┘ └──────────────┘ └──────────────┘ └─────────┘
```

## 5.2 Azure Functions - Structure

```
azure-functions/
├── src/
│   ├── functions/
│   │   ├── auth/
│   │   │   ├── register.ts
│   │   │   ├── login.ts
│   │   │   ├── refresh-token.ts
│   │   │   └── verify-email.ts
│   │   │
│   │   ├── users/
│   │   │   ├── get-profile.ts
│   │   │   ├── update-profile.ts
│   │   │   └── delete-account.ts
│   │   │
│   │   ├── cards/
│   │   │   ├── create-card.ts
│   │   │   ├── get-cards.ts
│   │   │   ├── update-card.ts
│   │   │   ├── delete-card.ts
│   │   │   ├── generate-qr.ts
│   │   │   ├── get-public-card.ts
│   │   │   └── track-analytics.ts
│   │   │
│   │   ├── wallet/
│   │   │   ├── generate-google-pass.ts
│   │   │   ├── generate-apple-pass.ts
│   │   │   └── update-pass.ts
│   │   │
│   │   ├── tags/
│   │   │   ├── save-tag.ts
│   │   │   ├── get-tags.ts
│   │   │   └── delete-tag.ts
│   │   │
│   │   ├── subscription/
│   │   │   ├── verify-purchase.ts
│   │   │   ├── get-status.ts
│   │   │   └── restore-purchase.ts
│   │   │
│   │   └── webhooks/
│   │       ├── google-play.ts
│   │       ├── app-store.ts
│   │       └── stripe.ts
│   │
│   ├── shared/
│   │   ├── middleware/
│   │   │   ├── auth.ts
│   │   │   ├── rate-limit.ts
│   │   │   └── validation.ts
│   │   │
│   │   ├── services/
│   │   │   ├── cosmos-db.ts
│   │   │   ├── blob-storage.ts
│   │   │   ├── email.ts
│   │   │   ├── push-notifications.ts
│   │   │   └── wallet-pass.ts
│   │   │
│   │   └── utils/
│   │       ├── jwt.ts
│   │       ├── crypto.ts
│   │       └── validators.ts
│   │
│   └── config/
│       ├── cosmos.ts
│       └── azure.ts
│
├── package.json
├── tsconfig.json
├── host.json
└── local.settings.json
```

## 5.3 Estimation des coûts Azure

### Hypothèses
- 10 000 utilisateurs actifs
- 50 000 requêtes API/jour
- 5 GB stockage données
- 10 GB stockage médias

### Coûts mensuels estimés

| Service | Tier | Coût mensuel |
|---------|------|--------------|
| Azure Functions | Premium P1v2 | ~85€ |
| Cosmos DB | Serverless | ~25€ |
| Blob Storage | Standard | ~5€ |
| Azure B2C | 50K MAU | Gratuit (50K inclus) |
| API Management | Developer | ~45€ |
| Azure SignalR | Standard S1 | ~45€ |
| Notification Hubs | Standard | ~8€ |
| Key Vault | Standard | ~3€ |
| Front Door | Standard | ~30€ |
| Application Insights | Pay-as-you-go | ~10€ |
| **TOTAL ESTIMÉ** | | **~256€/mois** |

### Évolution avec la croissance

| Utilisateurs | Coût mensuel estimé |
|--------------|---------------------|
| 1 000 | ~150€ |
| 10 000 | ~256€ |
| 50 000 | ~500€ |
| 100 000 | ~900€ |

## 5.4 Infrastructure as Code (Terraform)

```hcl
# main.tf - Configuration principale

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "nfcpro-tfstate"
    storage_account_name = "nfcprotfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "nfcpro-${var.environment}"
  location = var.location
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "nfcpro-cosmos-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "nfcprostorage${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    versioning_enabled = true
  }
}

# Function App
resource "azurerm_linux_function_app" "api" {
  name                = "nfcpro-api-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  site_config {
    application_stack {
      node_version = "18"
    }
    cors {
      allowed_origins = ["https://nfcpro.app"]
    }
  }

  app_settings = {
    "COSMOS_CONNECTION"     = azurerm_cosmosdb_account.main.connection_strings[0]
    "STORAGE_CONNECTION"    = azurerm_storage_account.main.primary_connection_string
    "B2C_TENANT"           = var.b2c_tenant
    "APPINSIGHTS_KEY"      = azurerm_application_insights.main.instrumentation_key
  }
}

# ... autres ressources (SignalR, NotificationHubs, KeyVault, etc.)
```

---

# 6. Sécurité et conformité

## 6.1 Mesures de sécurité

### 6.1.1 Authentification et autorisation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AUTHENTICATION FLOW                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────┐       ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  User   │──────▶│  Azure B2C  │──────▶│   JWT       │──────▶│    API      │
│  Login  │       │  Identity   │       │   Token     │       │  Gateway    │
└─────────┘       └─────────────┘       └─────────────┘       └─────────────┘
                        │
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │  Email  │    │  Google │    │  Apple  │
    │ + Pass  │    │  OAuth  │    │  OAuth  │
    └─────────┘    └─────────┘    └─────────┘
```

**Spécifications JWT :**
- Algorithme : RS256
- Expiration access token : 15 minutes
- Expiration refresh token : 30 jours
- Claims : userId, email, subscription, roles

### 6.1.2 Chiffrement des données

| Contexte | Méthode | Détails |
|----------|---------|---------|
| Transit | TLS 1.3 | Certificats Azure managed |
| Repos (DB) | AES-256 | Azure managed keys |
| Repos (Blob) | AES-256 | Customer managed keys (optionnel) |
| Mots de passe | bcrypt | Cost factor 12 |
| Tokens | AES-256-GCM | Rotation automatique |
| Secrets | Azure Key Vault | HSM-backed (optionnel) |

### 6.1.3 Protection des API

```yaml
Rate Limiting:
  - Anonymous: 10 req/min
  - Authenticated: 100 req/min
  - Premium: 500 req/min

IP Filtering:
  - Blacklist malveillantes
  - Geo-blocking (optionnel)

Request Validation:
  - Taille max body: 10MB
  - Validation JSON Schema
  - Sanitization inputs

Headers sécurité:
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - Content-Security-Policy: strict
  - X-XSS-Protection: 1; mode=block
```

### 6.1.4 Sécurité mobile

| Mesure | Android | iOS |
|--------|---------|-----|
| Certificate pinning | ✅ | ✅ |
| Root/Jailbreak detection | ✅ | ✅ |
| Code obfuscation | ProGuard/R8 | Bitcode |
| Secure storage | EncryptedSharedPrefs | Keychain |
| Biometric auth | BiometricPrompt | LocalAuth |
| Anti-tampering | SafetyNet | DeviceCheck |

## 6.2 Conformité RGPD

### 6.2.1 Données collectées

| Catégorie | Données | Base légale | Rétention |
|-----------|---------|-------------|-----------|
| Compte | Email, nom, photo | Contrat | Durée du compte + 30j |
| Cartes de visite | Infos professionnelles | Contrat | Durée du compte + 30j |
| Historique tags | UID, données, localisation | Consentement | 1 an ou suppression manuelle |
| Analytics | Usage app anonymisé | Intérêt légitime | 2 ans |
| Paiements | Transaction IDs (pas de CB) | Obligation légale | 7 ans |

### 6.2.2 Droits des utilisateurs

| Droit | Implémentation | Délai |
|-------|----------------|-------|
| Accès | Export JSON/PDF depuis l'app | Immédiat |
| Rectification | Modification profil/cartes | Immédiat |
| Effacement | Suppression compte complète | 48h max |
| Portabilité | Export données format standard | Immédiat |
| Opposition | Paramètres de confidentialité | Immédiat |
| Limitation | Désactivation fonctionnalités | Immédiat |

### 6.2.3 Documentation obligatoire

- [ ] Politique de confidentialité (app + web)
- [ ] Conditions générales d'utilisation
- [ ] Registre des traitements
- [ ] Analyse d'impact (PIA) si nécessaire
- [ ] Contrats sous-traitants (DPA avec Azure)
- [ ] Procédure de gestion des violations

## 6.3 Mentions légales spécifiques NFC

### 6.3.1 Avertissements légaux

**À afficher dans l'app :**

```
⚠️ AVERTISSEMENT LÉGAL

L'utilisation des fonctionnalités de copie et d'émulation NFC/RFID
est soumise aux lois et réglementations locales.

Il est INTERDIT de :
• Copier des cartes d'accès sans autorisation du propriétaire
• Cloner des moyens de paiement
• Dupliquer des documents d'identité
• Contourner des systèmes de contrôle d'accès
• Utiliser l'émulation à des fins frauduleuses

L'utilisateur est SEUL RESPONSABLE de l'utilisation qu'il fait
de cette application. Le développeur décline toute responsabilité
en cas d'utilisation illégale.

En utilisant cette application, vous certifiez être le propriétaire
légitime des tags que vous copiez ou avoir l'autorisation explicite
du propriétaire.
```

### 6.3.2 Consentement obligatoire

Avant d'activer les fonctions de copie/émulation :
1. Affichage de l'avertissement complet
2. Case à cocher "J'ai lu et j'accepte"
3. Confirmation par action explicite
4. Logging du consentement (date, heure, version CGU)

---

# 7. Modèle économique

## 7.1 Structure de l'offre

### 7.1.1 Version gratuite (Freemium)

| Fonctionnalité | Limitation |
|----------------|------------|
| Lecture NFC | Illimitée |
| Écriture NDEF basique | 5/mois |
| Historique | 10 derniers tags |
| Carte de visite | 1 carte |
| Templates | 3 basiques |
| Émulation | ❌ |
| Cloud sync | ❌ |
| Wallet export | ❌ |
| Support | Communauté |
| Publicités | Bannières |

### 7.1.2 Version Pro (Abonnement 19€/an)

| Fonctionnalité | Inclus |
|----------------|--------|
| Lecture NFC | Illimitée + analyse avancée |
| Écriture | Illimitée, tous formats |
| Copie/Clone | Complète |
| Émulation HCE | Complète (Android) |
| Historique | Illimité + cloud sync |
| Cartes de visite | Illimitées |
| Templates | Tous + personnalisés |
| Wallet export | Google + Apple |
| Analytics cartes | Complet |
| Export données | JSON, XML, CSV, PDF |
| Lecteurs externes | Support complet |
| Support | Email prioritaire |
| Publicités | Aucune |
| Mises à jour | Prioritaires |

### 7.1.3 Fonctionnalités futures (v2+)

| Add-on | Prix | Description |
|--------|------|-------------|
| Team Pack | +29€/an | 5 utilisateurs, gestion centralisée |
| Enterprise | Sur devis | SSO, API, support dédié |
| White Label | Sur devis | App personnalisée |

## 7.2 Projections financières

### 7.2.1 Hypothèses

```
Téléchargements mensuels : 2 000 (croissance organique)
Taux conversion Free → Pro : 3%
Churn annuel : 25%
Prix : 19€/an
```

### 7.2.2 Projection sur 24 mois

| Mois | Downloads cumulés | Users Pro | MRR | ARR |
|------|-------------------|-----------|-----|-----|
| 1 | 2 000 | 60 | 95€ | 1 140€ |
| 6 | 15 000 | 450 | 712€ | 8 550€ |
| 12 | 30 000 | 900 | 1 425€ | 17 100€ |
| 18 | 48 000 | 1 350 | 2 137€ | 25 650€ |
| 24 | 70 000 | 2 100 | 3 325€ | 39 900€ |

### 7.2.3 Break-even analysis

```
Coûts fixes mensuels :
- Infrastructure Azure : 256€
- Apple Developer : 8€ (99€/an)
- Google Play : 2€ (25€ one-time amorti)
- Divers (domaine, email, etc.) : 20€
TOTAL : ~286€/mois

Break-even = 286€ / (19€/12) = 181 abonnés actifs
```

## 7.3 Intégration paiements

### 7.3.1 In-App Purchase

**Google Play Billing**
```kotlin
// Produit d'abonnement
val productId = "nfcpro_annual_subscription"
val offerToken = "annual-offer-2024"

// Vérification serveur
POST /api/subscription/verify
{
    "purchaseToken": "...",
    "productId": "nfcpro_annual_subscription",
    "platform": "android"
}
```

**Apple StoreKit 2**
```swift
// Produit d'abonnement
let productId = "com.nfcpro.subscription.annual"

// Vérification serveur (App Store Server API)
POST /api/subscription/verify
{
    "transactionId": "...",
    "productId": "com.nfcpro.subscription.annual",
    "platform": "ios"
}
```

### 7.3.2 Validation côté serveur

```typescript
// Azure Function - verify-purchase.ts

export async function verifyPurchase(
  req: HttpRequest
): Promise<HttpResponseInit> {
  const { purchaseToken, productId, platform } = await req.json();

  if (platform === 'android') {
    // Google Play Developer API
    const result = await googlePlay.purchases.subscriptions.get({
      packageName: 'com.nfcpro.app',
      subscriptionId: productId,
      token: purchaseToken
    });

    if (result.data.paymentState === 1) {
      await updateSubscription(userId, {
        status: 'active',
        platform: 'android',
        expiryDate: result.data.expiryTimeMillis
      });
    }
  } else if (platform === 'ios') {
    // App Store Server API
    const result = await appStore.verifyReceipt(purchaseToken);
    // ... validation similaire
  }
}
```

---

# 8. UI/UX Design

## 8.1 Design System

### 8.1.1 Palette de couleurs

```scss
// Couleurs principales
$primary: #2563EB;        // Bleu professionnel
$primary-light: #3B82F6;
$primary-dark: #1D4ED8;

$secondary: #10B981;      // Vert succès/action
$secondary-light: #34D399;
$secondary-dark: #059669;

// Couleurs neutres
$gray-900: #111827;       // Texte principal (dark mode bg)
$gray-800: #1F2937;
$gray-700: #374151;
$gray-600: #4B5563;
$gray-500: #6B7280;       // Texte secondaire
$gray-400: #9CA3AF;
$gray-300: #D1D5DB;
$gray-200: #E5E7EB;
$gray-100: #F3F4F6;       // Fond clair
$gray-50: #F9FAFB;

// Couleurs sémantiques
$success: #10B981;
$warning: #F59E0B;
$error: #EF4444;
$info: #3B82F6;

// NFC-specific
$nfc-active: #06B6D4;     // Cyan - NFC en cours
$nfc-success: #10B981;    // Vert - Tag détecté
$nfc-write: #8B5CF6;      // Violet - Mode écriture
```

### 8.1.2 Typographie

```scss
// Font families
$font-primary: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
$font-mono: 'JetBrains Mono', 'Fira Code', monospace;

// Font sizes
$text-xs: 12px;
$text-sm: 14px;
$text-base: 16px;
$text-lg: 18px;
$text-xl: 20px;
$text-2xl: 24px;
$text-3xl: 30px;
$text-4xl: 36px;

// Font weights
$font-regular: 400;
$font-medium: 500;
$font-semibold: 600;
$font-bold: 700;
```

### 8.1.3 Espacements et grille

```scss
// Spacing scale (8px base)
$space-1: 4px;
$space-2: 8px;
$space-3: 12px;
$space-4: 16px;
$space-5: 20px;
$space-6: 24px;
$space-8: 32px;
$space-10: 40px;
$space-12: 48px;
$space-16: 64px;

// Border radius
$radius-sm: 4px;
$radius-md: 8px;
$radius-lg: 12px;
$radius-xl: 16px;
$radius-full: 9999px;

// Shadows
$shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
$shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
$shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
$shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.15);
```

## 8.2 Composants UI principaux

### 8.2.1 Navigation

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                     APP HEADER                           │    │
│  │  ┌──────┐                              ┌────┐  ┌────┐   │    │
│  │  │ Logo │  NFC Pro                     │ 🔔 │  │ ⚙️ │   │    │
│  │  └──────┘                              └────┘  └────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│                        CONTENT AREA                              │
│                                                                  │
│                                                                  │
│                                                                  │
│                                                                  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   BOTTOM NAVIGATION                      │    │
│  │                                                          │    │
│  │   ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐       │    │
│  │   │ 📖 │    │ ✏️ │    │ 📇 │    │ 📋 │    │ ⚙️ │       │    │
│  │   │Read│    │Write│   │Cards│   │Hist│    │More│       │    │
│  │   └────┘    └────┘    └────┘    └────┘    └────┘       │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2.2 Écran de scan NFC

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│                         NFC READER                               │
│                                                                  │
│           ┌─────────────────────────────────────┐               │
│           │                                     │               │
│           │          ╭─────────────╮           │               │
│           │         ╱               ╲          │               │
│           │        │    ┌─────┐     │          │               │
│           │        │    │ NFC │     │          │               │
│           │        │    │ ))) │     │          │               │
│           │        │    └─────┘     │          │               │
│           │         ╲               ╱          │               │
│           │          ╰─────────────╯           │               │
│           │                                     │               │
│           │       Approchez un tag NFC          │               │
│           │                                     │               │
│           └─────────────────────────────────────┘               │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  💡 Conseil: Tenez le tag contre le centre arrière      │   │
│   │     de votre téléphone pour une meilleure détection     │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│   │  Historique │  │  Favoris    │  │  Templates  │            │
│   └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2.3 Résultat de lecture

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Retour                                    ⋮                  │
│─────────────────────────────────────────────────────────────────│
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  ✓  Tag lu avec succès                                  │   │
│   │                                                          │   │
│   │  Type: NTAG215                                          │   │
│   │  UID: 04:A3:2B:C4:5D:6E:80                             │   │
│   │  Mémoire: 504 bytes (492 disponibles)                   │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  CONTENU NDEF                                            │   │
│   ├─────────────────────────────────────────────────────────┤   │
│   │                                                          │   │
│   │  🔗 URL                                                  │   │
│   │  https://example.com/product/12345                      │   │
│   │                                                          │   │
│   │  ┌────────────┐  ┌────────────┐                         │   │
│   │  │  Ouvrir    │  │   Copier   │                         │   │
│   │  └────────────┘  └────────────┘                         │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌──────────────────┐  ┌──────────────────┐                   │
│   │  📋 Voir mémoire  │  │  💾 Sauvegarder  │                   │
│   └──────────────────┘  └──────────────────┘                   │
│                                                                  │
│   ┌──────────────────┐  ┌──────────────────┐                   │
│   │  📤 Exporter      │  │  📝 Dupliquer    │                   │
│   └──────────────────┘  └──────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2.4 Éditeur de carte de visite

```
┌─────────────────────────────────────────────────────────────────┐
│  ← Retour              Ma carte                    Aperçu →     │
│─────────────────────────────────────────────────────────────────│
│                                                                  │
│            ┌───────────────────────┐                            │
│            │     ┌─────────┐       │                            │
│            │     │  Photo  │       │                            │
│            │     │   📷    │       │                            │
│            │     └─────────┘       │                            │
│            │    Ajouter photo      │                            │
│            └───────────────────────┘                            │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Informations personnelles                               │   │
│   ├─────────────────────────────────────────────────────────┤   │
│   │                                                          │   │
│   │  Prénom *              Nom *                            │   │
│   │  ┌──────────────┐     ┌──────────────┐                  │   │
│   │  │ Jean         │     │ Dupont       │                  │   │
│   │  └──────────────┘     └──────────────┘                  │   │
│   │                                                          │   │
│   │  Titre / Fonction                                       │   │
│   │  ┌─────────────────────────────────────────┐            │   │
│   │  │ Directeur Commercial                    │            │   │
│   │  └─────────────────────────────────────────┘            │   │
│   │                                                          │   │
│   │  Entreprise                                             │   │
│   │  ┌─────────────────────────────────────────┐            │   │
│   │  │ ACME Corp                               │            │   │
│   │  └─────────────────────────────────────────┘            │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Coordonnées                                  ▼         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Réseaux sociaux                              ▼         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────────┐
│   │               💾 Sauvegarder                               │
│   └─────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘
```

## 8.3 Animations et micro-interactions

### 8.3.1 Animation de scan NFC

```dart
// Lottie animation specs
{
  "name": "nfc_scan_pulse",
  "duration": 2000, // ms
  "states": {
    "idle": {
      "animation": "gentle_pulse",
      "color": "$primary"
    },
    "scanning": {
      "animation": "active_ripple",
      "color": "$nfc-active"
    },
    "success": {
      "animation": "checkmark_appear",
      "color": "$success",
      "haptic": "success"
    },
    "error": {
      "animation": "shake",
      "color": "$error",
      "haptic": "error"
    }
  }
}
```

### 8.3.2 Transitions entre écrans

| Transition | Type | Durée | Curve |
|------------|------|-------|-------|
| Navigation avant | Slide right | 300ms | easeOutCubic |
| Navigation arrière | Slide left | 250ms | easeInCubic |
| Modal | Slide up + fade | 350ms | easeOutQuint |
| Tab switch | Fade | 200ms | linear |
| Scan result | Scale + fade | 400ms | elasticOut |

---

# 9. Planning et livrables

## 9.1 Phases de développement

### Phase 1 : Foundation (MVP Core)

**Objectif :** Application fonctionnelle avec lecture/écriture NFC basique

**Livrables :**
- [ ] Architecture projet Flutter
- [ ] Intégration native NFC (Android + iOS)
- [ ] Lecture tags NDEF (tous types)
- [ ] Écriture tags NDEF basique
- [ ] UI/UX de base
- [ ] Backend Azure (auth, API core)
- [ ] Authentification utilisateur

### Phase 2 : Core Features

**Objectif :** Fonctionnalités complètes NFC

**Livrables :**
- [ ] Lecture avancée (raw memory, analyse)
- [ ] Écriture tous formats
- [ ] Copie/backup tags
- [ ] Historique + synchronisation cloud
- [ ] Support puces avancées (MIFARE, DESFire)
- [ ] Templates d'écriture
- [ ] Export données

### Phase 3 : Business Cards

**Objectif :** Module cartes de visite complet

**Livrables :**
- [ ] Création/édition cartes
- [ ] Templates personnalisables
- [ ] Génération QR codes
- [ ] Page web publique
- [ ] Partage NFC/QR/lien
- [ ] Carnet de contacts scannés
- [ ] OCR scan carte papier

### Phase 4 : Premium Features

**Objectif :** Fonctionnalités Pro et monétisation

**Livrables :**
- [ ] Émulation HCE (Android)
- [ ] Intégration Google Wallet
- [ ] Intégration Apple Wallet
- [ ] Analytics cartes de visite
- [ ] Système d'abonnement
- [ ] In-app purchase (iOS + Android)
- [ ] Suppression publicités

### Phase 5 : Polish & Launch

**Objectif :** Production-ready

**Livrables :**
- [ ] Tests complets (unit, integration, e2e)
- [ ] Optimisation performances
- [ ] Accessibility (a11y)
- [ ] Localisation (FR, EN, ES, DE)
- [ ] Documentation utilisateur
- [ ] Assets stores (screenshots, vidéos)
- [ ] Soumission App Store + Play Store

### Phase 6 : Post-Launch

**Objectif :** Amélioration continue

**Livrables :**
- [ ] Monitoring et alerting
- [ ] Analyse usage (analytics)
- [ ] Corrections bugs prioritaires
- [ ] Feedback utilisateurs
- [ ] Optimisations ASO
- [ ] Features v1.1

## 9.2 Métriques de succès

### KPIs Techniques

| Métrique | Objectif | Mesure |
|----------|----------|--------|
| Crash-free rate | > 99.5% | Firebase Crashlytics |
| Temps démarrage app | < 2s | App Insights |
| Temps réponse API | < 200ms (p95) | Azure Monitor |
| Taux succès scan NFC | > 95% | Analytics custom |
| Uptime backend | > 99.9% | Azure SLA |

### KPIs Business

| Métrique | Objectif M6 | Objectif M12 |
|----------|-------------|--------------|
| Downloads | 15 000 | 30 000 |
| DAU | 1 500 | 3 000 |
| Conversion Pro | 3% | 4% |
| Note stores | 4.3/5 | 4.5/5 |
| Churn mensuel | < 5% | < 4% |

## 9.3 Matrice des risques

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Limitations iOS NFC | Élevé | Haute | Fonctionnalités alternatives, communication claire |
| Rejet App Store | Élevé | Moyenne | Guidelines strictes, review pre-submission |
| Problèmes de sécurité | Élevé | Faible | Audit sécurité, pentesting |
| Coûts Azure dépassés | Moyen | Moyenne | Alertes budget, auto-scaling limité |
| Concurrence agressive | Moyen | Moyenne | Différenciation UX, features uniques |
| Faible adoption | Élevé | Moyenne | Marketing ASO, version gratuite attractive |

---

# 10. Annexes

## 10.1 Glossaire

| Terme | Définition |
|-------|------------|
| NFC | Near Field Communication - technologie sans contact courte portée |
| RFID | Radio-Frequency Identification - identification par ondes radio |
| NDEF | NFC Data Exchange Format - format standard pour données NFC |
| HCE | Host Card Emulation - émulation de carte par logiciel |
| UID | Unique Identifier - identifiant unique du tag |
| AAR | Android Application Record - lien vers app Android |
| vCard | Format standard pour cartes de visite électroniques |
| ISO 14443 | Norme internationale pour cartes sans contact |
| APDU | Application Protocol Data Unit - commandes carte à puce |

## 10.2 Références techniques

- [NFC Forum Specifications](https://nfc-forum.org/our-work/specification-releases/)
- [Android NFC Guide](https://developer.android.com/guide/topics/connectivity/nfc)
- [Apple Core NFC](https://developer.apple.com/documentation/corenfc)
- [Flutter NFC Manager](https://pub.dev/packages/nfc_manager)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [Google Wallet API](https://developers.google.com/wallet)
- [Apple PassKit](https://developer.apple.com/documentation/passkit)

## 10.3 Contacts et responsabilités

| Rôle | Responsabilités |
|------|-----------------|
| Product Owner | Vision produit, priorisation backlog, validation |
| Lead Developer | Architecture, code review, décisions techniques |
| Mobile Developer | Développement Flutter, intégration native |
| Backend Developer | Azure Functions, API, base de données |
| UI/UX Designer | Design system, wireframes, prototypes |
| QA Engineer | Tests, automatisation, qualité |

---

## Historique des versions

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0 | 28/11/2025 | Claude AI | Création initiale |

---

**Document généré pour validation. En attente de review et approbation.**
