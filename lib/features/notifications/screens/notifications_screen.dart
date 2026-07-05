import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/notification_inbox_store.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../settings/services/push_notification_service.dart';
import '../data/notification_repository.dart';
import '../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final snap =
          await NotificationRepository.instance.watchInbox().first;
      if (mounted) {
        await NotificationInboxStore.instance.markInboxSeen(snap);
      }
    });
  }

  Future<void> _refreshInbox() async {
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _enableAlerts() async {
    await PushNotificationService.instance.schedulePermissionPromptWhenReady();
  }

  String _errorMessage(Object? error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Permission denied loading notifications. Pull to retry after updating the app.';
    }
    return 'Could not load notifications.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: appTheme.sectionBg,
      appBar: AppBar(
        backgroundColor: appTheme.headerSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: StreamBuilder<List<AppNotification>>(
          stream: NotificationRepository.instance.watchInbox(),
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: appTheme.navyText,
                    letterSpacing: -0.3,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count ${count == 1 ? 'alert' : 'alerts'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: appTheme.subtitle,
                    ),
                  ),
              ],
            );
          },
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationRepository.instance.watchInbox(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingList(appTheme: appTheme);
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: _errorMessage(snapshot.error),
              onRetry: () => setState(() {}),
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return EmptyStateView(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              message:
                  'When MENU2GO sends deal alerts, they will appear here.',
              actionLabel: 'Enable deal alerts',
              onAction: _enableAlerts,
            );
          }

          final sections = _groupByDate(items);

          return RefreshIndicator(
            color: context.brandBlue,
            onRefresh: _refreshInbox,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  _SectionHeader(
                    label: sections[i].label,
                    appTheme: appTheme,
                  ),
                  const SizedBox(height: 8),
                  _NotificationGroup(
                    notifications: sections[i].items,
                    appTheme: appTheme,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateSection {
  const _DateSection({required this.label, required this.items});

  final String label;
  final List<AppNotification> items;
}

List<_DateSection> _groupByDate(List<AppNotification> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));

  final todayItems = <AppNotification>[];
  final yesterdayItems = <AppNotification>[];
  final weekItems = <AppNotification>[];
  final olderItems = <AppNotification>[];

  for (final item in items) {
    final sent = item.sentAt;
    if (sent == null) {
      olderItems.add(item);
      continue;
    }
    final day = DateTime(sent.year, sent.month, sent.day);
    if (day == today) {
      todayItems.add(item);
    } else if (day == yesterday) {
      yesterdayItems.add(item);
    } else if (day.isAfter(weekAgo)) {
      weekItems.add(item);
    } else {
      olderItems.add(item);
    }
  }

  final sections = <_DateSection>[];
  if (todayItems.isNotEmpty) {
    sections.add(_DateSection(label: 'Today', items: todayItems));
  }
  if (yesterdayItems.isNotEmpty) {
    sections.add(_DateSection(label: 'Yesterday', items: yesterdayItems));
  }
  if (weekItems.isNotEmpty) {
    sections.add(_DateSection(label: 'This week', items: weekItems));
  }
  if (olderItems.isNotEmpty) {
    sections.add(_DateSection(label: 'Earlier', items: olderItems));
  }
  return sections;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.appTheme});

  final String label;
  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: appTheme.subtitle,
        ),
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.notifications,
    required this.appTheme,
    required this.isDark,
  });

  final List<AppNotification> notifications;
  final AppThemeExtension appTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: appTheme.border.withValues(alpha: 0.55))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < notifications.length; i++) ...[
            _NotificationTile(
              notification: notifications[i],
              appTheme: appTheme,
              showDivider: i < notifications.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.appTheme,
    required this.showDivider,
  });

  final AppNotification notification;
  final AppThemeExtension appTheme;
  final bool showDivider;

  static const _brandPink = Color(0xFFEC3090);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/branding/app_logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  color: appTheme.navyText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  height: 1.25,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (notification.sentAt != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatWhen(notification.sentAt!),
                                style: TextStyle(
                                  color: appTheme.subtitle,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appTheme.subtitle,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _brandPink,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'MENU2GO',
                              style: TextStyle(
                                color: _brandPink.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 1,
                indent: 66,
                color: appTheme.border.withValues(alpha: 0.7),
              ),
      ],
    );
  }

  static String _formatWhen(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[when.month - 1]} ${when.day}';
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({required this.appTheme});

  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SkeletonBlock(appTheme: appTheme, height: 14, width: 72),
        const SizedBox(height: 10),
        _SkeletonBlock(appTheme: appTheme, height: 88),
        const SizedBox(height: 18),
        _SkeletonBlock(appTheme: appTheme, height: 14, width: 88),
        const SizedBox(height: 10),
        _SkeletonBlock(appTheme: appTheme, height: 88),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.appTheme,
    required this.height,
    this.width,
  });

  final AppThemeExtension appTheme;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: appTheme.searchFill,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
