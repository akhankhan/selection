import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/browse/screens/browse_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
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
