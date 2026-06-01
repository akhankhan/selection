import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'features/browse/screens/browse_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Disk-cache Firestore docs so a cold relaunch paints from the local copy
  // before the network round-trip finishes.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '699002286605-cr66fkq10usnoisphf6vmna1i62vo61a.apps.googleusercontent.com',
  );
  // Mirror every authenticated user into Firestore `users/{uid}` so the
  // admin panel (which reads from Firestore) sees them. Fires on cold-start
  // for already-signed-in users and on every fresh sign-in.
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
    return MaterialApp(
      title: 'Selection Flyer Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0071CE),
          primary: const Color(0xFF0071CE),
        ),
        useMaterial3: true,
      ),
      home: const BrowseScreen(),
    );
  }
}
