import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word.dart';

class FlashcardScreen extends StatelessWidget {
  final List<Word> words;

  const FlashcardScreen({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Flashcards"),
        centerTitle: true,
      ),
      body: PageView.builder(
        itemCount: words.length,
        itemBuilder: (context, index) {
          final word = words[index];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(word.english,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 12),
                    Text(
                      'Part of Speech: ${word.partOfSpeech}',
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        word.oromoTranslation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, color: Colors.deepOrange),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
