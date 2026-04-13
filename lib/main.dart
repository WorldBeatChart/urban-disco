import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/chart_screen.dart';

void main() {
  runApp(const WorldBeatChartApp());
}

class WorldBeatChartApp extends StatelessWidget {
  const WorldBeatChartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlbumDrop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0f172a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366f1),
          surface: Color(0xFF1e293b),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const ChartScreen(),
    );
  }
}
