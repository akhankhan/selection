import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  Stream<List<AppNotification>> watchInbox() {
    final controller = StreamController<List<AppNotification>>.broadcast();
    var broadcasts = const <AppNotification>[];
    var personal = const <AppNotification>[];

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = [...personal, ...broadcasts]
        ..sort(
          (a, b) => (b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      controller.add(merged);
    }

    final broadcastSub = watchSentNotifications().listen(
      (items) {
        broadcasts = items;
        emitMerged();
      },
      onError: controller.addError,
    );
    final personalSub = watchUserNotifications().listen(
      (items) {
        personal = items;
        emitMerged();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await broadcastSub.cancel();
      await personalSub.cancel();
    };

    return controller.stream;
  }

  Stream<List<AppNotification>> watchSentNotifications() {
    return FirebaseFirestore.instance
        .collection('notification_broadcasts')
        .where('status', isEqualTo: 'sent')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(_fromBroadcastDoc)
          .whereType<AppNotification>()
          .toList()
        ..sort(
          (a, b) => (b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      return items;
    });
  }

  Stream<List<AppNotification>> watchUserNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return FirebaseFirestore.instance
        .collection('user_notifications')
        .where('userId', isEqualTo: uid)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(_fromUserDoc)
          .whereType<AppNotification>()
          .toList()
        ..sort(
          (a, b) => (b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      return items;
    });
  }

  AppNotification? _fromBroadcastDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = (data['title'] as String?)?.trim() ?? '';
    final body = (data['body'] as String?)?.trim() ?? '';
    if (title.isEmpty && body.isEmpty) return null;

    final sentAt = _toDate(data['processedAt']) ?? _toDate(data['createdAt']);

    return AppNotification(
      id: doc.id,
      title: title,
      body: body,
      sentAt: sentAt,
    );
  }

  AppNotification? _fromUserDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = (data['title'] as String?)?.trim() ?? '';
    final body = (data['body'] as String?)?.trim() ?? '';
    if (title.isEmpty && body.isEmpty) return null;

    return AppNotification(
      id: doc.id,
      title: title,
      body: body,
      sentAt: _toDate(data['createdAt']),
    );
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
