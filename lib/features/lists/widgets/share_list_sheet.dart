import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../services/shopping_list_share_service.dart';
import '../../settings/screens/email_signin_screen.dart';
import '../../settings/services/apple_sign_in_service.dart';
import '../../settings/widgets/legal_terms_footer.dart';

class ShareListSheet extends StatelessWidget {
  ShareListSheet({super.key});

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  static Future<void> show(BuildContext context) {
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
            child: ShareListSheet(),
          ),
        );
      },
    );
  }

  Future<void> _handleEmailSignIn(BuildContext context) async {
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EmailSignInScreen()),
    );

    if (signedIn == true && context.mounted) {
      final user = FirebaseAuth.instance.currentUser;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully signed in as ${user?.displayName ?? user?.email ?? "User"}!',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    final available = await AppleSignInService.isAvailable();
    if (!available) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Apple Sign-In is not available on this device.',
          ),
          backgroundColor: context.brandBlue,
        ),
      );
      return;
    }

    try {
      final result = await AppleSignInService.requestAppleCredentialWithNonce();

      if (!context.mounted) return;

      _isLoading.value = true;

      final userCredential = await AppleSignInService.signInWithFirebase(
        appleCredential: result.credential,
        rawNonce: result.rawNonce,
      );

      _isLoading.value = false;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully signed in as '
              '${userCredential.user?.displayName ?? userCredential.user?.email ?? "User"}!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      _isLoading.value = false;
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (context.mounted) {
        _showAppleErrorDialog(context, AppleSignInService.authErrorMessage(e));
      }
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      if (context.mounted) {
        _showAppleErrorDialog(context, AppleSignInService.authErrorMessage(e));
      }
    } catch (e) {
      _isLoading.value = false;
      if (context.mounted) {
        _showAppleErrorDialog(context, AppleSignInService.authErrorMessage(e));
      }
    }
  }

  void _showAppleErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Apple Sign-In Failed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'OK',
              style: TextStyle(
                color: dialogContext.brandBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleGoogleSignIn(BuildContext context) async {
    _isLoading.value = true;
    debugPrint('[Google Sign-In] Triggering GoogleSignIn.instance.authenticate()...');

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      debugPrint('[Google Sign-In] Authentication successful! User email: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      
      debugPrint('[Google Sign-In] Retreived ID Token: ${idToken != null ? "SUCCESS (length: ${idToken.length})" : "NULL"}');
      if (idToken == null) {
        throw Exception('Failed to retrieve Google ID Token.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      debugPrint('[Google Sign-In] Signing into Firebase with credential...');
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[Google Sign-In] Firebase Sign-In successful! User: ${userCredential.user?.displayName} (${userCredential.user?.email})');

      _isLoading.value = false;

      if (context.mounted) {
        Navigator.pop(context); // Dismiss ShareListSheet bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully signed in as ${userCredential.user?.displayName ?? "User"}!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      _isLoading.value = false;
      debugPrint('[Google Sign-In ERROR] Exception occurred during authentication flow: $e');
      debugPrint('[Google Sign-In ERROR] NOTE: If you get "No credentials available", you MUST add a Google account to your Android emulator settings (Settings -> Passwords & Accounts -> Add Account -> Google).');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: Colors.red[800],
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _buildSignedOutContent(context);
        } else {
          return _buildSignedInContent(context, user);
        }
      },
    );
  }

  Widget _buildSignedOutContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, child) {
        return Stack(
          children: [
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetHandle(appTheme: appTheme),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.brandBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.people_outline_rounded,
                              color: context.brandBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share your list',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: appTheme.navyText,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Shop together with friends & family',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: appTheme.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: appTheme.chipInactive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ShareHeroCard(appTheme: appTheme),
                      const SizedBox(height: 16),
                      _BenefitChip(
                        icon: Icons.checklist_rounded,
                        label: 'Merge lists in real time',
                        appTheme: appTheme,
                      ),
                      const SizedBox(height: 8),
                      _BenefitChip(
                        icon: Icons.notifications_active_outlined,
                        label: 'Get notified when items are added',
                        appTheme: appTheme,
                      ),
                      const SizedBox(height: 8),
                      _BenefitChip(
                        icon: Icons.devices_outlined,
                        label: 'Stay synced across all devices',
                        appTheme: appTheme,
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: appTheme.searchFill,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: context.brandBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Learn how list sharing works',
                                    style: TextStyle(
                                      color: appTheme.navyText,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: appTheme.subtitle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          icon: Icon(Icons.ios_share_rounded, color: context.brandBlue),
                          label: Text(
                            'Share list as text',
                            style: TextStyle(
                              color: context.brandBlue,
                              fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: appTheme.border, height: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: appTheme.subtitle,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: appTheme.border, height: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SocialButton(
                        label: 'Continue with Apple',
                        icon: Icon(
                          Icons.apple,
                          color: colorScheme.onSurface,
                          size: 24,
                        ),
                        onTap: () => _handleAppleSignIn(context),
                      ),
                      const SizedBox(height: 10),
                      _SocialButton(
                        label: 'Continue with Google',
                        icon: _GoogleIcon(),
                        onTap: () => _handleGoogleSignIn(context),
                      ),
                      const SizedBox(height: 10),
                      _SocialButton(
                        label: 'Continue with email',
                        icon: Icon(
                          Icons.mail_outline_rounded,
                          color: colorScheme.onSurface,
                          size: 22,
                        ),
                        onTap: () => _handleEmailSignIn(context),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(
                          'No thanks',
                          style: TextStyle(
                            color: context.brandBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const LegalTermsFooter(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: appTheme.cardSurface.withValues(alpha: 0.88),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.brandBlue,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
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
                      await ShoppingListShareService.shareCurrentList();
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceFirst('StateError: ', '')),
                          backgroundColor: context.brandBlue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  label: const Text(
                    'Share Shopping List',
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

class _ShareHeroCard extends StatelessWidget {
  const _ShareHeroCard({required this.appTheme});

  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    final brandBlue = context.brandBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandBlue.withValues(alpha: 0.18),
            brandBlue.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniListCard(appTheme: appTheme, label: 'Your list'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.sync_rounded,
              color: brandBlue,
              size: 28,
            ),
          ),
          _MiniListCard(appTheme: appTheme, label: 'Friend'),
        ],
      ),
    );
  }
}

class _MiniListCard extends StatelessWidget {
  const _MiniListCard({required this.appTheme, required this.label});

  final AppThemeExtension appTheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 72,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appTheme.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: appTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ListLine(appTheme: appTheme, checked: true),
              const SizedBox(height: 6),
              _ListLine(appTheme: appTheme, checked: true),
              const SizedBox(height: 6),
              _ListLine(appTheme: appTheme, checked: false),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: appTheme.subtitle,
          ),
        ),
      ],
    );
  }
}

class _ListLine extends StatelessWidget {
  const _ListLine({required this.appTheme, required this.checked});

  final AppThemeExtension appTheme;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: checked
                ? context.brandBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: checked ? context.brandBlue : appTheme.border,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: checked
              ? Icon(Icons.check, size: 7, color: context.brandBlue)
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: appTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({
    required this.icon,
    required this.label,
    required this.appTheme,
  });

  final IconData icon;
  final String label;
  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.brandBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: appTheme.navyText,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Material(
      color: appTheme.searchFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: appTheme.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: icon)),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: appTheme.navyText,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// class _FacebookIcon extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 24,
//       height: 24,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1877F2),
//         shape: BoxShape.circle,
//       ),
//       child: const Center(
//         child: Text(
//           'f',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w900,
//             height: 1,
//           ),
//         ),
//       ),
//     );
//   }
// }

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 20), painter: _GoogleIconPainter());
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / 24.0;
    final double scaleY = size.height / 24.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Blue Path (#4285F4)
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final Path bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..relativeCubicTo(0.0, -0.78, -0.07, -1.53, -0.2, -2.25)
      ..lineTo(12.0, 10.0)
      ..relativeLineTo(0.0, 4.26)
      ..relativeLineTo(5.92, 0.0)
      ..relativeCubicTo(-0.26, 1.37, -1.04, 2.53, -2.21, 3.31)
      ..relativeLineTo(0.0, 2.77)
      ..relativeLineTo(3.57, 0.0)
      ..relativeCubicTo(2.08, -1.92, 3.28, -4.74, 3.28, -8.09)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Path (#34A853)
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final Path greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..relativeCubicTo(2.97, 0.0, 5.46, -0.98, 7.28, -2.66)
      ..relativeLineTo(-3.57, -2.77)
      ..relativeCubicTo(-0.98, 0.66, -2.23, 1.06, -3.71, 1.06)
      ..relativeCubicTo(-2.86, 0.0, -5.29, -1.93, -6.16, -4.53)
      ..lineTo(2.18, 14.1)
      ..relativeLineTo(0.0, 2.84)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Path (#FBBC05)
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final Path yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..relativeCubicTo(-0.22, -0.66, -0.35, -1.36, -0.35, -2.09)
      ..relativeCubicTo(0.0, -0.73, 0.13, -1.43, 0.35, -2.09)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..relativeLineTo(2.85, -2.22)
      ..relativeLineTo(0.81, -0.63)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Path (#EA4335)
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final Path redPath = Path()
      ..moveTo(12.0, 5.38)
      ..relativeCubicTo(1.62, 0.0, 3.06, 0.56, 4.21, 1.64)
      ..relativeLineTo(3.15, -3.15)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..relativeLineTo(3.66, 2.84)
      ..relativeCubicTo(0.87, -2.6, 3.3, -4.52, 6.16, -4.52)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
