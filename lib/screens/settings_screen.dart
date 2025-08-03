import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oromo_dictionary/themes/app_theme.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode =  PlatformDispatcher.instance.platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  @override
  void initState() {
    super.initState();
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      var systemBrightness = PlatformDispatcher.instance.platformBrightness;
      setState(() {
        _themeMode =
        systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      });
    };
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: _toggleTheme,
              secondary: const Icon(Icons.brightness_6),
            ),
          ],
        ),
      ),
    );
  }
}
