import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word.dart';
import 'flashcard_screen.dart';

class LearnScreen extends StatelessWidget {
  final List<Word> words;
  const LearnScreen({super.key, required this.words});

  Word getWordOfTheDay() {
    if (words.isEmpty) {
      return Word(english: 'Loading...', oromoTranslation: '', englishDefinition: '', partOfSpeech: '', pronunciation: '');
    }
    final index = DateTime.now().day % words.length;
    return words[index];
  }

  @override
  Widget build(BuildContext context) {
    final wordOfTheDay = getWordOfTheDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Learning'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.amber.shade100,
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.bolt, color: Colors.orange),
                title: const Text(
                  'Word of the Day',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${wordOfTheDay.english} – ${wordOfTheDay.oromoTranslation}'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text("Learn 5 new words today!"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final randomWords = (words..shuffle()).take(5).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardScreen(words: randomWords),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
