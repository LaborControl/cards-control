const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const jwt = require('jsonwebtoken');
const path = require('path');

// CRM Integrations
// CRM Integrations
const crmIntegrations = require('./crm-integrations');

// Charger le service account pour Google Wallet
const serviceAccount = require('./service-account.json');

admin.initializeApp();

const db = admin.firestore();

const campaigns = require('./campaigns');

// ==================== GOOGLE WALLET API ====================

const GOOGLE_WALLET_ISSUER_ID = functions.config().google?.issuer_id || 'BCR2DN5TRDQIXRBC';
const GOOGLE_WALLET_CLASS_ID = `${GOOGLE_WALLET_ISSUER_ID}.lc_nfc_pro_business_card`;

/**
 * Génère un JWT signé pour Google Wallet
 */
function createGoogleWalletJwt(genericObject) {
  const claims = {
    iss: serviceAccount.client_email,
    aud: 'google',
    origins: ['https://cards-control.app', 'https://us-central1-lc-nfc-pro.cloudfunctions.net'],
    typ: 'savetowallet',
    payload: {
      genericObjects: [genericObject],
    },
  };

  const token = jwt.sign(claims, serviceAccount.private_key, { algorithm: 'RS256' });
  return token;
}

/**
 * Crée une classe de pass Google Wallet (info seulement)
 */
exports.createGoogleWalletClass = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      res.json({
        success: true,
        message: 'La classe Google Wallet a été créée dans la console',
        issuer_id: GOOGLE_WALLET_ISSUER_ID,
        class_id: GOOGLE_WALLET_CLASS_ID,
        service_account: serviceAccount.client_email,
      });
    } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Génère un lien "Add to Google Wallet" pour une carte de visite
 */
exports.generateGoogleWalletPass = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { cardId, debug } = req.query;

      console.log('=== generateGoogleWalletPass START ===');
      console.log('cardId:', cardId);
      console.log('ISSUER_ID:', GOOGLE_WALLET_ISSUER_ID);
      console.log('CLASS_ID:', GOOGLE_WALLET_CLASS_ID);
      console.log('Service Account:', serviceAccount.client_email);

      if (!cardId) {
        return res.status(400).json({ error: 'cardId is required' });
      }

      // Essayer de récupérer la carte depuis public_cards d'abord
      console.log('Fetching card from public_cards...');
      let cardDoc = await db.collection('public_cards').doc(cardId).get();
      let card = null;

      if (cardDoc.exists) {
        card = cardDoc.data();
        console.log('Card found in public_cards:', JSON.stringify(card, null, 2));
      } else {
        console.log('Card not in public_cards, searching in users collections...');
        // Chercher dans toutes les collections users/*/business_cards
        const usersSnapshot = await db.collection('users').get();
        for (const userDoc of usersSnapshot.docs) {
          const businessCardDoc = await db.collection(`users/${userDoc.id}/business_cards`).doc(cardId).get();
          if (businessCardDoc.exists) {
            card = businessCardDoc.data();
            console.log('Card found in user collection:', userDoc.id);
            // Créer automatiquement le document public_cards pour la prochaine fois
            await db.collection('public_cards').doc(cardId).set({
              cardId: cardId,
              userId: userDoc.id,
              firstName: card.firstName || '',
              lastName: card.lastName || '',
              company: card.company || '',
              jobTitle: card.jobTitle || '',
              email: card.email || '',
              phone: card.phone || '',
              mobile: card.mobile || '',
              website: card.website || '',
              address: card.address || '',
              bio: card.bio || '',
              photoUrl: card.photoUrl || '',
              primaryColor: card.primaryColor || '#6366F1',
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            break;
          }
        }
      }

      if (!card) {
        console.log('Card not found anywhere');
        return res.status(404).json({ error: 'Card not found' });
      }
      const objectId = `${GOOGLE_WALLET_ISSUER_ID}.${cardId.replace(/-/g, '_')}`;
      console.log('Object ID:', objectId);

      // Créer l'objet pass Google Wallet
      const genericObject = {
        id: objectId,
        classId: GOOGLE_WALLET_CLASS_ID,
        genericType: 'GENERIC_TYPE_UNSPECIFIED',
        hexBackgroundColor: card.primaryColor || '#6366F1',
        logo: {
          sourceUri: {
            uri: card.photoUrl || 'https://cards-control.app/logo.png',
          },
        },
        cardTitle: {
          defaultValue: {
            language: 'fr',
            value: `${card.firstName || ''} ${card.lastName || ''}`.trim() || 'Contact',
          },
        },
        subheader: {
          defaultValue: {
            language: 'fr',
            value: card.company || '',
          },
        },
        header: {
          defaultValue: {
            language: 'fr',
            value: card.jobTitle || 'Carte de visite',
          },
        },
        textModulesData: [],
        linksModuleData: {
          uris: [
            {
              uri: `https://cards-control.app/card/${cardId}`,
              description: 'Voir la carte complète',
            },
          ],
        },
        barcode: {
          type: 'QR_CODE',
          value: `https://cards-control.app/card/${cardId}`,
        },
      };

      // Ajouter les champs de texte
      if (card.company) {
        genericObject.textModulesData.push({
          id: 'company',
          header: 'Entreprise',
          body: card.company,
        });
      }
      if (card.jobTitle) {
        genericObject.textModulesData.push({
          id: 'jobTitle',
          header: 'Fonction',
          body: card.jobTitle,
        });
      }
      if (card.email) {
        genericObject.textModulesData.push({
          id: 'email',
          header: 'Email',
          body: card.email,
        });
      }
      if (card.phone || card.mobile) {
        genericObject.textModulesData.push({
          id: 'phone',
          header: 'Téléphone',
          body: card.phone || card.mobile,
        });
      }

      // Ajouter le site web aux liens
      if (card.website) {
        genericObject.linksModuleData.uris.unshift({
          uri: card.website.startsWith('http') ? card.website : `https://${card.website}`,
          description: 'Site web',
        });
      }

      // Générer le JWT signé
      console.log('Generating JWT...');
      console.log('Generic Object:', JSON.stringify(genericObject, null, 2));

      const token = createGoogleWalletJwt(genericObject);
      console.log('JWT generated, length:', token.length);

      // URL pour ajouter au Google Wallet
      const saveUrl = `https://pay.google.com/gp/v/save/${token}`;
      console.log('Save URL generated');

      // Mode debug: retourner les infos au lieu de rediriger
      if (debug === 'true') {
        return res.json({
          success: true,
          cardId,
          objectId,
          classId: GOOGLE_WALLET_CLASS_ID,
          issuerId: GOOGLE_WALLET_ISSUER_ID,
          serviceAccount: serviceAccount.client_email,
          card: {
            firstName: card.firstName,
            lastName: card.lastName,
            company: card.company,
            jobTitle: card.jobTitle,
          },
          saveUrl,
          jwtPreview: token.substring(0, 100) + '...',
        });
      }

      // Rediriger directement vers Google Wallet
      console.log('Redirecting to Google Wallet...');
      res.redirect(saveUrl);
    } catch (error) {
      console.error('Error generating pass:', error);
      console.error('Error stack:', error.stack);
      res.status(500).json({
        error: error.message,
        details: error.stack,
        hint: 'Check Firebase Functions logs for more details'
      });
    }
  });
});

/**
 * Génère les données pour Google Wallet (retourne JSON au lieu de rediriger)
 */
exports.getGoogleWalletJWT = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { cardId } = req.query;

      if (!cardId) {
        return res.status(400).json({ error: 'cardId is required' });
      }

      // Récupérer la carte
      const cardDoc = await db.collection('public_cards').doc(cardId).get();
      if (!cardDoc.exists) {
        return res.status(404).json({ error: 'Card not found' });
      }

      const card = cardDoc.data();
      const objectId = `${GOOGLE_WALLET_ISSUER_ID}.${cardId.replace(/-/g, '_')}`;

      const genericObject = {
        id: objectId,
        classId: GOOGLE_WALLET_CLASS_ID,
        genericType: 'GENERIC_TYPE_UNSPECIFIED',
        hexBackgroundColor: card.primaryColor || '#6366F1',
        cardTitle: {
          defaultValue: {
            language: 'fr',
            value: `${card.firstName || ''} ${card.lastName || ''}`.trim() || 'Contact',
          },
        },
        header: {
          defaultValue: {
            language: 'fr',
            value: card.jobTitle || 'Contact',
          },
        },
        subheader: {
          defaultValue: {
            language: 'fr',
            value: card.company || '',
          },
        },
        textModulesData: [],
        barcode: {
          type: 'QR_CODE',
          value: `https://cards-control.app/card/${cardId}`,
          alternateText: 'Scan pour voir la carte',
        },
      };

      // Ajouter les informations de contact
      if (card.email) {
        genericObject.textModulesData.push({
          id: 'email',
          header: 'Email',
          body: card.email,
        });
      }
      if (card.phone) {
        genericObject.textModulesData.push({
          id: 'phone',
          header: 'Téléphone',
          body: card.phone,
        });
      }

      // Générer le JWT et l'URL
      const token = createGoogleWalletJwt(genericObject);
      const saveUrl = `https://pay.google.com/gp/v/save/${token}`;

      res.json({
        success: true,
        saveUrl,
        issuerId: GOOGLE_WALLET_ISSUER_ID,
        classId: GOOGLE_WALLET_CLASS_ID,
        objectId,
      });
    } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// ==================== APPLE WALLET API ====================

/**
 * Génère un pass Apple Wallet (.pkpass) pour une carte de visite
 */
exports.generateAppleWalletPass = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { cardId } = req.query;

      if (!cardId) {
        return res.status(400).json({ error: 'cardId is required' });
      }

      // Récupérer la carte
      const cardDoc = await db.collection('public_cards').doc(cardId).get();
      if (!cardDoc.exists) {
        return res.status(404).json({ error: 'Card not found' });
      }

      const card = cardDoc.data();

      // Configuration requise (à définir via Firebase config)
      const APPLE_PASS_TYPE_ID = functions.config().apple?.pass_type_id;
      const APPLE_TEAM_ID = functions.config().apple?.team_id;

      if (!APPLE_PASS_TYPE_ID || !APPLE_TEAM_ID) {
        return res.status(500).json({
          error: 'Apple Wallet not configured',
          message: 'Please configure Apple Developer credentials',
          instructions: {
            step1: 'Create an Apple Developer account ($99/year)',
            step2: 'Create a Pass Type ID in Apple Developer portal',
            step3: 'Generate a certificate for the Pass Type ID',
            step4: 'Set firebase config: firebase functions:config:set apple.pass_type_id="pass.com.yourcompany.nfcpro" apple.team_id="YOUR_TEAM_ID"',
            step5: 'Upload certificates to Firebase Storage',
          },
        });
      }

      // Structure du pass Apple Wallet
      const passData = {
        formatVersion: 1,
        passTypeIdentifier: APPLE_PASS_TYPE_ID,
        serialNumber: cardId,
        teamIdentifier: APPLE_TEAM_ID,
        organizationName: 'LC NFC PRO',
        description: `Carte de visite - ${card.firstName} ${card.lastName}`,
        foregroundColor: 'rgb(255, 255, 255)',
        backgroundColor: card.primaryColor || 'rgb(99, 102, 241)',
        labelColor: 'rgb(255, 255, 255)',
        generic: {
          primaryFields: [
            {
              key: 'name',
              label: 'NOM',
              value: `${card.firstName} ${card.lastName}`,
            },
          ],
          secondaryFields: [
            {
              key: 'company',
              label: 'ENTREPRISE',
              value: card.company || '',
            },
            {
              key: 'title',
              label: 'FONCTION',
              value: card.jobTitle || '',
            },
          ],
          auxiliaryFields: [
            {
              key: 'phone',
              label: 'TÉLÉPHONE',
              value: card.phone || card.mobile || '',
            },
          ],
          backFields: [
            {
              key: 'email',
              label: 'EMAIL',
              value: card.email || '',
            },
            {
              key: 'website',
              label: 'SITE WEB',
              value: card.website || '',
            },
            {
              key: 'address',
              label: 'ADRESSE',
              value: card.address || '',
            },
          ],
        },
        barcode: {
          message: `https://cards-control.app/card/${cardId}`,
          format: 'PKBarcodeFormatQR',
          messageEncoding: 'iso-8859-1',
        },
        barcodes: [
          {
            message: `https://cards-control.app/card/${cardId}`,
            format: 'PKBarcodeFormatQR',
            messageEncoding: 'iso-8859-1',
          },
        ],
      };

      res.json({
        success: true,
        message: 'Apple Wallet pass data generated',
        note: 'Full .pkpass generation requires Apple Developer certificate',
        passData,
        downloadUrl: null,
      });
    } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// ==================== HELPER FUNCTIONS ====================

/**
 * Enregistre une vue de carte (appelé depuis la page web)
 */
exports.recordCardView = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { cardId, source } = req.body;

      if (!cardId) {
        return res.status(400).json({ error: 'cardId is required' });
      }

      // Enregistrer la vue
      await db.collection('card_views').add({
        cardId,
        source: source || 'web',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        userAgent: req.headers['user-agent'],
      });

      // Incrémenter le compteur
      await db.collection('public_cards').doc(cardId).update({
        viewCount: admin.firestore.FieldValue.increment(1),
      });

      res.json({ success: true });
    } catch (error) {
      console.error('Error recording view:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Récupère les informations d'une carte publique
 */
exports.getPublicCard = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { cardId } = req.query;

      if (!cardId) {
        return res.status(400).json({ error: 'cardId is required' });
      }

      // Essayer public_cards d'abord
      let cardDoc = await db.collection('public_cards').doc(cardId).get();
      let card = null;

      if (cardDoc.exists) {
        card = cardDoc.data();
      } else {
        // Chercher dans users/*/business_cards
        const usersSnapshot = await db.collection('users').get();
        for (const userDoc of usersSnapshot.docs) {
          const businessCardDoc = await db.collection(`users/${userDoc.id}/business_cards`).doc(cardId).get();
          if (businessCardDoc.exists) {
            card = businessCardDoc.data();
            card.cardId = cardId;
            // Créer automatiquement le document public_cards
            await db.collection('public_cards').doc(cardId).set({
              cardId: cardId,
              userId: userDoc.id,
              firstName: card.firstName || '',
              lastName: card.lastName || '',
              company: card.company || '',
              jobTitle: card.jobTitle || '',
              email: card.email || '',
              phone: card.phone || '',
              mobile: card.mobile || '',
              website: card.website || '',
              address: card.address || '',
              bio: card.bio || '',
              photoUrl: card.photoUrl || '',
              primaryColor: card.primaryColor || '#6366F1',
              socialLinks: card.socialLinks || {},
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            break;
          }
        }
      }

      if (!card) {
        return res.status(404).json({ error: 'Card not found' });
      }

      res.json({
        success: true,
        card: card,
      });
    } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// ==================== CRM INTEGRATIONS ====================

/**
 * Test CRM connection
 * POST /testCrmConnection
 * Body: { provider, apiKey, apiUrl? }
 */
exports.testCrmConnection = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { provider, apiKey, apiUrl } = req.body;

      if (!provider || !apiKey) {
        return res.status(400).json({ error: 'provider and apiKey are required' });
      }

      console.log(`Testing CRM connection: ${provider}`);
      const result = await crmIntegrations.testConnection(provider, apiKey, apiUrl);

      res.json(result);
    } catch (error) {
      console.error('Error testing CRM connection:', error);
      res.status(500).json({ success: false, message: error.message });
    }
  });
});

/**
 * Sync a single contact to CRM
 * POST /syncContactToCrm
 * Body: { userId, contactId } or { userId, contact }
 */
exports.syncContactToCrm = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { userId, contactId, contact: providedContact } = req.body;

      if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
      }

      // Get user's CRM config
      const configDoc = await db.doc(`users/${userId}/settings/crm`).get();
      if (!configDoc.exists || !configDoc.data().enabled) {
        return res.status(400).json({ error: 'CRM not configured for this user' });
      }

      const config = configDoc.data();
      const { provider, apiKey, apiUrl } = config;

      // Get contact data
      let contact = providedContact;
      if (!contact && contactId) {
        const contactDoc = await db.doc(`users/${userId}/scanned_contacts/${contactId}`).get();
        if (!contactDoc.exists) {
          return res.status(404).json({ error: 'Contact not found' });
        }
        contact = contactDoc.data();
      }

      if (!contact) {
        return res.status(400).json({ error: 'contact or contactId is required' });
      }

      console.log(`Syncing contact to ${provider} for user ${userId}`);
      const result = await crmIntegrations.syncContact(provider, apiKey, apiUrl, contact);

      // Log the sync
      if (result.success) {
        await db.collection(`users/${userId}/crm_sync_logs`).add({
          provider,
          contactId: contactId || 'manual',
          crmContactId: result.contactId,
          action: result.action,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update last sync timestamp
        await db.doc(`users/${userId}/settings/crm`).update({
          lastSync: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      res.json(result);
    } catch (error) {
      console.error('Error syncing contact to CRM:', error);
      res.status(500).json({ success: false, message: error.message });
    }
  });
});

/**
 * Sync all contacts to CRM
 * POST /syncAllContactsToCrm
 * Body: { userId }
 */
exports.syncAllContactsToCrm = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const { userId } = req.body;

      if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
      }

      // Get user's CRM config
      const configDoc = await db.doc(`users/${userId}/settings/crm`).get();
      if (!configDoc.exists || !configDoc.data().enabled) {
        return res.status(400).json({ error: 'CRM not configured for this user' });
      }

      const config = configDoc.data();
      const { provider, apiKey, apiUrl, syncContacts } = config;

      if (!syncContacts) {
        return res.status(400).json({ error: 'Contact sync is disabled' });
      }

      // Get all contacts
      const contactsSnapshot = await db.collection(`users/${userId}/scanned_contacts`).get();
      const results = {
        total: contactsSnapshot.size,
        success: 0,
        failed: 0,
        errors: [],
      };

      console.log(`Syncing ${results.total} contacts to ${provider} for user ${userId}`);

      for (const doc of contactsSnapshot.docs) {
        const contact = doc.data();
        const result = await crmIntegrations.syncContact(provider, apiKey, apiUrl, contact);

        if (result.success) {
          results.success++;

          // Log successful sync
          await db.collection(`users/${userId}/crm_sync_logs`).add({
            provider,
            contactId: doc.id,
            crmContactId: result.contactId,
            action: result.action,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          results.failed++;
          results.errors.push({
            contactId: doc.id,
            error: result.message,
          });
        }
      }

      // Update last sync timestamp
      await db.doc(`users/${userId}/settings/crm`).update({
        lastSync: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.json({
        success: true,
        results,
      });
    } catch (error) {
      console.error('Error syncing all contacts to CRM:', error);
      res.status(500).json({ success: false, message: error.message });
    }
  });
});

/**
 * Firestore trigger: Auto-sync new contacts to CRM
 */
exports.onContactCreated = functions.firestore
  .document('users/{userId}/scanned_contacts/{contactId}')
  .onCreate(async (snap, context) => {
    const { userId, contactId } = context.params;
    const contact = snap.data();

    try {
      // Check if user has CRM configured with auto-sync
      const configDoc = await db.doc(`users/${userId}/settings/crm`).get();
      if (!configDoc.exists) {
        console.log(`No CRM config for user ${userId}`);
        return null;
      }

      const config = configDoc.data();
      if (!config.enabled || !config.syncContacts) {
        console.log(`CRM sync disabled for user ${userId}`);
        return null;
      }

      const { provider, apiKey, apiUrl } = config;

      console.log(`Auto-syncing new contact ${contactId} to ${provider} for user ${userId}`);
      const result = await crmIntegrations.syncContact(provider, apiKey, apiUrl, contact);

      // Log the sync
      await db.collection(`users/${userId}/crm_sync_logs`).add({
        provider,
        contactId,
        crmContactId: result.contactId || null,
        action: result.success ? result.action : 'failed',
        error: result.success ? null : result.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        automatic: true,
      });

      if (result.success) {
        // Update last sync timestamp
        await db.doc(`users/${userId}/settings/crm`).update({
          lastSync: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`Contact sync result:`, result);
      return result;
    } catch (error) {
      console.error(`Error auto-syncing contact ${contactId}:`, error);

      // Log the error
      await db.collection(`users/${userId}/crm_sync_logs`).add({
        provider: 'unknown',
        contactId,
        action: 'failed',
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        automatic: true,
      });

      return null;
    }
  });

/**
 * Get CRM sync logs
 * GET /getCrmSyncLogs?userId=xxx&limit=50
 */
exports.getCrmSyncLogs = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { userId, limit = 50 } = req.query;

      if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
      }

      const logsSnapshot = await db
        .collection(`users/${userId}/crm_sync_logs`)
        .orderBy('timestamp', 'desc')
        .limit(parseInt(limit))
        .get();

      const logs = logsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate?.() || null,
      }));

      res.json({ success: true, logs });
    } catch (error) {
      console.error('Error getting CRM sync logs:', error);
      res.status(500).json({ success: false, message: error.message });
    }
  });
});

// ==================== CAMPAIGNS ====================

exports.processCampaign = campaigns.processCampaign;
