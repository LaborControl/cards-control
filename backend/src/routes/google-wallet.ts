import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { GoogleAuth } from 'google-auth-library';
import { z } from 'zod';

const router = Router();

// Configuration
const ISSUER_ID = process.env.GOOGLE_WALLET_ISSUER_ID || '';
const CLASS_SUFFIX = process.env.GOOGLE_WALLET_CLASS_SUFFIX || 'nfcpro_business_card';
const SERVICE_ACCOUNT_EMAIL = process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL || '';
const SERVICE_ACCOUNT_KEY_PATH = process.env.GOOGLE_SERVICE_ACCOUNT_KEY_PATH || '';

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
  photoUrl: z.string().optional(),
  logoUrl: z.string().optional(),
  primaryColor: z.string().default('#6366F1'),
});

type BusinessCard = z.infer<typeof CardSchema>;

/**
 * Crée la classe de pass Google Wallet (à faire une seule fois)
 */
async function createPassClass() {
  const auth = new GoogleAuth({
    keyFile: SERVICE_ACCOUNT_KEY_PATH,
    scopes: ['https://www.googleapis.com/auth/wallet_object.issuer'],
  });

  const client = await auth.getClient();
  const classId = `${ISSUER_ID}.${CLASS_SUFFIX}`;

  const genericClass = {
    id: classId,
    classTemplateInfo: {
      cardTemplateOverride: {
        cardRowTemplateInfos: [
          {
            twoItems: {
              startItem: {
                firstValue: {
                  fields: [{ fieldPath: "object.textModulesData['email']" }],
                },
              },
              endItem: {
                firstValue: {
                  fields: [{ fieldPath: "object.textModulesData['phone']" }],
                },
              },
            },
          },
        ],
      },
    },
  };

  try {
    const response = await client.request({
      url: 'https://walletobjects.googleapis.com/walletobjects/v1/genericClass',
      method: 'POST',
      data: genericClass,
    });
    console.log('Pass class created:', response.data);
    return response.data;
  } catch (error: any) {
    if (error.response?.status === 409) {
      console.log('Pass class already exists');
      return null;
    }
    throw error;
  }
}

/**
 * Génère un JWT signé pour Google Wallet
 */
function generateSignedJwt(card: BusinessCard): string {
  const classId = `${ISSUER_ID}.${CLASS_SUFFIX}`;
  const objectId = `${ISSUER_ID}.${card.id}`;

  const genericObject = {
    id: objectId,
    classId: classId,
    genericType: 'GENERIC_TYPE_UNSPECIFIED',
    hexBackgroundColor: card.primaryColor,
    logo: {
      sourceUri: {
        uri: card.logoUrl || 'https://cards-control.app/assets/logo.png',
      },
    },
    cardTitle: {
      defaultValue: {
        language: 'fr',
        value: card.company || 'Carte de visite',
      },
    },
    subheader: {
      defaultValue: {
        language: 'fr',
        value: card.jobTitle || '',
      },
    },
    header: {
      defaultValue: {
        language: 'fr',
        value: `${card.firstName} ${card.lastName}`,
      },
    },
    barcode: {
      type: 'QR_CODE',
      value: `https://cards-control.app/card/${card.id}`,
    },
    textModulesData: [
      ...(card.email ? [{ id: 'email', header: 'Email', body: card.email }] : []),
      ...(card.phone ? [{ id: 'phone', header: 'Téléphone', body: card.phone }] : []),
      ...(card.website ? [{ id: 'website', header: 'Site web', body: card.website }] : []),
    ],
    linksModuleData: {
      uris: [
        ...(card.website ? [{
          uri: card.website.startsWith('http') ? card.website : `https://${card.website}`,
          description: 'Site web',
        }] : []),
        {
          uri: `https://cards-control.app/card/${card.id}`,
          description: 'Voir la carte complète',
        },
      ],
    },
  };

  const claims = {
    iss: SERVICE_ACCOUNT_EMAIL,
    aud: 'google',
    typ: 'savetowallet',
    iat: Math.floor(Date.now() / 1000),
    payload: {
      genericObjects: [genericObject],
    },
  };

  // Note: En production, utilisez la clé privée du compte de service
  // const privateKey = fs.readFileSync(SERVICE_ACCOUNT_KEY_PATH);
  // return jwt.sign(claims, privateKey, { algorithm: 'RS256' });

  // Pour le développement, retourner un placeholder
  return Buffer.from(JSON.stringify(claims)).toString('base64url');
}

/**
 * Route pour ajouter une carte à Google Wallet
 */
router.get('/add', async (req, res) => {
  try {
    const { cardId } = req.query;

    if (!cardId || typeof cardId !== 'string') {
      return res.status(400).json({ error: 'cardId is required' });
    }

    // TODO: Récupérer les données de la carte depuis la base de données
    // Pour l'exemple, on utilise des données de test
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

    const token = generateSignedJwt(card);
    const saveUrl = `https://pay.google.com/gp/v/save/${token}`;

    // Rediriger vers Google Wallet
    res.redirect(saveUrl);
  } catch (error) {
    console.error('Error adding to Google Wallet:', error);
    res.status(500).json({ error: 'Failed to generate wallet pass' });
  }
});

/**
 * Route pour obtenir le JWT sans redirection
 */
router.post('/generate', async (req, res) => {
  try {
    const card = CardSchema.parse(req.body);
    const token = generateSignedJwt(card);
    const saveUrl = `https://pay.google.com/gp/v/save/${token}`;

    res.json({ token, saveUrl });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid card data', details: error.errors });
    }
    console.error('Error generating JWT:', error);
    res.status(500).json({ error: 'Failed to generate wallet pass' });
  }
});

export { router as googleWalletRouter };
