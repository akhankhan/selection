import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/models/app_notification.dart';

class NotificationInboxStore extends ChangeNotifier {
  NotificationInboxStore._();

  static final NotificationInboxStore instance = NotificationInboxStore._();

  static const _lastSeenKey = 'notification_inbox_last_seen_ms';
  static const _pendingKey = 'notification_inbox_pending_count';

  DateTime? _lastSeenAt;
  int _pendingCount = 0;

  DateTime? get lastSeenAt => _lastSeenAt;
  int get pendingCount => _pendingCount;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenMs = prefs.getInt(_lastSeenKey);
    _lastSeenAt =
        lastSeenMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
    _pendingCount = prefs.getInt(_pendingKey) ?? 0;
    notifyListeners();
  }

  int unreadCountFor(List<AppNotification> notifications) {
    final baseline = _lastSeenAt;
    final fromFeed = baseline == null
        ? notifications.length
        : notifications
            .where(
              (n) => n.sentAt != null && n.sentAt!.isAfter(baseline),
            )
            .length;
    return fromFeed + _pendingCount;
  }

  Future<void> markInboxSeen(List<AppNotification> notifications) async {
    _lastSeenAt = DateTime.now();
    _pendingCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSeenKey, _lastSeenAt!.millisecondsSinceEpoch);
    await prefs.setInt(_pendingKey, 0);
    notifyListeners();
  }

  Future<void> registerIncomingNotification() async {
    _pendingCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pendingKey, _pendingCount);
    notifyListeners();
  }
}
