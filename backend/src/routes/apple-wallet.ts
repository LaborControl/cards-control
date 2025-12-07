import { Router } from 'express';
import { z } from 'zod';
import path from 'path';
import fs from 'fs';

const router = Router();

// Configuration Apple Wallet
const PASS_TYPE_ID = process.env.APPLE_PASS_TYPE_ID || 'pass.com.nfcpro.businesscard';
const TEAM_ID = process.env.APPLE_TEAM_ID || '';
const CERT_PATH = process.env.APPLE_CERT_PATH || '';
const CERT_PASSWORD = process.env.APPLE_CERT_PASSWORD || '';
const WWDR_CERT_PATH = process.env.APPLE_WWDR_CERT_PATH || '';

// Schéma de validation
const CardSchema = z.object({
  id: z.string(),
  firstName: z.string(),
  lastName: z.string(),
  company: z.string().optional(),
  jobTitle: z.string().optional(),
  email: z.string().optional(),
  phone: z.string().optional(),
  website: z.string().optional(),
  address: z.string().optional(),
  bio: z.string().optional(),
  photoUrl: z.string().optional(),
  logoUrl: z.string().optional(),
  primaryColor: z.string().default('#6366F1'),
});

type BusinessCard = z.infer<typeof CardSchema>;

/**
 * Convertit une couleur hex en RGB pour Apple Wallet
 */
function hexToRgb(hex: string): string {
  hex = hex.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);
  return `rgb(${r}, ${g}, ${b})`;
}

/**
 * Génère les données du pass.json
 */
function generatePassJson(card: BusinessCard): object {
  return {
    formatVersion: 1,
    passTypeIdentifier: PASS_TYPE_ID,
    serialNumber: card.id,
    teamIdentifier: TEAM_ID,
    organizationName: 'NFC Pro',
    description: `Carte de visite - ${card.firstName} ${card.lastName}`,
    logoText: card.company || 'NFC Pro',
    foregroundColor: 'rgb(255, 255, 255)',
    backgroundColor: hexToRgb(card.primaryColor),
    labelColor: 'rgb(255, 255, 255)',

    // Type de pass: Generic
    generic: {
      primaryFields: [
        {
          key: 'name',
          label: 'NOM',
          value: `${card.firstName} ${card.lastName}`,
        },
      ],
      secondaryFields: [
        ...(card.jobTitle ? [{
          key: 'title',
          label: 'FONCTION',
          value: card.jobTitle,
        }] : []),
        ...(card.company ? [{
          key: 'company',
          label: 'ENTREPRISE',
          value: card.company,
        }] : []),
      ],
      auxiliaryFields: [
        ...(card.email ? [{
          key: 'email',
          label: 'EMAIL',
          value: card.email,
        }] : []),
        ...(card.phone ? [{
          key: 'phone',
          label: 'TÉLÉPHONE',
          value: card.phone,
        }] : []),
      ],
      backFields: [
        ...(card.website ? [{
          key: 'website',
          label: 'Site web',
          value: card.website,
        }] : []),
        ...(card.address ? [{
          key: 'address',
          label: 'Adresse',
          value: card.address,
        }] : []),
        ...(card.bio ? [{
          key: 'bio',
          label: 'À propos',
          value: card.bio,
        }] : []),
        {
          key: 'app',
          label: 'Application',
          value: 'Créé avec NFC Pro',
          attributedValue: '<a href="https://cards-control.app">cards-control.app</a>',
        },
      ],
    },

    // QR Code
    barcode: {
      format: 'PKBarcodeFormatQR',
      message: `https://cards-control.app/card/${card.id}`,
      messageEncoding: 'iso-8859-1',
      altText: 'Scanner pour voir la carte',
    },
    barcodes: [
      {
        format: 'PKBarcodeFormatQR',
        message: `https://cards-control.app/card/${card.id}`,
        messageEncoding: 'iso-8859-1',
        altText: 'Scanner pour voir la carte',
      },
    ],

    // URLs associées
    associatedStoreIdentifiers: [],
    appLaunchURL: `nfcpro://card/${card.id}`,

    // Notifications
    voided: false,

    // Localisation
    locations: [],

    // Date de création
    relevantDate: new Date().toISOString(),
  };
}

/**
 * Génère un fichier .pkpass
 * Note: En production, utilisez passkit-generator ou une bibliothèque similaire
 */
async function generatePkpass(card: BusinessCard): Promise<Buffer> {
  // Cette fonction nécessite les certificats Apple pour signer le pass
  // Pour un exemple complet, voir: https://github.com/alexandercerutti/passkit-generator

  try {
    // Dynamically import passkit-generator if available
    const { PKPass } = await import('passkit-generator');

    const pass = await PKPass.from({
      model: path.join(__dirname, '../../templates/business-card.pass'),
      certificates: {
        wwdr: fs.readFileSync(WWDR_CERT_PATH),
        signerCert: fs.readFileSync(CERT_PATH),
        signerKey: fs.readFileSync(CERT_PATH),
        signerKeyPassphrase: CERT_PASSWORD,
      },
    }, generatePassJson(card));

    // Personnaliser le pass
    pass.primaryFields.push({
      key: 'name',
      label: 'NOM',
      value: `${card.firstName} ${card.lastName}`,
    });

    // Générer le buffer du .pkpass
    return pass.getAsBuffer();
  } catch (error) {
    console.error('Error generating pkpass:', error);
    throw new Error('Failed to generate Apple Wallet pass. Certificates may not be configured.');
  }
}

/**
 * Route pour télécharger le pass Apple Wallet
 */
router.get('/download', async (req, res) => {
  try {
    const { cardId } = req.query;

    if (!cardId || typeof cardId !== 'string') {
      return res.status(400).json({ error: 'cardId is required' });
    }

    // TODO: Récupérer les données de la carte depuis la base de données
    const card: BusinessCard = {
      id: cardId,
      firstName: 'Jean',
      lastName: 'Dupont',
      company: 'NFC Pro',
      jobTitle: 'Développeur',
      email: 'jean.dupont@example.com',
      phone: '+33 6 12 34 56 78',
      website: 'https://cards-control.app',
      primaryColor: '#6366F1',
    };

    const pkpassBuffer = await generatePkpass(card);

    // Définir les headers pour le téléchargement
    res.setHeader('Content-Type', 'application/vnd.apple.pkpass');
    res.setHeader('Content-Disposition', `attachment; filename="${card.firstName}_${card.lastName}.pkpass"`);
    res.setHeader('Content-Length', pkpassBuffer.length);

    res.send(pkpassBuffer);
  } catch (error) {
    console.error('Error downloading Apple Wallet pass:', error);
    res.status(500).json({
      error: 'Failed to generate Apple Wallet pass',
      message: 'Cette fonctionnalité nécessite une configuration serveur avec les certificats Apple.'
    });
  }
});

/**
 * Route pour générer le pass.json (pour debug/preview)
 */
router.post('/preview', async (req, res) => {
  try {
    const card = CardSchema.parse(req.body);
    const passJson = generatePassJson(card);
    res.json(passJson);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid card data', details: error.errors });
    }
    console.error('Error generating pass preview:', error);
    res.status(500).json({ error: 'Failed to generate pass preview' });
  }
});

export { router as appleWalletRouter };
