# NFC Pro Backend API

Backend API pour la génération des passes Google Wallet et Apple Wallet.

## Prérequis

- Node.js 18+
- Compte Google Cloud avec l'API Google Wallet activée
- Compte Apple Developer avec les certificats Pass Type ID

## Configuration

### Google Wallet

1. Créer un projet dans Google Cloud Console
2. Activer l'API Google Wallet
3. Créer un compte de service et télécharger la clé JSON
4. Créer une classe de pass dans la console Google Wallet

### Apple Wallet

1. Créer un Pass Type ID dans Apple Developer Portal
2. Générer un certificat de signature (.p12)
3. Télécharger le certificat WWDR d'Apple

## Variables d'environnement

```env
# Server
PORT=3000
NODE_ENV=production

# Google Wallet
GOOGLE_SERVICE_ACCOUNT_EMAIL=xxx@xxx.iam.gserviceaccount.com
GOOGLE_SERVICE_ACCOUNT_KEY_PATH=./keys/google-service-account.json
GOOGLE_WALLET_ISSUER_ID=your_issuer_id
GOOGLE_WALLET_CLASS_SUFFIX=nfcpro_business_card

# Apple Wallet
APPLE_PASS_TYPE_ID=pass.com.nfcpro.businesscard
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_CERT_PATH=./certs/pass.p12
APPLE_CERT_PASSWORD=your_password
APPLE_WWDR_CERT_PATH=./certs/wwdr.pem

# Database
DATABASE_URL=postgresql://...

# Cards Control
CARDS_CONTROL_BASE_URL=https://cards-control.app
CARDS_CONTROL_API_URL=https://api.cards-control.app
```

## Installation

```bash
npm install
npm run build
npm start
```

## Endpoints

### Google Wallet
- `GET /wallet/google/add?cardId=xxx` - Redirige vers Google Wallet avec le JWT

### Apple Wallet
- `GET /wallet/apple/download?cardId=xxx` - Télécharge le fichier .pkpass

## Déploiement

Le backend peut être déployé sur :
- Google Cloud Run
- AWS Lambda
- Vercel
- Railway
- Render
