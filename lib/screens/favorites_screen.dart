import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';
import 'package:flutter/services.dart' show rootBundle;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Word> _favorites = [];

  // @override
  // void initState() {
  //   super.initState();
  //   _loadFavorites();
  // }

  // Future<void> _loadFavorites() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> savedFavorites = prefs.getStringList('favorites') ?? [];
  //
  //   final String response = await rootBundle.loadString('assets/data/dictionary.json');
  //   final List<dynamic> data = json.decode(response);
  //
  //   List<Word> allWords = data.map((item) => Word.fromJson(item)).toList();
  //
  //   setState(() {
  //     _favorites = allWords
  //         .where((word) => savedFavorites.contains(word.english.toLowerCase()))
  //         .toList();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: _favorites.isEmpty
          ? const Center(child: Text('No favorite words yet!'))
          : ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          return WordCard(word: _favorites[index]);
        },
      ),
    );
  }
}
