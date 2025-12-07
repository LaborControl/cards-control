import { Router } from 'express';
import { z } from 'zod';

const router = Router();

// Schéma de validation pour les cartes
const CardSchema = z.object({
  id: z.string(),
  firstName: z.string(),
  lastName: z.string(),
  company: z.string().optional(),
  jobTitle: z.string().optional(),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  mobile: z.string().optional(),
  website: z.string().url().optional(),
  address: z.string().optional(),
  bio: z.string().optional(),
  photoUrl: z.string().url().optional(),
  logoUrl: z.string().url().optional(),
  primaryColor: z.string().default('#6366F1'),
  socialLinks: z.record(z.string()).optional(),
});

// Store temporaire (en production, utiliser une vraie base de données)
const cards = new Map<string, z.infer<typeof CardSchema>>();

/**
 * Récupérer une carte par son ID
 */
router.get('/:cardId', async (req, res) => {
  try {
    const { cardId } = req.params;
    const card = cards.get(cardId);

    if (!card) {
      return res.status(404).json({ error: 'Card not found' });
    }

    res.json(card);
  } catch (error) {
    console.error('Error fetching card:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Créer ou mettre à jour une carte
 */
router.post('/', async (req, res) => {
  try {
    const card = CardSchema.parse(req.body);
    cards.set(card.id, card);
    res.status(201).json(card);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid card data', details: error.errors });
    }
    console.error('Error creating card:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Générer une vCard pour une carte
 */
router.get('/:cardId/vcard', async (req, res) => {
  try {
    const { cardId } = req.params;
    const card = cards.get(cardId);

    if (!card) {
      return res.status(404).json({ error: 'Card not found' });
    }

    const vcard = generateVCard(card);

    res.setHeader('Content-Type', 'text/vcard; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${card.firstName}_${card.lastName}.vcf"`);
    res.send(vcard);
  } catch (error) {
    console.error('Error generating vCard:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Enregistrer une vue/partage pour les analytics
 */
router.post('/:cardId/analytics', async (req, res) => {
  try {
    const { cardId } = req.params;
    const { type, method, source } = req.body;

    // TODO: Enregistrer dans la base de données
    console.log(`Analytics: ${type} for card ${cardId} via ${method} from ${source}`);

    res.json({ success: true });
  } catch (error) {
    console.error('Error recording analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Génère une vCard au format standard
 */
function generateVCard(card: z.infer<typeof CardSchema>): string {
  const lines = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    `N:${card.lastName};${card.firstName};;;`,
    `FN:${card.firstName} ${card.lastName}`,
  ];

  if (card.company) lines.push(`ORG:${card.company}`);
  if (card.jobTitle) lines.push(`TITLE:${card.jobTitle}`);
  if (card.email) lines.push(`EMAIL:${card.email}`);
  if (card.phone) lines.push(`TEL;TYPE=WORK:${card.phone}`);
  if (card.mobile) lines.push(`TEL;TYPE=CELL:${card.mobile}`);
  if (card.website) lines.push(`URL:${card.website}`);
  if (card.address) lines.push(`ADR:;;${card.address};;;;`);
  if (card.photoUrl) lines.push(`PHOTO;VALUE=URI:${card.photoUrl}`);
  if (card.bio) lines.push(`NOTE:${card.bio}`);

  // Réseaux sociaux
  if (card.socialLinks) {
    Object.entries(card.socialLinks).forEach(([network, url]) => {
      lines.push(`X-SOCIALPROFILE;TYPE=${network}:${url}`);
    });
  }

  lines.push('END:VCARD');
  return lines.join('\r\n');
}

export { router as cardsRouter };
