import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/storage/notification_preferences_store.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../services/apple_sign_in_service.dart';
import '../services/push_notification_service.dart';
import '../widgets/legal_terms_footer.dart';
import 'email_signin_screen.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF7F7F7F).withValues(
        alpha: 0.5,
      ), // Semi-transparent backdrop like a bottom sheet overlay
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Clickable top area to dismiss, mimicking a bottom sheet
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Bottom Sheet Container
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                return Stack(
                  children: [
                    Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Bottom sheet handle
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: appTheme.border,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title Block
                  Text(
                    'Sign in to MENU2GO',
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Unlock a smarter way to shop',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: appTheme.navyText,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3 Card Carousel
                  _buildFlyersRow(context),
                  const SizedBox(height: 24),

                  // Benefits checklist
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                        _buildBenefitRow(
                          context,
                          'Build and share your shopping list',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          context,
                          'Easy access to your favourite stores',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          context,
                          'Deals synced across all your devices',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Social login buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // _buildSocialButton(
                        //   icon: Icons.facebook,
                        //   iconColor: const Color(0xFF1877F2),
                        //   label: 'Continue with Facebook',
                        //   onTap: () => _handleLogin(context, 'Facebook'),
                        // ),
                        // const SizedBox(height: 12),
                        _buildSocialButton(
                          context,
                          iconImage: 'apple',
                          label: 'Continue with Apple',
                          onTap: () => _handleAppleLogin(context),
                        ),
                        const SizedBox(height: 12),
                        _buildSocialButton(
                          context,
                          iconImage:
                              'google', // Simulated custom colorful Google icon
                          label: 'Continue with Google',
                          onTap: () => _handleLogin(context, 'Google'),
                        ),
                        const SizedBox(height: 12),
                        _buildSocialButton(
                          context,
                          icon: Icons.email_outlined,
                          iconColor: appTheme.subtitle,
                          label: 'Continue with email',
                          onTap: () => _handleEmailLogin(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Not now link
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Not now',
                      style: TextStyle(
                        color: context.brandBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer disclaimer
                  const LegalTermsFooter(
                    style: LegalTermsFooterStyle.full,
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.7),
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
    ),
  ],
),
),
);
}

  Widget _buildFlyersRow(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics:
            const NeverScrollableScrollPhysics(), // Match static screenshot feel
        children: [
          _buildFlyerMockCard(
            context,
            brandName: 'FRESH CO',
            color: const Color(0xFF8DC63F),
            subLabel: 'Lower Food Prices',
            items: [
              {
                'title': 'Fresh Raspberries',
                'price': '\$1.99',
                'color': Colors.red,
              },
              {
                'title': 'Beef Burgers',
                'price': '\$8.99',
                'color': Colors.brown,
              },
            ],
          ),
          const SizedBox(width: 12),
          _buildFlyerMockCard(
            context,
            brandName: 'NO FRILLS',
            color: const Color(0xFFFFD200),
            subLabel: 'Won\'t Be Beat',
            textColor: Colors.black87,
            items: [
              {
                'title': 'Yellow Melon',
                'price': '\$2.49',
                'color': Colors.orangeAccent,
              },
              {
                'title': 'Pork Sausages',
                'price': '\$3.99',
                'color': Colors.redAccent,
              },
            ],
          ),
          const SizedBox(width: 12),
          _buildFlyerMockCard(
            context,
            brandName: 'Walmart',
            color: const Color(0xFF0071CE),
            subLabel: 'Save money. Live better.',
            items: [
              {
                'title': 'Green Seedless Grapes',
                'price': '\$2.99',
                'color': Colors.green,
              },
              {
                'title': 'Lean Ground Beef',
                'price': '\$9.99',
                'color': Colors.red,
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlyerMockCard(
    BuildContext context, {
    required String brandName,
    required Color color,
    required String subLabel,
    Color textColor = Colors.white,
    required List<Map<String, dynamic>> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner
          Container(
            height: 38,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  brandName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  subLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content cells
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.78,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                children: items.map((item) {
                  return Container(
                    decoration: BoxDecoration(
                      color: appTheme.sectionBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: (item['color'] as Color)
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                Icons.shopping_basket,
                                size: 10,
                                color: item['color'],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          item['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 6,
                            color: appTheme.subtitle,
                          ),
                        ),
                        Text(
                          item['price'],
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: item['color'],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, String benefit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check, color: Color(0xFF00C853), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            benefit,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: context.appTheme.navyText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    IconData? icon,
    Color? iconColor,
    String? iconImage,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: appTheme.border, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (iconImage == 'google')
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: GoogleLogoPainter()),
                )
              else if (iconImage == 'apple')
                Icon(Icons.apple, color: colorScheme.onSurface, size: 24)
              else
                Icon(icon, color: iconColor, size: 22),
              const Expanded(child: SizedBox()),
              Text(
                label,
                style: TextStyle(
                  color: appTheme.navyText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                ),
              ),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 22), // Offset to perfectly center text
            ],
          ),
        ),
      ),
    );
  }

  /// Creates the Firestore `users/{uid}` document on first sign-in, or
  /// updates the profile + lastSignInAt on subsequent sign-ins. The admin
  /// panel reads from this collection — without this, signed-in users do
  /// not appear in the admin Users screen.
  Future<void> _afterSignInSuccess() async {
    if (NotificationPreferencesStore.instance.enabled) {
      unawaited(PushNotificationService.instance.syncTokenIfPermitted());
      if (!await PushNotificationService.instance.isNotificationPermissionGranted()) {
        PushNotificationService.instance.resetPromptSession();
        unawaited(
          PushNotificationService.instance.schedulePermissionPromptWhenReady(),
        );
      }
    }
  }

  Future<void> _upsertUserDoc(User? user) async {
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      final snap = await ref.get();
      final profile = <String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'lastSignInAt': FieldValue.serverTimestamp(),
      };
      if (!snap.exists) {
        profile['createdAt'] = FieldValue.serverTimestamp();
        profile['notificationsEnabled'] =
            NotificationPreferencesStore.instance.enabled;
        await ref.set(profile);
      } else {
        await ref.update(profile);
      }

      if (NotificationPreferencesStore.instance.enabled) {
        unawaited(PushNotificationService.instance.syncTokenIfPermitted());
      }
    } catch (e) {
      debugPrint('[Firestore] upsert failed: $e');
    }
  }

  Future<void> _handleEmailLogin(BuildContext context) async {
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EmailSignInScreen()),
    );

    if (signedIn == true && context.mounted) {
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pop(context);
      await _afterSignInSuccess();
      if (!context.mounted) return;
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

  Future<void> _handleAppleLogin(BuildContext context) async {
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

    debugPrint('[Apple Sign-In] Starting Apple authentication...');

    try {
      final result = await AppleSignInService.requestAppleCredentialWithNonce();

      if (!context.mounted) return;

      _isLoading.value = true;

      final userCredential = await AppleSignInService.signInWithFirebase(
        appleCredential: result.credential,
        rawNonce: result.rawNonce,
      );

      await _upsertUserDoc(userCredential.user);
      _isLoading.value = false;

      if (context.mounted) {
        Navigator.pop(context);
        await _afterSignInSuccess();
        if (!context.mounted) return;
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
      debugPrint('[Apple Sign-In ERROR] $e');
      if (context.mounted) {
        _showAppleErrorDialog(
          context,
          AppleSignInService.authErrorMessage(e),
        );
      }
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      debugPrint('[Apple Sign-In ERROR] ${e.code}: ${e.message}');
      if (context.mounted) {
        _showAppleErrorDialog(
          context,
          AppleSignInService.authErrorMessage(e),
        );
      }
    } catch (e) {
      _isLoading.value = false;
      debugPrint('[Apple Sign-In ERROR] $e');
      if (context.mounted) {
        _showAppleErrorDialog(
          context,
          AppleSignInService.authErrorMessage(e),
        );
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

  void _handleLogin(BuildContext context, String provider) async {
    if (provider != 'Google') return;

    // Google Sign-In Flow
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

      await _upsertUserDoc(userCredential.user);

      _isLoading.value = false;

      if (context.mounted) {
        Navigator.pop(context); // Dismiss SignInScreen bottom sheet
        await _afterSignInSuccess();
        if (!context.mounted) return;
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

      final message = _googleSignInErrorMessage(e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 6),
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

  String _googleSignInErrorMessage(Object error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Google Sign-In was cancelled.';
      }
      final details = error.toString().toLowerCase();
      if (details.contains('no credential') ||
          details.contains('no credentials')) {
        return 'No Google account found on this device. '
            'On the emulator: Settings → Passwords & accounts → Add account → Google. '
            'Then try again.';
      }
    }
    return 'Google Sign-In failed. Uninstall the app, run flutter clean, rebuild, '
        'and try again. If it still fails, add a Google account to the device.';
  }
}

// Custom Painter to draw mathematically accurate Google "G" vector logo
class GoogleLogoPainter extends CustomPainter {
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
