import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dictionary_screen.dart';
import 'favorites_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _screens = [
    const DictionaryScreen(),
    const FavoritesScreen(),
    const AboutScreen(),
  ];

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade700,
        elevation: 4,
        centerTitle: true,
        title: Text(
          'HAMID MUDE DICTIONARY',
          style: GoogleFonts.alumniSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
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
                'Hamid Muudee Dictionary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text(
                'Developed by Horn Team',
                style: TextStyle(fontSize: 14),
              ),
              currentAccountPicture:  Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: CircleAvatar(
        backgroundImage: AssetImage('assets/icons/ic_launcher.png'),
        radius: 20,
      ),
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
              title: const Text('About'),
              onTap: () => _onItemTapped(2),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
      body:  IndexedStack(
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
        selectedItemColor: Colors.amber.shade800,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}
