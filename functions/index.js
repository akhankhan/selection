const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
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

/**
 * When a user submits a store request, push a web notification to every admin
 * device that registered an FCM token (works when the tab is minimized).
 */
exports.notifyAdminsOnStoreRequest = onDocumentCreated(
  {
    document: 'store_requests/{requestId}',
    region: 'us-central1',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    if (data.status !== 'pending') return;

    const storeName = String(data.storeName || 'Unknown store').trim();
    const location = String(data.location || 'Unknown location').trim();
    const title = 'New store request';
    const body = `${storeName} · ${location}`;

    const db = getFirestore();
    const tokens = new Set();

    const devicesSnap = await db.collection('admin_devices').get();
    for (const doc of devicesSnap.docs) {
      const token = doc.data().fcmToken;
      if (typeof token === 'string' && token.length > 0) {
        tokens.add(token);
      }
    }

    const adminsSnap = await db.collection('admins').get();
    for (const doc of adminsSnap.docs) {
      const token = doc.data().fcmToken;
      if (typeof token === 'string' && token.length > 0) {
        tokens.add(token);
      }
    }

    const tokenList = [...tokens];

    if (tokenList.length === 0) {
      logger.info('No admin FCM tokens for store request alert', {
        requestId: event.params.requestId,
      });
      return;
    }

    const messaging = getMessaging();
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokenList.length; i += BATCH_SIZE) {
      const chunk = tokenList.slice(i, i + BATCH_SIZE);
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        data: {
          type: 'store_request',
          title,
          body,
          requestId: event.params.requestId,
          storeName,
          location,
        },
        webpush: {
          headers: { Urgency: 'high' },
          notification: {
            title,
            body,
            icon: 'https://menu2go-fb7de.web.app/icons/admin-notification-192.png',
          },
          fcmOptions: {
            link: 'https://menu2go-fb7de.web.app/',
          },
        },
      });
      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((result, index) => {
        if (result.success) return;
        const failedToken = chunk[index];
        logger.warn('Admin push token failed', {
          error: result.error?.message,
          tokenPrefix: failedToken.slice(0, 12),
        });
        if (
          result.error?.code === 'messaging/invalid-registration-token' ||
          result.error?.code === 'messaging/registration-token-not-registered'
        ) {
          db.collection('admin_devices')
            .where('fcmToken', '==', failedToken)
            .get()
            .then((snap) => {
              snap.docs.forEach((doc) =>
                doc.ref.update({
                  fcmToken: FieldValue.delete(),
                  updatedAt: FieldValue.serverTimestamp(),
                }),
              );
            })
            .catch(() => {});
        }
      });
    }

    logger.info('Admin store-request push sent', {
      requestId: event.params.requestId,
      recipientCount: tokenList.length,
      successCount,
      failureCount,
    });
  },
);

/**
 * When admin approves or rejects a store request, notify the user who submitted it.
 */
exports.notifyUserOnStoreRequestReview = onDocumentUpdated(
  {
    document: 'store_requests/{requestId}',
    region: 'us-central1',
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== 'approved' && after.status !== 'rejected') return;

    const userId = after.userId;
    if (typeof userId !== 'string' || userId.length === 0) {
      logger.info('Store request review without userId — skipping user notify', {
        requestId: event.params.requestId,
        status: after.status,
      });
      return;
    }

    const storeName = String(after.storeName || 'your store').trim();
    const isApproved = after.status === 'approved';
    const title = isApproved ? 'Store request approved' : 'Store request update';
    const body = isApproved
      ? `Great news! "${storeName}" was approved by our team.`
      : `Your request for "${storeName}" was reviewed.`;

    const db = getFirestore();

    await db.collection('user_notifications').add({
      userId,
      type: 'store_request_review',
      title,
      body,
      storeRequestId: event.params.requestId,
      status: after.status,
      storeName,
      createdAt: FieldValue.serverTimestamp(),
    });

    const userSnap = await db.collection('users').doc(userId).get();
    if (!userSnap.exists) return;

    const user = userSnap.data() || {};
    if (user.notificationsEnabled === false) return;

    const token = user.fcmToken;
    if (typeof token !== 'string' || token.length === 0) {
      logger.info('No FCM token for store request review notify', { userId });
      return;
    }

    try {
      await getMessaging().send({
        token,
        notification: { title, body },
        data: {
          type: 'store_request_review',
          requestId: event.params.requestId,
          status: after.status,
          storeName,
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
      logger.info('User store-request review push sent', {
        requestId: event.params.requestId,
        userId,
        status: after.status,
      });
    } catch (err) {
      logger.error('User store-request review push failed', {
        requestId: event.params.requestId,
        userId,
        error: String(err.message || err),
      });
    }
  },
);
