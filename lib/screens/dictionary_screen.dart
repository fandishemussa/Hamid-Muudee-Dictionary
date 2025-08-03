import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';
import 'flashcard_screen.dart'; // <- make sure this file exists

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Word> _words = [];
  List<Word> _filteredWords = [];

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
      _words = data.map((item) => Word.fromJson(item)).toList();
      _filteredWords = _words;
    });
  }

  void _filterWords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWords = _words;
      } else {
        _filteredWords = _words
            .where((word) => word.english.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Word getWordOfTheDay() {
    if (_words.isEmpty) return Word(english: 'Loading...', oromoTranslation: '', englishDefinition: '', partOfSpeech: '', pronunciation: '');
    final index = DateTime.now().day % _words.length;
    return _words[index];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordOfTheDay = getWordOfTheDay();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prof. Mahdi Hamid Muudeetiin',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _filterWords,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search English Word...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterWords('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Word List
            Expanded(
              child: _filteredWords.isEmpty
                  ? const Center(child: Text('No words found!'))
                  : ListView.builder(
                itemCount: _filteredWords.length,
                itemBuilder: (context, index) {
                  return WordCard(word: _filteredWords[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
