import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:google_fonts/google_fonts.dart';

import '../models/word.dart';
import 'dictionary_screen.dart';
import 'favorites_screen.dart';
import 'about_screen.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<Word> _dictionaryWords = [];
  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _isSearching = false;
      _searchController.clear();
    });
    Navigator.pop(context); // Close drawer
  }
  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    final ByteData byteData = await rootBundle.load('assets/data/dictionary.bin');
    final Uint8List encryptedBytes = byteData.buffer.asUint8List();

    final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
    final ciphertext = encryptedBytes.sublist(16);

    const password = String.fromEnvironment('DICT_PASSWORD');
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyBytes));

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt(encrypt.Encrypted(ciphertext), iv: iv);

    final List<dynamic> data = json.decode(decrypted);
    setState(() {
      _dictionaryWords = data.map((item) => Word.fromJson(item)).toList();
    });
  }


  final List<String> _titles = ['Learn', 'Dictionary', 'Favorites', 'About'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const DictionaryScreen(),
      const FavoritesScreen(),
      const AboutScreen(),
      LearnScreen(words: _dictionaryWords)
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade700,
        elevation: 4,
        centerTitle: true,
        title: Text(
          "HAMID MUUDEE'S DICTIONARY",
          style: GoogleFonts.alumniSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon( Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text(
                "Hamid Muudee's Dictionary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text(
                'Developed by Horn Team',
                style: TextStyle(fontSize: 14),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('assets/icons/ic_launcher.png'),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.amberAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Favorites'),
              onTap: () => _onItemTapped(1),
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Author'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Developer'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Learn'),
              onTap: () => _onItemTapped(3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Exit'),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  SystemNavigator.pop();
                });
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
          _isSearching = false;
          _searchController.clear();
        }),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.amberAccent,
        showUnselectedLabels: true,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dictionary'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Learn'),
        ],
      ),
    );
  }
}
