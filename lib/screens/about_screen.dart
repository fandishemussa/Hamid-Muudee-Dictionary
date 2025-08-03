import 'package:flutter/material.dart';
//import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String version = '';

  // @override
  // void initState() {
  //   super.initState();
  //   _loadAppInfo();
  // }

  // Future<void> _loadAppInfo() async {
  //   PackageInfo info = await PackageInfo.fromPlatform();
  //   setState(() {
  //     version = info.version;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Oromo Dictionary App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Version: $version', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Developed by: Horn Development Team', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
