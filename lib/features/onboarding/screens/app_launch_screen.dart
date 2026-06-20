import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/storage/onboarding_store.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../browse/screens/browse_screen.dart';
import 'onboarding_screen.dart';

class AppLaunchScreen extends StatefulWidget {
  const AppLaunchScreen({super.key});

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final showOnboarding = !OnboardingStore.instance.isCompleted;
    final nextScreen = showOnboarding
        ? const OnboardingScreen()
        : const BrowseScreen();

    await AnalyticsService.instance.logScreen(
      showOnboarding ? 'onboarding' : 'browse',
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => nextScreen),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.handlePendingInviteIfAny();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: context.brandBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_offer,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Flipp',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: appTheme.navyText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deals & shopping lists',
              style: TextStyle(
                fontSize: 14,
                color: appTheme.subtitle,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.brandBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
