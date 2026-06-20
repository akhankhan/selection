import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/legal_documents_service.dart';
import '../../../core/storage/auto_delete_preferences_store.dart';
import '../../../core/storage/notification_preferences_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../browse/services/search_history_service.dart';
import '../../lists/models/shopping_list_manager.dart';
import '../services/push_notification_service.dart';
import 'signin_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_choices_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _brandBlue = AppTheme.brandBlue;

  bool _acceptNotifications = true;
  AutoDeleteExpiredPolicy _autoDeletePolicy = AutoDeleteExpiredPolicy.never;

  @override
  void initState() {
    super.initState();
    NotificationPreferencesStore.instance.load().then((_) {
      if (mounted) {
        setState(() {
          _acceptNotifications = NotificationPreferencesStore.instance.enabled;
        });
      }
    });
    AutoDeletePreferencesStore.instance.load().then((_) {
      if (mounted) {
        setState(() {
          _autoDeletePolicy = AutoDeletePreferencesStore.instance.policy;
        });
      }
    });
    NotificationPreferencesStore.instance.addListener(_onNotificationPrefChanged);
    AutoDeletePreferencesStore.instance.addListener(_onAutoDeleteChanged);
  }

  void _onAutoDeleteChanged() {
    if (mounted) {
      setState(() {
        _autoDeletePolicy = AutoDeletePreferencesStore.instance.policy;
      });
    }
  }

  void _onNotificationPrefChanged() {
    if (mounted) {
      setState(() {
        _acceptNotifications = NotificationPreferencesStore.instance.enabled;
      });
    }
  }

  @override
  void dispose() {
    NotificationPreferencesStore.instance.removeListener(_onNotificationPrefChanged);
    AutoDeletePreferencesStore.instance.removeListener(_onAutoDeleteChanged);
    super.dispose();
  }

  void _openLegalDocument(LegalDocumentType type) {
    LegalDocumentsService.instance.open(context, type);
  }

  void _openAppSettings() {
    launchUrl(Uri.parse('app-settings:'));
  }

  void _showThemePicker() {
    final currentTheme = ThemeController.instance.label;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Select Theme',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: RadioGroup<String>(
            groupValue: currentTheme,
            onChanged: (value) async {
              if (value == null) return;
              await ThemeController.instance.setPreference(
                AppThemePreference.fromLabel(value),
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppThemePreference.values.map((theme) {
                return ListTile(
                  title: Text(theme.label),
                  leading: Radio<String>(
                    value: theme.label,
                    activeColor: _brandBlue,
                  ),
                  onTap: () async {
                    await ThemeController.instance.setPreference(theme);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showAutoDeletePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Auto Delete Expired Items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: RadioGroup<AutoDeleteExpiredPolicy>(
            groupValue: _autoDeletePolicy,
            onChanged: (value) async {
              if (value == null) return;
              await AutoDeletePreferencesStore.instance.setPolicy(value);
              final removed = ShoppingListManager.instance.purgeExpiredByPolicy(value);
              if (!context.mounted) return;
              setState(() => _autoDeletePolicy = value);
              Navigator.pop(context);
              if (removed > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed $removed expired item${removed == 1 ? '' : 's'}.'),
                    backgroundColor: _brandBlue,
                  ),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AutoDeleteExpiredPolicy.values.map((policy) {
                return ListTile(
                  title: Text(policy.label),
                  leading: Radio<AutoDeleteExpiredPolicy>(
                    value: policy,
                    activeColor: _brandBlue,
                  ),
                  onTap: () async {
                    await AutoDeletePreferencesStore.instance.setPolicy(policy);
                    final removed =
                        ShoppingListManager.instance.purgeExpiredByPolicy(policy);
                    if (!context.mounted) return;
                    setState(() => _autoDeletePolicy = policy);
                    Navigator.pop(context);
                    if (removed > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Removed $removed expired item${removed == 1 ? '' : 's'}.',
                          ),
                          backgroundColor: _brandBlue,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _confirmClear(String title, String message, {Future<void> Function()? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await onConfirm?.call();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title Cleared Successfully!'),
                    backgroundColor: _brandBlue,
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMockPage(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _brandBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This is a placeholder page for the dynamic $title document.\n\n'
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
                    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
                    'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: theme.dividerColor),
            ),
          ),
          body: ListView(
            children: [
          // My Account Section
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryHeader('My Account'),
                    _buildTile(
                      title: 'Sign In or Create Account',
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SignInScreen(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryHeader('My Account'),
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _brandBlue.withValues(
                                  alpha: 0.1,
                                ),
                                backgroundImage: user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
                                    ? Text(
                                        (user.displayName ??
                                                user.email ??
                                                'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: _brandBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName ?? 'User',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildTile(
                      title: 'Sign Out',
                      subtitle: 'Sign out of your MENU2GO account',
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        try {
                          await GoogleSignIn.instance.signOut();
                        } catch (e) {
                          debugPrint('Google Sign In sign out error: $e');
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully signed out!'),
                              backgroundColor: _brandBlue,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              }
            },
          ),

          // Preferences Section
          _buildCategoryHeader('Preferences'),
          _buildCheckboxTile(
            title: 'Accept Push Notifications',
            subtitle:
                'Allow MENU2GO to notify you of the latest deals in your area',
            value: _acceptNotifications,
            onChanged: (val) async {
              final result =
                  await NotificationPreferencesStore.instance.setEnabled(val);
              if (!context.mounted) return;
              setState(() {
                _acceptNotifications =
                    NotificationPreferencesStore.instance.enabled;
              });

              if (val && result != null) {
                final messenger = ScaffoldMessenger.of(context);
                switch (result.status) {
                  case PushRegistrationStatus.permissionDenied:
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ??
                              'Notification permission was denied.',
                        ),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'Settings',
                          textColor: Colors.white,
                          onPressed: _openAppSettings,
                        ),
                      ),
                    );
                  case PushRegistrationStatus.apnsPending:
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ??
                              'Notifications enabled. Token will register when the device is ready.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  case PushRegistrationStatus.success:
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Push notifications enabled. You\'ll receive deal alerts for your area.',
                        ),
                        backgroundColor: _brandBlue,
                      ),
                    );
                  case PushRegistrationStatus.failed:
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ?? 'Could not enable notifications.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                }
              }
            },
          ),
          _buildDivider(),
          _buildTile(
            title: 'Theme',
            subtitle: ThemeController.instance.label,
            onTap: _showThemePicker,
          ),
          _buildDivider(),
          _buildTile(
            title: 'Clear Search History',
            subtitle: 'Remove all saved search terms',
            onTap: () => _confirmClear(
              'Search History',
              'Are you sure you want to clear your search history?',
              onConfirm: SearchHistoryService.instance.clear,
            ),
          ),

          // Legal Section
          _buildCategoryHeader('Legal'),
          _buildTile(
            title: 'Terms Of Service',
            onTap: () => _openLegalDocument(LegalDocumentType.termsOfService),
          ),
          _buildDivider(),
          _buildTile(
            title: 'Enhanced Notice',
            onTap: () => _openLegalDocument(LegalDocumentType.enhancedNotice),
          ),
          _buildDivider(),
          _buildTile(
            title: 'Privacy Policy',
            onTap: () => _openLegalDocument(LegalDocumentType.privacyPolicy),
          ),

          // Shopping List Section
          _buildCategoryHeader('Shopping List'),
          _buildTile(
            title: 'Clear Shopping List History',
            subtitle: 'Remove all prior items from recommendations',
            onTap: () => _confirmClear(
              'Shopping List History',
              'Are you sure you want to clear your shopping list history? This action is irreversible.',
              onConfirm: () async {
                ShoppingListManager.instance.deleteAll();
                await ShoppingListManager.instance.clearHistory();
              },
            ),
          ),
          _buildDivider(),
          _buildTile(
            title: 'Auto Delete Expired Shopping List Items',
            subtitle: _autoDeletePolicy.label,
            onTap: _showAutoDeletePicker,
          ),

          // Version Section
          _buildCategoryHeader('Version'),
          _buildTile(title: '97.1.0', enabled: false),

          // Contact Us Section
          _buildCategoryHeader('Contact Us'),
          _buildTile(
            title: 'Privacy Choices',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyChoicesScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildTile(
            title: 'Share your feedback',
            onTap: () => _showMockPage('Share your feedback'),
          ),
          const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _brandBlue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 16,
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: value,
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
                activeColor: _brandBlue,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
