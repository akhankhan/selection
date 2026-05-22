import 'package:flutter/material.dart';
import 'features/flyer/screens/flyer_viewer_screen.dart';

void main() {
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
      home: const FlyerViewerScreen(),
    );
  }
}
