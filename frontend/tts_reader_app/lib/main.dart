// main.dart — the entry point of every Flutter app.
// Flutter calls main() automatically when the app launches, just like in Go or C.

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  // runApp() hands control to Flutter. From here Flutter takes over the screen,
  // builds the widget tree, and manages the render loop.
  runApp(const TtsReaderApp());
}

// StatelessWidget is the right choice here because the root app itself never
// changes — it just defines the theme and the starting screen.
// Only use StatefulWidget when a widget needs to store and update its own data.
class TtsReaderApp extends StatelessWidget {
  const TtsReaderApp({super.key});

  // build() describes what this widget looks like. Flutter calls it whenever
  // it needs to (re)draw this widget. Keep it pure — no side effects here.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Reader',
      debugShowCheckedModeBanner: false,

      // ThemeData centralises your visual design so every widget picks up
      // the same colours and typography automatically.
      // ColorScheme.fromSeed generates a full palette from a single seed colour.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true, // Material 3 is the current design system from Google.
      ),

      // `home` is the first screen shown when the app starts.
      home: const HomeScreen(),
    );
  }
}
