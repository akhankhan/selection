import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../screens/signin_screen.dart';

class SignInRequiredGate extends StatelessWidget {
  const SignInRequiredGate({
    super.key,
    this.title = 'Sign in to use your lists',
    this.message =
        'Create an account to save, sync, and share shopping lists across all your devices.',
    this.showNotNow = true,
  });

  final String title;
  final String message;
  final bool showNotNow;

  Future<void> _openSignIn(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: context.brandBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: context.brandBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: appTheme.navyText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: appTheme.subtitle,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _BenefitRow(
              icon: Icons.cloud_sync_outlined,
              label: 'Sync lists on every device',
              appTheme: appTheme,
            ),
            const SizedBox(height: 10),
            _BenefitRow(
              icon: Icons.people_outline,
              label: 'Share lists with friends & family',
              appTheme: appTheme,
            ),
            const SizedBox(height: 10),
            _BenefitRow(
              icon: Icons.favorite_border,
              label: 'Keep favorites backed up',
              appTheme: appTheme,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => _openSignIn(context),
                style: FilledButton.styleFrom(
                  backgroundColor: context.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sign in or create account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (showNotNow) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Not now',
                  style: TextStyle(
                    color: appTheme.subtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
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
        Icon(icon, size: 20, color: context.brandBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appTheme.navyText,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> ensureSignedIn(BuildContext context) async {
  if (FirebaseAuth.instance.currentUser != null) return true;

  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => SignInScreen()),
  );

  return FirebaseAuth.instance.currentUser != null;
}
