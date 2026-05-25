import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ShareListSheet extends StatelessWidget {
  ShareListSheet({super.key});

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ShareListSheet(),
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
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, child) {
        return Stack(
          children: [
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              const SizedBox(height: 12),
              const Text(
                'Sign in to share your list',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Combine your list with a friend and\ncollaborate on a single shopping list.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F6368),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _HandsIllustration(),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Learn more about how sharing works',
                      style: TextStyle(
                        color: Color(0xFF0071CE),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, size: 14, color: Color(0xFF0071CE)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'To combine lists, connect with',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Continue with Facebook',
                icon: _FacebookIcon(),
                onTap: () {},
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
                icon: const Icon(
                  Icons.mail_outline,
                  color: Colors.black87,
                  size: 22,
                ),
                onTap: () {},
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'No thanks',
                  style: TextStyle(
                    color: Color(0xFF0071CE),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _TermsText(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    ),
    if (isLoading)
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0071CE),
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
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Collaborate & Share!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are currently signed in as:\n${user.displayName ?? user.email ?? "User"}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF5F6368),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // User info row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF0071CE).withValues(
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
                                color: Color(0xFF0071CE),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            user.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Share button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inviting friends feature enabled!'),
                        backgroundColor: Color(0xFF0071CE),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                  label: const Text(
                    'Invite a Friend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0071CE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Sign out or close option
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(
                    color: Color(0xFF0071CE),
                    fontWeight: FontWeight.bold,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            SizedBox(width: 24, height: 24, child: Center(child: icon)),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

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

class _HandsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: CustomPaint(
        size: const Size(200, 140),
        painter: _HandsIllustrationPainter(),
      ),
    );
  }
}

class _HandsIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw soft blue oval background
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF0F5FA)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Draw shopping list sheet (tilted white card in the center)
    final Paint cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint cardShadow = Paint()
      ..color = const Color(0x10000000)
      ..style = PaintingStyle.fill;

    // Shadow rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.23, h * 0.16, w * 0.54, h * 0.70),
        const Radius.circular(8),
      ),
      cardShadow,
    );
    // Real sheet rect
    final RRect sheetRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.14, w * 0.50, h * 0.68),
      const Radius.circular(8),
    );
    canvas.drawRRect(sheetRRect, cardPaint);

    // Draw thin blue border around the sheet
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFD8E5F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(sheetRRect, borderPaint);

    // 3. Draw lines and checkboxes on the sheet
    final Paint linePaint = Paint()
      ..color = const Color(0xFFE6EFF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint checkPaint = Paint()
      ..color = const Color(0xFF4FA0F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint checkedBg = Paint()
      ..color = const Color(0xFFE8F1FC)
      ..style = PaintingStyle.fill;

    // Checkbox 1 (Checked)
    final double cb1Top = h * 0.24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, cb1Top, 15, 11),
        const Radius.circular(2),
      ),
      checkedBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, cb1Top, 15, 11),
        const Radius.circular(2),
      ),
      checkPaint,
    );
    // Draw check mark
    final Path checkPath = Path()
      ..moveTo(w * 0.32 + 3, cb1Top + 5)
      ..lineTo(w * 0.32 + 6, cb1Top + 8)
      ..lineTo(w * 0.32 + 11, cb1Top + 3);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = const Color(0xFF0071CE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Lines for item 1
    canvas.drawLine(
      Offset(w * 0.44, cb1Top + 5),
      Offset(w * 0.68, cb1Top + 5),
      linePaint,
    );

    // Checkbox 2 (Checked)
    final double cb2Top = h * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, cb2Top, 15, 11),
        const Radius.circular(2),
      ),
      checkedBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, cb2Top, 15, 11),
        const Radius.circular(2),
      ),
      checkPaint,
    );
    // Draw check mark
    final Path checkPath2 = Path()
      ..moveTo(w * 0.32 + 3, cb2Top + 5)
      ..lineTo(w * 0.32 + 6, cb2Top + 8)
      ..lineTo(w * 0.32 + 11, cb2Top + 3);
    canvas.drawPath(
      checkPath2,
      Paint()
        ..color = const Color(0xFF0071CE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // Lines for item 2
    canvas.drawLine(
      Offset(w * 0.44, cb2Top + 5),
      Offset(w * 0.62, cb2Top + 5),
      linePaint,
    );

    // Checkbox 3 (Unchecked)
    final double cb3Top = h * 0.60;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, cb3Top, 15, 11),
        const Radius.circular(2),
      ),
      checkPaint,
    );
    // Lines for item 3
    canvas.drawLine(
      Offset(w * 0.44, cb3Top + 5),
      Offset(w * 0.58, cb3Top + 5),
      linePaint,
    );

    // 4. Draw Left Hand (Sleeve, Watch, Hand pointing to Checkbox 1)
    final Paint skinPaint = Paint()..color = const Color(0xFFFCBEA1);
    final Paint watchPaint = Paint()..color = const Color(0xFF6B7A82);
    final Paint sleevePaint1 = Paint()
      ..color = const Color(0xFFED836F); // Peach-red sleeve

    // Left Arm/Sleeve
    final Path sleevePath1 = Path()
      ..moveTo(0, h * 0.38)
      ..lineTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.22, h * 0.48)
      ..lineTo(w * 0.05, h * 0.56)
      ..close();
    canvas.drawPath(sleevePath1, sleevePaint1);

    // Watch
    canvas.drawOval(Rect.fromLTWH(w * 0.13, h * 0.38, 10, 8), watchPaint);

    // Left Hand pointing finger
    final Path handPath1 = Path()
      ..moveTo(w * 0.16, h * 0.38)
      ..quadraticBezierTo(
        w * 0.22,
        h * 0.40,
        w * 0.32,
        h * 0.46,
      ) // Pointing finger
      ..lineTo(w * 0.34, h * 0.48)
      ..quadraticBezierTo(w * 0.36, h * 0.50, w * 0.34, h * 0.52)
      ..lineTo(w * 0.24, h * 0.54)
      ..lineTo(w * 0.18, h * 0.46)
      ..close();
    canvas.drawPath(handPath1, skinPaint);

    // 5. Draw Right Hand (pointing to Checkbox 2)
    final Paint sleevePaint2 = Paint()
      ..color = const Color(0xFFED836F); // Reddish sleeve

    // Right Arm/Sleeve
    final Path sleevePath2 = Path()
      ..moveTo(w, h * 0.48)
      ..lineTo(w * 0.84, h * 0.42)
      ..lineTo(w * 0.78, h * 0.60)
      ..lineTo(w * 0.94, h * 0.66)
      ..close();
    canvas.drawPath(sleevePath2, sleevePaint2);

    // Right Hand pointing finger
    final Path handPath2 = Path()
      ..moveTo(w * 0.84, h * 0.50)
      ..quadraticBezierTo(
        w * 0.78,
        h * 0.52,
        w * 0.68,
        h * 0.58,
      ) // Pointing finger
      ..lineTo(w * 0.66, h * 0.60)
      ..quadraticBezierTo(w * 0.64, h * 0.62, w * 0.66, h * 0.64)
      ..lineTo(w * 0.74, h * 0.66)
      ..lineTo(w * 0.80, h * 0.58)
      ..close();
    canvas.drawPath(handPath2, skinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      fontSize: 12,
      color: Color(0xFF0071CE),
      fontWeight: FontWeight.w600,
    );
    const normal = TextStyle(fontSize: 12, color: Colors.black54, height: 1.4);
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'By continuing, you agree to our ', style: normal),
          TextSpan(text: 'Terms of Use', style: link),
          TextSpan(
            text:
                ' and the collection and use of your data as described in our ',
            style: normal,
          ),
          TextSpan(text: 'Privacy\nPolicy', style: link),
          TextSpan(
            text:
                '. If you\'d like to opt out or learn more about your data options, please review our ',
            style: normal,
          ),
          TextSpan(text: 'Privacy Policy', style: link),
          TextSpan(text: '.', style: normal),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
