import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../themes/app_sizing.dart';

class FlashcardScreen extends StatefulWidget {
  final List<Word> words;

  const FlashcardScreen({super.key, required this.words});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late PageController _pageController;

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFFF093FB), const Color(0xFFF5576C)],
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
    [const Color(0xFFFFA726), const Color(0xFFFF7043)],
    [const Color(0xFFE040FB), const Color(0xFF7C4DFF)],
    [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
    [const Color(0xFFFF5722), const Color(0xFFE91E63)],
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.selectionClick();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard() {
    if (_currentIndex < widget.words.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  String _toTitleCase(String input) {
    if (input.isEmpty) return '';
    return input
        .split(' ')
        .map(
          (w) =>
              w.isNotEmpty
                  ? w[0].toUpperCase() + w.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: Text(
          'Flashcards',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.words.length}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((_currentIndex + 1) / widget.words.length),
                backgroundColor:
                    isDark ? const Color(0xFF252540) : Colors.grey.shade200,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.words.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isFlipped = false;
                  _flipController.reset();
                });
              },
              itemBuilder: (context, index) {
                final word = widget.words[index];
                final gradient = _cardGradients[index % _cardGradients.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        // Only animate current card
                        final angle =
                            index == _currentIndex
                                ? _flipAnimation.value * pi
                                : 0.0;
                        final isBack = angle > pi / 2;

                        return Transform(
                          transform:
                              Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                          alignment: Alignment.center,
                          child:
                              isBack
                                  ? Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildBackCard(
                                      word,
                                      gradient,
                                      isDark,
                                    ),
                                  )
                                  : _buildFrontCard(word, gradient, isDark),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Tap hint
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap card to reveal translation',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      'Previous',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color:
                            _currentIndex > 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _currentIndex < widget.words.length - 1
                            ? _nextCard
                            : () => Navigator.pop(context),
                    icon: Icon(
                      _currentIndex < widget.words.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentIndex < widget.words.length - 1 ? 'Next' : 'Done',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(Word word, List<Color> gradient, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                word.partOfSpeech.isNotEmpty ? word.partOfSpeech : 'word',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            // Use FittedBox so very long words scale down instead of overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _toTitleCase(word.english),
                style: GoogleFonts.playfairDisplay(
                  fontSize: AppSizing.isSmall(context) ? 30 : 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            if (word.pronunciation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '/${word.pronunciation}/',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flip,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to see translation',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Word word, List<Color> gradient, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient.last, gradient.first],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Afaan Oromoo',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _toTitleCase(word.oromoTranslation),
                style: GoogleFonts.playfairDisplay(
                  fontSize: AppSizing.isSmall(context) ? 28 : 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            if (word.englishDefinition.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  word.englishDefinition,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
