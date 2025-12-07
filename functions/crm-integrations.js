/**
 * CRM Integrations for Cards Control
 * Real implementations for HubSpot, Salesforce, Pipedrive, Zoho, Notion, Airtable, and Webhooks
 */

const axios = require('axios');
const { Client: NotionClient } = require('@notionhq/client');
const Airtable = require('airtable');

// ==================== HUBSPOT ====================

const HubSpotIntegration = {
  name: 'hubspot',

  /**
   * Test connection to HubSpot API
   */
  async testConnection(apiKey) {
    try {
      const response = await axios.get('https://api.hubapi.com/crm/v3/objects/contacts?limit=1', {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      });
      return { success: true, message: 'Connexion HubSpot réussie' };
    } catch (error) {
      const message = error.response?.data?.message || error.message;
      return { success: false, message: `Erreur HubSpot: ${message}` };
    }
  },

  /**
   * Create or update a contact in HubSpot
   */
  async syncContact(apiKey, contact) {
    try {
      // Search for existing contact by email
      let existingContactId = null;

      if (contact.email) {
        try {
          const searchResponse = await axios.post(
            'https://api.hubapi.com/crm/v3/objects/contacts/search',
            {
              filterGroups: [{
                filters: [{
                  propertyName: 'email',
                  operator: 'EQ',
                  value: contact.email,
                }],
              }],
            },
            {
              headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
              },
            }
          );

          if (searchResponse.data.results?.length > 0) {
            existingContactId = searchResponse.data.results[0].id;
          }
        } catch (e) {
          // Contact not found, will create new
        }
      }

      const properties = {
        email: contact.email || '',
        firstname: contact.firstName || '',
        lastname: contact.lastName || '',
        phone: contact.phone || contact.mobile || '',
        company: contact.company || '',
        jobtitle: contact.jobTitle || '',
        website: contact.website || '',
        address: contact.address || '',
        hs_lead_status: 'NEW',
      };

      let response;
      if (existingContactId) {
        // Update existing contact
        response = await axios.patch(
          `https://api.hubapi.com/crm/v3/objects/contacts/${existingContactId}`,
          { properties },
          {
            headers: {
              'Authorization': `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
          }
        );
      } else {
        // Create new contact
        response = await axios.post(
          'https://api.hubapi.com/crm/v3/objects/contacts',
          { properties },
          {
            headers: {
              'Authorization': `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
          }
        );
      }

      return {
        success: true,
        contactId: response.data.id,
        action: existingContactId ? 'updated' : 'created',
      };
    } catch (error) {
      const message = error.response?.data?.message || error.message;
      return { success: false, message: `Erreur HubSpot: ${message}` };
    }
  },
};

// ==================== SALESFORCE ====================

const SalesforceIntegration = {
  name: 'salesforce',

  /**
   * Test connection to Salesforce API
   * Requires: apiKey = access_token, apiUrl = instance_url
   */
  async testConnection(apiKey, apiUrl) {
    try {
      if (!apiUrl) {
        return { success: false, message: 'URL Salesforce requise (ex: https://yourcompany.salesforce.com)' };
      }

      const response = await axios.get(`${apiUrl}/services/data/v58.0/sobjects/Contact/describe`, {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      });
      return { success: true, message: 'Connexion Salesforce réussie' };
    } catch (error) {
      const message = error.response?.data?.[0]?.message || error.message;
      return { success: false, message: `Erreur Salesforce: ${message}` };
    }
  },

  /**
   * Create or update a contact in Salesforce
   */
  async syncContact(apiKey, apiUrl, contact) {
    try {
      if (!apiUrl) {
        return { success: false, message: 'URL Salesforce requise' };
      }

      // Search for existing contact by email
      let existingContactId = null;

      if (contact.email) {
        try {
          const query = encodeURIComponent(`SELECT Id FROM Contact WHERE Email = '${contact.email}' LIMIT 1`);
          const searchResponse = await axios.get(
            `${apiUrl}/services/data/v58.0/query?q=${query}`,
            {
              headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
              },
            }
          );

          if (searchResponse.data.records?.length > 0) {
            existingContactId = searchResponse.data.records[0].Id;
          }
        } catch (e) {
          // Contact not found
        }
      }

      const contactData = {
        Email: contact.email || '',
        FirstName: contact.firstName || '',
        LastName: contact.lastName || 'Inconnu',
        Phone: contact.phone || contact.mobile || '',
        Title: contact.jobTitle || '',
        MailingStreet: contact.address || '',
        Description: contact.bio || '',
      };

      let response;
      if (existingContactId) {
        // Update existing contact
        await axios.patch(
          `${apiUrl}/services/data/v58.0/sobjects/Contact/${existingContactId}`,
          contactData,
          {
            headers: {
              'Authorization': `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
          }
        );
        response = { id: existingContactId };
      } else {
        // Create new contact
        const createResponse = await axios.post(
          `${apiUrl}/services/data/v58.0/sobjects/Contact`,
          contactData,
          {
            headers: {
              'Authorization': `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
          }
        );
        response = { id: createResponse.data.id };
      }

      return {
        success: true,
        contactId: response.id,
        action: existingContactId ? 'updated' : 'created',
      };
    } catch (error) {
      const message = error.response?.data?.[0]?.message || error.response?.data?.message || error.message;
      return { success: false, message: `Erreur Salesforce: ${message}` };
    }
  },
};

// ==================== PIPEDRIVE ====================

const PipedriveIntegration = {
  name: 'pipedrive',

  /**
   * Test connection to Pipedrive API
   */
  async testConnection(apiKey) {
    try {
      const response = await axios.get(`https://api.pipedrive.com/v1/users/me?api_token=${apiKey}`);
      if (response.data.success) {
        return { success: true, message: `Connexion Pipedrive réussie (${response.data.data.name})` };
      }
      return { success: false, message: 'Erreur de connexion Pipedrive' };
    } catch (error) {
      const message = error.response?.data?.error || error.message;
      return { success: false, message: `Erreur Pipedrive: ${message}` };
    }
  },

  /**
   * Create or update a person in Pipedrive
   */
  async syncContact(apiKey, contact) {
    try {
      // Search for existing person by email
      let existingPersonId = null;

      if (contact.email) {
        try {
          const searchResponse = await axios.get(
            `https://api.pipedrive.com/v1/persons/search?term=${encodeURIComponent(contact.email)}&fields=email&api_token=${apiKey}`
          );

          if (searchResponse.data.data?.items?.length > 0) {
            existingPersonId = searchResponse.data.data.items[0].item.id;
          }
        } catch (e) {
          // Person not found
        }
      }

      const personData = {
        name: `${contact.firstName || ''} ${contact.lastName || ''}`.trim() || 'Contact',
        email: contact.email ? [{ value: contact.email, primary: true }] : undefined,
        phone: (contact.phone || contact.mobile) ? [{ value: contact.phone || contact.mobile, primary: true }] : undefined,
      };

      // Also create/find organization
      let orgId = null;
      if (contact.company) {
        try {
          const orgSearch = await axios.get(
            `https://api.pipedrive.com/v1/organizations/search?term=${encodeURIComponent(contact.company)}&api_token=${apiKey}`
          );

          if (orgSearch.data.data?.items?.length > 0) {
            orgId = orgSearch.data.data.items[0].item.id;
          } else {
            // Create organization
            const orgCreate = await axios.post(
              `https://api.pipedrive.com/v1/organizations?api_token=${apiKey}`,
              { name: contact.company }
            );
            orgId = orgCreate.data.data.id;
          }
        } catch (e) {
          // Ignore org errors
        }
      }

      if (orgId) {
        personData.org_id = orgId;
      }

      let response;
      if (existingPersonId) {
        // Update existing person
        response = await axios.put(
          `https://api.pipedrive.com/v1/persons/${existingPersonId}?api_token=${apiKey}`,
          personData
        );
      } else {
        // Create new person
        response = await axios.post(
          `https://api.pipedrive.com/v1/persons?api_token=${apiKey}`,
          personData
        );
      }

      return {
        success: true,
        contactId: response.data.data.id,
        action: existingPersonId ? 'updated' : 'created',
      };
    } catch (error) {
      const message = error.response?.data?.error || error.message;
      return { success: false, message: `Erreur Pipedrive: ${message}` };
    }
  },
};

// ==================== ZOHO CRM ====================

const ZohoIntegration = {
  name: 'zoho',

  /**
   * Test connection to Zoho CRM API
   * apiKey = access_token, apiUrl = api domain (ex: https://www.zohoapis.eu)
   */
  async testConnection(apiKey, apiUrl = 'https://www.zohoapis.eu') {
    try {
      const response = await axios.get(`${apiUrl}/crm/v2/users?type=CurrentUser`, {
        headers: {
          'Authorization': `Zoho-oauthtoken ${apiKey}`,
        },
      });

      if (response.data.users?.length > 0) {
        return { success: true, message: `Connexion Zoho réussie (${response.data.users[0].full_name})` };
      }
      return { success: false, message: 'Erreur de connexion Zoho' };
    } catch (error) {
      const message = error.response?.data?.message || error.message;
      return { success: false, message: `Erreur Zoho: ${message}` };
    }
  },

  /**
   * Create or update a contact in Zoho CRM
   */
  async syncContact(apiKey, apiUrl = 'https://www.zohoapis.eu', contact) {
    try {
      // Search for existing contact by email
      let existingContactId = null;

      if (contact.email) {
        try {
          const searchResponse = await axios.get(
            `${apiUrl}/crm/v2/Contacts/search?email=${encodeURIComponent(contact.email)}`,
            {
              headers: {
                'Authorization': `Zoho-oauthtoken ${apiKey}`,
              },
            }
          );

          if (searchResponse.data.data?.length > 0) {
            existingContactId = searchResponse.data.data[0].id;
          }
        } catch (e) {
          // Contact not found
        }
      }

      const contactData = {
        data: [{
          Email: contact.email || '',
          First_Name: contact.firstName || '',
          Last_Name: contact.lastName || 'Inconnu',
          Phone: contact.phone || contact.mobile || '',
          Title: contact.jobTitle || '',
          Mailing_Street: contact.address || '',
          Description: contact.bio || '',
        }],
        trigger: ['workflow'],
      };

      // Add company as Account
      if (contact.company) {
        contactData.data[0].Account_Name = contact.company;
      }

      let response;
      if (existingContactId) {
        // Update existing contact
        contactData.data[0].id = existingContactId;
        response = await axios.put(
          `${apiUrl}/crm/v2/Contacts`,
          contactData,
          {
            headers: {
              'Authorization': `Zoho-oauthtoken ${apiKey}`,
              'Content-Type': 'application/json',
            },
          }
        );
      } else {
        // Create new contact
        response = await axios.post(
          `${apiUrl}/crm/v2/Contacts`,
          contactData,
          {
            headers: {
              'Authorization': `Zoho-oauthtoken ${apiKey}`,
              'Content-Type': 'application/json',
            },
          }
        );
      }

      const result = response.data.data?.[0];
      return {
        success: result?.status === 'success',
        contactId: result?.details?.id || existingContactId,
        action: existingContactId ? 'updated' : 'created',
      };
    } catch (error) {
      const message = error.response?.data?.message || error.message;
      return { success: false, message: `Erreur Zoho: ${message}` };
    }
  },
};

// ==================== NOTION ====================

const NotionIntegration = {
  name: 'notion',

  /**
   * Test connection to Notion API
   * apiKey = integration token, apiUrl = database ID
   */
  async testConnection(apiKey, databaseId) {
    try {
      if (!databaseId) {
        return { success: false, message: 'ID de base de données Notion requis' };
      }

      const notion = new NotionClient({ auth: apiKey });
      const database = await notion.databases.retrieve({ database_id: databaseId });

      return {
        success: true,
        message: `Connexion Notion réussie (${database.title?.[0]?.plain_text || 'Base de données'})`
      };
    } catch (error) {
      return { success: false, message: `Erreur Notion: ${error.message}` };
    }
  },

  /**
   * Create a page in Notion database
   */
  async syncContact(apiKey, databaseId, contact) {
    try {
      if (!databaseId) {
        return { success: false, message: 'ID de base de données Notion requis' };
      }

      const notion = new NotionClient({ auth: apiKey });

      // Get database schema to understand properties
      const database = await notion.databases.retrieve({ database_id: databaseId });
      const props = database.properties;

      // Build properties based on available columns
      const properties = {};

      // Try to match common property names
      const addProperty = (possibleNames, value, type = 'rich_text') => {
        if (!value) return;

        for (const name of possibleNames) {
          const prop = Object.keys(props).find(k => k.toLowerCase() === name.toLowerCase());
          if (prop) {
            if (props[prop].type === 'title') {
              properties[prop] = { title: [{ text: { content: value } }] };
            } else if (props[prop].type === 'email') {
              properties[prop] = { email: value };
            } else if (props[prop].type === 'phone_number') {
              properties[prop] = { phone_number: value };
            } else if (props[prop].type === 'url') {
              properties[prop] = { url: value };
            } else if (props[prop].type === 'rich_text') {
              properties[prop] = { rich_text: [{ text: { content: value } }] };
            }
            break;
          }
        }
      };

      // Map contact fields to Notion properties
      const fullName = `${contact.firstName || ''} ${contact.lastName || ''}`.trim();
      addProperty(['name', 'nom', 'title', 'titre', 'contact'], fullName || 'Contact');
      addProperty(['email', 'e-mail', 'mail'], contact.email);
      addProperty(['phone', 'téléphone', 'telephone', 'tel'], contact.phone || contact.mobile);
      addProperty(['company', 'entreprise', 'société', 'societe', 'organisation'], contact.company);
      addProperty(['job', 'job title', 'titre', 'fonction', 'poste', 'position'], contact.jobTitle);
      addProperty(['website', 'site', 'site web', 'url'], contact.website);
      addProperty(['address', 'adresse'], contact.address);
      addProperty(['first name', 'prénom', 'prenom', 'firstname'], contact.firstName);
      addProperty(['last name', 'nom de famille', 'lastname'], contact.lastName);

      // Ensure we have at least a title property
      const titleProp = Object.keys(props).find(k => props[k].type === 'title');
      if (titleProp && !properties[titleProp]) {
        properties[titleProp] = { title: [{ text: { content: fullName || 'Contact' } }] };
      }

      const page = await notion.pages.create({
        parent: { database_id: databaseId },
        properties,
      });

      return {
        success: true,
        contactId: page.id,
        action: 'created',
      };
    } catch (error) {
      return { success: false, message: `Erreur Notion: ${error.message}` };
    }
  },
};

// ==================== AIRTABLE ====================

const AirtableIntegration = {
  name: 'airtable',

  /**
   * Test connection to Airtable API
   * apiKey = personal access token, apiUrl = base ID/table name (format: appXXXX/TableName)
   */
  async testConnection(apiKey, baseConfig) {
    try {
      if (!baseConfig || !baseConfig.includes('/')) {
        return { success: false, message: 'Format requis: baseId/tableName (ex: appABC123/Contacts)' };
      }

      const [baseId, tableName] = baseConfig.split('/');

      Airtable.configure({ apiKey });
      const base = Airtable.base(baseId);

      // Try to fetch one record to test connection
      const records = await base(tableName).select({ maxRecords: 1 }).firstPage();

      return { success: true, message: `Connexion Airtable réussie (${tableName})` };
    } catch (error) {
      return { success: false, message: `Erreur Airtable: ${error.message}` };
    }
  },

  /**
   * Create a record in Airtable
   */
  async syncContact(apiKey, baseConfig, contact) {
    try {
      if (!baseConfig || !baseConfig.includes('/')) {
        return { success: false, message: 'Format requis: baseId/tableName' };
      }

      const [baseId, tableName] = baseConfig.split('/');

      Airtable.configure({ apiKey });
      const base = Airtable.base(baseId);

      // Get table schema
      const records = await base(tableName).select({ maxRecords: 1 }).firstPage();

      // Build fields - Airtable is flexible with field names
      const fields = {};

      // Common field mappings
      const fullName = `${contact.firstName || ''} ${contact.lastName || ''}`.trim();

      // Try common field names
      fields['Name'] = fullName || 'Contact';
      fields['Nom'] = fullName || 'Contact';

      if (contact.email) {
        fields['Email'] = contact.email;
        fields['E-mail'] = contact.email;
      }
      if (contact.phone || contact.mobile) {
        fields['Phone'] = contact.phone || contact.mobile;
        fields['Téléphone'] = contact.phone || contact.mobile;
      }
      if (contact.company) {
        fields['Company'] = contact.company;
        fields['Entreprise'] = contact.company;
      }
      if (contact.jobTitle) {
        fields['Job Title'] = contact.jobTitle;
        fields['Fonction'] = contact.jobTitle;
      }
      if (contact.website) {
        fields['Website'] = contact.website;
        fields['Site Web'] = contact.website;
      }
      if (contact.address) {
        fields['Address'] = contact.address;
        fields['Adresse'] = contact.address;
      }
      if (contact.firstName) {
        fields['First Name'] = contact.firstName;
        fields['Prénom'] = contact.firstName;
      }
      if (contact.lastName) {
        fields['Last Name'] = contact.lastName;
        fields['Nom de famille'] = contact.lastName;
      }

      const record = await base(tableName).create(fields, { typecast: true });

      return {
        success: true,
        contactId: record.id,
        action: 'created',
      };
    } catch (error) {
      return { success: false, message: `Erreur Airtable: ${error.message}` };
    }
  },
};

// ==================== WEBHOOK ====================

const WebhookIntegration = {
  name: 'webhook',

  /**
   * Test webhook connection
   */
  async testConnection(apiKey, webhookUrl) {
    try {
      if (!webhookUrl) {
        return { success: false, message: 'URL du webhook requise' };
      }

      // Send a test payload
      const response = await axios.post(webhookUrl, {
        event: 'test',
        timestamp: new Date().toISOString(),
        message: 'Test de connexion Cards Control',
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey ? `Bearer ${apiKey}` : undefined,
          'X-Cards-Control-Event': 'test',
        },
        timeout: 10000,
      });

      return {
        success: true,
        message: `Webhook accessible (status: ${response.status})`
      };
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        return { success: false, message: 'Webhook inaccessible (connexion refusée)' };
      }
      if (error.code === 'ENOTFOUND') {
        return { success: false, message: 'URL du webhook invalide' };
      }
      // Some webhooks return non-2xx but still work
      if (error.response) {
        return {
          success: true,
          message: `Webhook accessible (status: ${error.response.status})`
        };
      }
      return { success: false, message: `Erreur Webhook: ${error.message}` };
    }
  },

  /**
   * Send contact data to webhook
   */
  async syncContact(apiKey, webhookUrl, contact) {
    try {
      if (!webhookUrl) {
        return { success: false, message: 'URL du webhook requise' };
      }

      const payload = {
        event: 'contact.created',
        timestamp: new Date().toISOString(),
        data: {
          firstName: contact.firstName || '',
          lastName: contact.lastName || '',
          email: contact.email || '',
          phone: contact.phone || '',
          mobile: contact.mobile || '',
          company: contact.company || '',
          jobTitle: contact.jobTitle || '',
          website: contact.website || '',
          address: contact.address || '',
          bio: contact.bio || '',
          source: contact.source || 'cards_control',
        },
      };

      const response = await axios.post(webhookUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey ? `Bearer ${apiKey}` : undefined,
          'X-Cards-Control-Event': 'contact.created',
        },
        timeout: 30000,
      });

      return {
        success: true,
        contactId: response.data?.id || 'webhook_sent',
        action: 'sent',
      };
    } catch (error) {
      return { success: false, message: `Erreur Webhook: ${error.message}` };
    }
  },
};

// ==================== MAIN EXPORTS ====================

const integrations = {
  hubspot: HubSpotIntegration,
  salesforce: SalesforceIntegration,
  pipedrive: PipedriveIntegration,
  zoho: ZohoIntegration,
  notion: NotionIntegration,
  airtable: AirtableIntegration,
  webhook: WebhookIntegration,
};

/**
 * Get integration by name
 */
function getIntegration(name) {
  return integrations[name] || null;
}

/**
 * Test connection for any integration
 */
async function testConnection(provider, apiKey, apiUrl) {
  const integration = getIntegration(provider);
  if (!integration) {
    return { success: false, message: `Intégration inconnue: ${provider}` };
  }
  return await integration.testConnection(apiKey, apiUrl);
}

/**
 * Sync contact to any integration
 */
async function syncContact(provider, apiKey, apiUrl, contact) {
  const integration = getIntegration(provider);
  if (!integration) {
    return { success: false, message: `Intégration inconnue: ${provider}` };
  }

  // Handle different parameter signatures
  if (provider === 'hubspot' || provider === 'pipedrive') {
    return await integration.syncContact(apiKey, contact);
  } else {
    return await integration.syncContact(apiKey, apiUrl, contact);
  }
}

module.exports = {
  integrations,
  getIntegration,
  testConnection,
  syncContact,
  HubSpotIntegration,
  SalesforceIntegration,
  PipedriveIntegration,
  ZohoIntegration,
  NotionIntegration,
  AirtableIntegration,
  WebhookIntegration,
};
