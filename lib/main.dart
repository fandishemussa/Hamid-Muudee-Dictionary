import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oromo_dictionary/screens/new_home_screen.dart';
import 'screens/home_screen.dart';
import 'themes/app_theme.dart';

void main() {
 // GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const OromoDictionaryApp());
}

class OromoDictionaryApp extends StatelessWidget {
  const OromoDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
