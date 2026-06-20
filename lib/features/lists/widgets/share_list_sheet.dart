import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../services/shopping_list_share_service.dart';
import '../services/shared_list_service.dart';
import '../widgets/join_shared_list_sheet.dart';
import '../../settings/widgets/sign_in_required_gate.dart';

class ShareListSheet extends StatelessWidget {
  const ShareListSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final signedIn = await ensureSignedIn(context);
    if (!signedIn || !context.mounted) return;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final appTheme = sheetContext.appTheme;

        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(sheetContext).size.height * 0.06,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: appTheme.cardSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: sheetContext.isDarkMode ? 0.45 : 0.12,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: const ShareListSheet(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return _buildSignedInContent(context, user);
  }

  Widget _buildSignedInContent(BuildContext context, User user) {
    final appTheme = context.appTheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(appTheme: appTheme),
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re ready to share',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: appTheme.navyText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Invite friends to collaborate on your shopping lists.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: appTheme.subtitle,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: appTheme.searchFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: appTheme.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: context.brandBlue.withValues(
                        alpha: 0.12,
                      ),
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              (user.displayName ?? user.email ?? 'U')[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                color: context.brandBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'User',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: appTheme.navyText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: appTheme.subtitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await SharedListService.instance.shareInviteLink();
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('StateError: ', ''),
                          ),
                          backgroundColor: context.brandBlue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.link_rounded, size: 20),
                  label: const Text(
                    'Share invite link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await JoinSharedListSheet.show(context);
                  },
                  icon: Icon(Icons.group_add_outlined, color: context.brandBlue),
                  label: Text(
                    'Join with invite code',
                    style: TextStyle(
                      color: context.brandBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.brandBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ShoppingListShareService.shareCurrentList();
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('StateError: ', ''),
                          ),
                          backgroundColor: context.brandBlue,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.ios_share_rounded, size: 20, color: context.brandBlue),
                  label: Text(
                    'Share list as text',
                    style: TextStyle(
                      color: context.brandBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.brandBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: context.brandBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.appTheme});

  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: appTheme.subtitle.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
