const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');

initializeApp();

const BATCH_SIZE = 500;

/**
 * When admin queues a row in `notification_broadcasts`, send FCM to all
 * users with a registered token and notifications enabled.
 */
exports.deliverNotificationBroadcast = onDocumentCreated(
  {
    document: 'notification_broadcasts/{broadcastId}',
    region: 'us-central1',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    if (data.status !== 'queued') return;

    const db = getFirestore();
    const broadcastRef = snap.ref;
    const title = String(data.title || '').trim();
    const body = String(data.body || '').trim();

    if (!title || !body) {
      await broadcastRef.update({
        status: 'failed',
        error: 'Missing title or body',
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      const usersSnap = await db.collection('users').get();
      const tokens = [];

      for (const doc of usersSnap.docs) {
        const user = doc.data();
        if (user.notificationsEnabled === false) continue;
        const token = user.fcmToken;
        if (typeof token === 'string' && token.length > 0) {
          tokens.push(token);
        }
      }

      if (tokens.length === 0) {
        await broadcastRef.update({
          status: 'sent',
          recipientCount: 0,
          successCount: 0,
          failureCount: 0,
          note: 'No registered FCM tokens',
          processedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const messaging = getMessaging();
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const chunk = tokens.slice(i, i + BATCH_SIZE);
        const response = await messaging.sendEachForMulticast({
          tokens: chunk,
          notification: { title, body },
          data: {
            type: 'broadcast',
            broadcastId: event.params.broadcastId,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'menu2go_alerts',
              icon: 'ic_stat_menu2go',
              color: '#EC3090',
            },
          },
        });
        successCount += response.successCount;
        failureCount += response.failureCount;
      }

      await broadcastRef.update({
        status: 'sent',
        recipientCount: tokens.length,
        successCount,
        failureCount,
        processedAt: FieldValue.serverTimestamp(),
      });

      logger.info('Broadcast sent', {
        broadcastId: event.params.broadcastId,
        recipientCount: tokens.length,
        successCount,
        failureCount,
      });
    } catch (err) {
      logger.error('Broadcast failed', err);
      await broadcastRef.update({
        status: 'failed',
        error: String(err.message || err),
        processedAt: FieldValue.serverTimestamp(),
      });
    }
  },
);
