import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/word.dart';
import '../widgets/word_card.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';


class EncryptedDictionaryScreen extends StatefulWidget {
  const EncryptedDictionaryScreen({super.key});

  @override
  State<EncryptedDictionaryScreen> createState() => _EncryptedDictionaryScreenState();
}

class _EncryptedDictionaryScreenState extends State<EncryptedDictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  // late stt.SpeechToText _speech;
  //bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    //_speech = stt.SpeechToText();
  }
  Future<void> _loadDictionary() async {
    // 🔒 Load encrypted binary file
    final ByteData byteData = await rootBundle.load('assets/data/dictionary.bin');
    final Uint8List encryptedBytes = byteData.buffer.asUint8List();

    // 🔐 Extract IV + ciphertext
    final iv = encrypt.IV(encryptedBytes.sublist(0, 16)); // IV = first 16 bytes
    final ciphertext = encryptedBytes.sublist(16);       // encrypted JSON

    // 🔑 Derive AES-256 key using SHA256
    const password = String.fromEnvironment('DICT_PASSWORD');
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyBytes));

    // 🔓 Decrypt using AES CBC
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt(encrypt.Encrypted(ciphertext), iv: iv);

    // 📝 Parse decrypted JSON string into Word objects
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

  /*void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _searchController.text = val.recognizedWords;
          _filterWords(val.recognizedWords);
        });
      });
    }
  }
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }
*/
  @override
  void dispose() {
    _searchController.dispose();
    //_speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prof. Mahdi Hamid Muudeetiin', style:  GoogleFonts.alumniSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
      ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterWords,
              autofocus: true,
              autocorrect: true,
              decoration: InputDecoration(
                hintText: 'Search English Word...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: (){}
                ),
                //suffixIcon: IconButton(
                // icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                // onPressed: _isListening ? _stopListening : _startListening,
                //),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
