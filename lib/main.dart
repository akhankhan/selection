import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/browse/screens/browse_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.instance.load();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '699002286605-cr66fkq10usnoisphf6vmna1i62vo61a.apps.googleusercontent.com',
  );
  FirebaseAuth.instance.authStateChanges().listen(_syncUserToFirestore);
  runApp(const MyApp());
}

Future<void> _syncUserToFirestore(User? user) async {
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
      await ref.set(profile);
    } else {
      await ref.update(profile);
    }
  } catch (e) {
    debugPrint('[Firestore] user sync failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Selection Flyer Viewer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 250),
          themeAnimationCurve: Curves.easeInOut,
          home: const BrowseScreen(),
        );
      },
    );
  }
}
