# Guide de Publication iOS - Cards Control

Ce guide explique comment configurer GitHub Actions pour builder et publier l'app iOS sur l'App Store.

## Prérequis

1. **Compte Apple Developer** ($99/an) - https://developer.apple.com
2. **App créée sur App Store Connect** - https://appstoreconnect.apple.com
3. **Certificats et Provisioning Profile** créés

---

## Étape 1 : Créer l'App sur App Store Connect

1. Aller sur https://appstoreconnect.apple.com
2. Cliquer sur "My Apps" → "+" → "New App"
3. Remplir :
   - **Platform** : iOS
   - **Name** : Cards Control
   - **Primary Language** : French
   - **Bundle ID** : com.cardscontrol.app
   - **SKU** : cardscontrol-app-001

---

## Étape 2 : Créer les Certificats (depuis n'importe quel navigateur)

### 2.1 Certificate Signing Request (CSR)

Comme tu n'as pas de Mac, tu devras :
- **Option A** : Utiliser un service cloud Mac (MacinCloud, MacStadium)
- **Option B** : Demander à quelqu'un avec un Mac de générer le CSR

Sur un Mac, ouvrir "Keychain Access" :
```
Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
```
- Email : ton email Apple Developer
- Common Name : Cards Control Distribution
- Request is : Saved to disk

### 2.2 Créer le Certificat de Distribution

1. Aller sur https://developer.apple.com/account/resources/certificates
2. Cliquer "+" → "Apple Distribution"
3. Uploader le fichier CSR
4. Télécharger le certificat (.cer)
5. Double-cliquer pour l'installer dans Keychain

### 2.3 Exporter en P12

Sur le Mac :
1. Ouvrir Keychain Access
2. Trouver le certificat "Apple Distribution: ..."
3. Clic droit → Export
4. Format : .p12
5. Définir un mot de passe (à garder pour GitHub Secrets)

---

## Étape 3 : Créer le Provisioning Profile

1. Aller sur https://developer.apple.com/account/resources/profiles
2. Cliquer "+" → "App Store"
3. Sélectionner l'App ID : com.cardscontrol.app
4. Sélectionner le certificat créé
5. Nommer : "Cards Control Distribution"
6. Télécharger le .mobileprovision

---

## Étape 4 : Créer l'API Key App Store Connect

1. Aller sur https://appstoreconnect.apple.com/access/api
2. Cliquer "+" pour créer une nouvelle clé
3. Nom : "GitHub Actions"
4. Access : "App Manager"
5. Télécharger la clé (.p8) - **ATTENTION : téléchargement unique !**
6. Noter :
   - **Issuer ID** (en haut de la page)
   - **Key ID** (dans la liste des clés)

---

## Étape 5 : Configurer les Secrets GitHub

Aller sur https://github.com/LaborControl/cards-control/settings/secrets/actions

Cliquer "New repository secret" pour chaque secret :

### Certificats Apple

| Secret Name | Description | Comment obtenir |
|------------|-------------|-----------------|
| `IOS_CERTIFICATE_P12` | Certificat .p12 en base64 | `base64 -i certificate.p12` |
| `IOS_CERTIFICATE_PASSWORD` | Mot de passe du .p12 | Le mot de passe choisi à l'export |
| `IOS_PROVISIONING_PROFILE` | Profile .mobileprovision en base64 | `base64 -i profile.mobileprovision` |
| `APPLE_TEAM_ID` | Team ID Apple | Visible sur developer.apple.com |

### App Store Connect API

| Secret Name | Description | Comment obtenir |
|------------|-------------|-----------------|
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | Page API Keys sur App Store Connect |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID | Page API Keys sur App Store Connect |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Contenu du .p8 | Ouvrir le fichier .p8 avec un éditeur texte |

### Firebase (récupérer depuis la console Firebase)

| Secret Name | Description |
|------------|-------------|
| `FIREBASE_PROJECT_ID` | lc-nfc-pro |
| `FIREBASE_MESSAGING_SENDER_ID` | Le sender ID |
| `FIREBASE_IOS_API_KEY` | API Key iOS |
| `FIREBASE_IOS_APP_ID` | App ID iOS |
| `FIREBASE_IOS_CLIENT_ID` | OAuth Client ID iOS |
| `FIREBASE_IOS_REVERSED_CLIENT_ID` | Le client ID inversé |
| `FIREBASE_WEB_API_KEY` | API Key Web |
| `FIREBASE_WEB_APP_ID` | App ID Web |
| `FIREBASE_ANDROID_API_KEY` | API Key Android |
| `FIREBASE_ANDROID_APP_ID` | App ID Android |

### Claude API

| Secret Name | Description |
|------------|-------------|
| `CLAUDE_API_KEY` | Ta clé API Anthropic |

---

## Étape 6 : Encoder les fichiers en Base64

### Sur Windows (PowerShell)
```powershell
# Pour le certificat P12
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12")) | Set-Clipboard

# Pour le provisioning profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision")) | Set-Clipboard
```

### Sur Mac/Linux
```bash
# Pour le certificat P12
base64 -i certificate.p12 | pbcopy

# Pour le provisioning profile
base64 -i profile.mobileprovision | pbcopy
```

---

## Étape 7 : Lancer le Build

### Automatique
Le build se lance automatiquement :
- À chaque push sur `main`
- À chaque création de tag `v*` (ex: v1.0.0)

### Manuel
1. Aller sur https://github.com/LaborControl/cards-control/actions
2. Cliquer sur "Build iOS & Deploy to App Store"
3. Cliquer "Run workflow"
4. Choisir si tu veux uploader sur TestFlight
5. Cliquer "Run workflow"

---

## Étape 8 : Soumettre à la Review

1. Une fois l'IPA uploadé sur TestFlight, aller sur App Store Connect
2. Cliquer sur l'app → "TestFlight"
3. Attendre que le build soit traité (~30 min)
4. Aller dans "App Store" → "Prepare for Submission"
5. Remplir toutes les métadonnées :
   - Screenshots
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL
6. Cliquer "Submit for Review"

---

## Résolution de Problèmes

### Erreur "No matching provisioning profile"
- Vérifier que le Bundle ID correspond
- Vérifier que le profil n'est pas expiré
- Régénérer le profil sur developer.apple.com

### Erreur "Certificate not found"
- Vérifier que le certificat n'est pas expiré
- Vérifier que le P12 a été correctement encodé en base64
- Vérifier le mot de passe

### Build échoue sur les entitlements
- Vérifier que les capabilities NFC sont activées sur l'App ID
- Vérifier les Associated Domains

---

## Contacts Support

- Apple Developer Support : https://developer.apple.com/support/
- GitHub Actions : https://docs.github.com/actions

---

## Checklist Finale

- [ ] Compte Apple Developer actif
- [ ] App créée sur App Store Connect
- [ ] Certificat de distribution créé et exporté en P12
- [ ] Provisioning Profile créé
- [ ] API Key App Store Connect créée
- [ ] Tous les secrets configurés sur GitHub
- [ ] Build testé manuellement
- [ ] Métadonnées App Store remplies
- [ ] Screenshots préparés
- [ ] Politique de confidentialité publiée
