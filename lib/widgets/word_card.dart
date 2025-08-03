import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import 'package:google_fonts/google_fonts.dart';


class WordCard extends StatefulWidget {
  final Word word;

  const WordCard({super.key, required this.word});

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
//  late bool _isFavorite;

  // @override
  // void initState() {
  //   super.initState();
  //   _isFavorite = widget.word.isFavorite;
  //   _loadFavoriteStatus();
  // }

  // Future<void> _loadFavoriteStatus() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> savedFavorites = prefs.getStringList('favorites') ?? [];
  //   setState(() {
  //     _isFavorite = savedFavorites.contains(widget.word.english.toLowerCase());
  //   });
  // }

  // Future<void> _toggleFavorite() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> savedFavorites = prefs.getStringList('favorites') ?? [];
  //
  //   setState(() {
  //     _isFavorite = !_isFavorite;
  //   });
  //
  //   if (_isFavorite) {
  //     savedFavorites.add(widget.word.english.toLowerCase());
  //   } else {
  //     savedFavorites.remove(widget.word.english.toLowerCase());
  //   }
  //
  //   await prefs.setStringList('favorites', savedFavorites);
  // }
  String toTitleCase(String input) {
    if (input.isEmpty) return '';
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
        ? word[0].toUpperCase() + word.substring(1).toLowerCase()
        : '')
        .join(' ');
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        title:
        Row(
          children: [
            const SizedBox(height: 4),
            Text(toTitleCase(widget.word.english), style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),),
            Text('/${widget.word.pronunciation}', style: GoogleFonts.robotoSerif(color: Colors.green,fontSize: 12, fontWeight: FontWeight.normal ),),
            Text('/ ${widget.word.partOfSpeech}', style: TextStyle(color: Colors.blueAccent),),
            //Text('Definition: ${widget.word.englishDefinition}'),

          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
           // Text('Pronunciation: ${widget.word.pronunciation}'),
            //Text('Part of Speech: ${widget.word.partOfSpeech}'),
            //Text('Definition: ${widget.word.englishDefinition}'),
            Text(toTitleCase(widget.word.oromoTranslation),
                style: const TextStyle(color: Colors.black45)),
          ],
        ),
        // trailing: IconButton(
        //   icon: Icon(
        //     _isFavorite ? Icons.star : Icons.star_border,
        //     color: _isFavorite ? Colors.yellow[700] : Colors.grey,
        //   ),
        //   onPressed: //_toggleFavorite,
        // ),
      ),
    );
  }
}
