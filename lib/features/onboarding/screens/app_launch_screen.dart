import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/storage/onboarding_store.dart';
import '../../browse/screens/browse_screen.dart';
import '../widgets/menu2go_splash_animation.dart';
import 'onboarding_screen.dart';

class AppLaunchScreen extends StatefulWidget {
  const AppLaunchScreen({super.key});

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
  final _splashKey = GlobalKey<Menu2GoSplashAnimationState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 1600));
    await minSplash;
    if (!mounted) return;

    final showOnboarding = !OnboardingStore.instance.isCompleted;
    final nextScreen = showOnboarding
        ? const OnboardingScreen()
        : const BrowseScreen();

    await AnalyticsService.instance.logScreen(
      showOnboarding ? 'onboarding' : 'browse',
    );

    if (!mounted) return;
    await Menu2GoSplashAnimation.playExit(_splashKey);
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => nextScreen));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.handlePendingInviteIfAny();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: brandPink,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: brandPink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: brandPink,
        body: Menu2GoSplashAnimation(key: _splashKey),
      ),
    );
  }
}
