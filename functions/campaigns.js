const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

const db = admin.firestore();

// Initialize Twilio client (lazy load or init inside function to avoid errors if env vars missing)
const getTwilioClient = () => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID || functions.config().twilio?.sid;
  const authToken = process.env.TWILIO_AUTH_TOKEN || functions.config().twilio?.token;
  if (!accountSid || !authToken) {
    throw new Error('Twilio credentials missing. Set them via env vars or firebase functions:config:set twilio.sid="..." twilio.token="..."');
  }
  return twilio(accountSid, authToken);
};

const replaceVariables = (content, contact) => {
  let text = content;
  text = text.replace(/{firstName}/g, contact.firstName || '');
  text = text.replace(/{lastName}/g, contact.lastName || '');
  return text;
};

exports.processCampaign = functions.firestore
  .document('users/{userId}/campaigns/{campaignId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    // Only trigger if status changed to 'sending'
    if (newData.status !== 'sending' || previousData.status === 'sending') {
      return null;
    }

    try {
      // 1. Fetch Recipients
      let recipients = [];
      const contactsRef = db.collection(`users/${userId}/scanned_contacts`);

      if (targetType === 'all') {
        const snapshot = await contactsRef.get();
        recipients = snapshot.docs.map(doc => doc.data());
      } else if (targetType === 'category' && targetCategoryId) {
        const snapshot = await contactsRef.where('categoryId', '==', targetCategoryId).get();
        recipients = snapshot.docs.map(doc => doc.data());
      }

      console.log(`Found ${recipients.length} recipients`);

      // Credit Check (moved here after counting recipients)
      if (type === 'sms') {
        const currentCredits = userData.credits || 0;
        const cost = recipients.length; // 1 credit per SMS

        if (currentCredits < cost) {
          throw new Error(`Crédits insuffisants. Requis: ${cost}, Disponible: ${currentCredits}`);
        }

        // Deduct credits immediately (optimistic) or after?
        // Let's deduct after successful sends to be fair, OR deduct all upfront and refund failures.
        // For simplicity: Check upfront, deduct actual success count later.
        // BETTER: Deduct upfront to prevent abuse, then refund if needed.
        // SIMPLEST START: Check upfront, deduct success count at the end.
        if (currentCredits < cost) {
           await change.after.ref.update({
            status: 'failed',
            error: `Crédits insuffisants. Requis: ${cost}, Disponible: ${currentCredits}`
          });
          return;
        }
      }

      // 2. Process Sending
      let successCount = 0;
      let failureCount = 0;

      if (type === 'sms') {
        const client = getTwilioClient();
        const fromNumber = process.env.TWILIO_FROM_NUMBER || functions.config().twilio?.from;

        const promises = recipients.map(async (contact) => {
          if (!contact.phone) return; // Skip if no phone
          try {
            const personalizedBody = replaceVariables(`${senderName}: ${content}`, contact);
            await client.messages.create({
              body: personalizedBody,
              from: fromNumber,
              to: contact.phone
            });
            successCount++;
          } catch (error) {
            console.error(`Failed to send SMS to ${contact.phone}:`, error);
            failureCount++;
          }
        });
        await Promise.all(promises);

      } else if (type === 'email') {
        // Use Firebase Email Extension pattern (write to 'mail' collection)
        // Assuming the extension is configured to listen to 'mail' collection
        const mailCollection = db.collection('mail');

        const promises = recipients.map(async (contact) => {
          if (!contact.email) return; // Skip if no email
          try {
            const personalizedContent = replaceVariables(content, contact);
            await mailCollection.add({
              to: contact.email,
              message: {
                subject: subject,
                text: personalizedContent,
                html: personalizedContent.replace(/\n/g, '<br>'),
                from: `${senderName} via Cards Control <noreply@cards-control.app>`,
                replyTo: senderEmail
              },
              metadata: {
                campaignId: campaignId,
                userId: userId
              }
            });
            successCount++;
          } catch (error) {
            console.error(`Failed to queue email for ${contact.email}:`, error);
            failureCount++;
          }
        });
        await Promise.all(promises);
      }

      // 3. Update Campaign Status & Deduct Credits
      const updates = {
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        stats: {
          delivered: successCount,
          failed: failureCount,
          opened: 0,
          clicked: 0
        }
      };

      await change.after.ref.update(updates);

      // Deduct credits for SMS
      if (type === 'sms' && successCount > 0) {
        await userDocRef.update({
          credits: admin.firestore.FieldValue.increment(-successCount)
        });
        console.log(`Deducted ${successCount} credits from user ${userId}`);
      }

      console.log(`Campaign ${campaignId} completed. Success: ${successCount}, Failed: ${failureCount}`);

    } catch (error) {
      console.error('Error processing campaign:', error);
      await change.after.ref.update({
        status: 'failed',
        error: error.message
      });
    }
  });
