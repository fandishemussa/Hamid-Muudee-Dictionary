import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../services/app_session.dart';
import '../services/tts_service.dart';
import '../services/share_service.dart';

class WordDetailScreen extends StatefulWidget {
  final Word word;
  final List<Word> allWords;

  const WordDetailScreen({
    super.key,
    required this.word,
    this.allWords = const [],
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isSpeaking = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Map<String, Color> _posColors = {
    'noun': Color(0xFF4A90D9),
    'verb': Color(0xFF7B68EE),
    'adj': Color(0xFF00BFA5),
    'adjective': Color(0xFF00BFA5),
    'adv': Color(0xFFFF8C00),
    'adverb': Color(0xFFFF8C00),
    'prep': Color(0xFFE91E63),
    'conj': Color(0xFF9C27B0),
    'pron': Color(0xFF4CAF50),
    'pronoun': Color(0xFF4CAF50),
    'interj': Color(0xFFFF5722),
    'n': Color(0xFF4A90D9),
    'v': Color(0xFF7B68EE),
  };

  Color get _posColor {
    final pos = widget.word.partOfSpeech.toLowerCase().trim();
    for (final key in _posColors.keys) {
      if (pos.contains(key)) return _posColors[key]!;
    }
    return const Color(0xFF9E9E9E);
  }

  List<Word> get _relatedWords {
    if (widget.allWords.isEmpty) return [];
    final pos = widget.word.partOfSpeech.toLowerCase();
    return widget.allWords
        .where((w) =>
    w.english != widget.word.english &&
        w.partOfSpeech.toLowerCase() == pos)
        .take(5)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    AppSession.instance.addRecentWord(widget.word.english);
    AppSession.instance.recordWordViewed();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    final newVal = !AppSession.instance.isFavorite(widget.word.english);
    widget.word.isFavorite = newVal;
    AppSession.instance.toggleFavorite(widget.word.english, value: newVal);
    // favoritesNotifier fires → bookmark icons everywhere rebuild instantly
  }

  void _speakWord() async {
    final tts = TtsService.instance;
    if (tts.isSpeaking.value) {
      await tts.stop();
      setState(() => _isSpeaking = false);
      _pulseController.stop();
      _pulseController.reset();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSpeaking = true);
    _pulseController.repeat(reverse: true);
    await tts.speak(widget.word.english);
    if (mounted) {
      setState(() => _isSpeaking = false);
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _shareWord() {
    ShareService.instance.shareWord(widget.word);
  }

  String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posColor = _posColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFBF0),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark, posColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildPronunciationRow(isDark, posColor),
                  const SizedBox(height: 24),
                  if (widget.word.englishDefinition.isNotEmpty)
                    _buildSection(
                      title: 'Definition',
                      icon: Icons.menu_book_outlined,
                      color: posColor,
                      isDark: isDark,
                      child: _buildDefinitionCard(isDark, posColor),
                    ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Afaan Oromoo Translation',
                    icon: Icons.translate,
                    color: posColor,
                    isDark: isDark,
                    child: _buildTranslationCard(isDark, posColor),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Grammar',
                    icon: Icons.label_outline,
                    color: posColor,
                    isDark: isDark,
                    child: _buildGrammarCard(isDark, posColor),
                  ),
                  if (_relatedWords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'More ${widget.word.partOfSpeech}s',
                      icon: Icons.grid_view_outlined,
                      color: posColor,
                      isDark: isDark,
                      child: _buildRelatedWords(isDark, posColor),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildActionRow(isDark, posColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, Color posColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : posColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        ValueListenableBuilder<Set<String>>(
          valueListenable: AppSession.instance.favoritesNotifier,
          builder: (_, favs, __) {
            final saved = favs.contains(widget.word.english.toLowerCase());
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  key: ValueKey(saved),
                  color: saved ? Colors.amber : Colors.white,
                ),
              ),
              onPressed: _toggleFavorite,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: _shareWord,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                posColor,
                posColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.word.partOfSpeech.isNotEmpty
                          ? widget.word.partOfSpeech
                          : 'word',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _toTitleCase(widget.word.english),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPronunciationRow(bool isDark, Color posColor) {
    return Row(
      children: [
        if (widget.word.pronunciation.isNotEmpty) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252540) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF00BFA5).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over_outlined,
                      size: 16, color: Color(0xFF00BFA5)),
                  const SizedBox(width: 8),
                  Text(
                    '/${widget.word.pronunciation}/',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: const Color(0xFF00BFA5),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        // TTS Button
        GestureDetector(
          onTap: _speakWord,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _isSpeaking ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSpeaking
                        ? [const Color(0xFF00BFA5), const Color(0xFF00897B)]
                        : [posColor, posColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpeaking
                          ? const Color(0xFF00BFA5)
                          : posColor)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isSpeaking ? Icons.volume_up : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildDefinitionCard(bool isDark, Color posColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: posColor.withOpacity(0.15)),
      ),
      child: Text(
        widget.word.englishDefinition,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          height: 1.6,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTranslationCard(bool isDark, Color posColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            posColor.withOpacity(isDark ? 0.15 : 0.08),
            posColor.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: posColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Afaan Oromoo',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: posColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _toTitleCase(widget.word.oromoTranslation),
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarCard(bool isDark, Color posColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: posColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          _GrammarChip(
            label: 'Part of Speech',
            value: widget.word.partOfSpeech.isNotEmpty
                ? widget.word.partOfSpeech
                : 'Unknown',
            color: posColor,
            isDark: isDark,
          ),
          if (widget.word.pronunciation.isNotEmpty) ...[
            const SizedBox(width: 12),
            _GrammarChip(
              label: 'Pronunciation',
              value: widget.word.pronunciation,
              color: const Color(0xFF00BFA5),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedWords(bool isDark, Color posColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _relatedWords.map((w) {
        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => WordDetailScreen(
                  word: w,
                  allWords: widget.allWords,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252540) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: posColor.withOpacity(0.2)),
            ),
            child: Text(
              _toTitleCase(w.english),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: posColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionRow(bool isDark, Color posColor) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.copy_outlined,
            label: 'Copy',
            color: posColor,
            isDark: isDark,
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: '${widget.word.english}: ${widget.word.oromoTranslation}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied!', style: GoogleFonts.dmSans()),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            color: const Color(0xFF4A90D9),
            isDark: isDark,
            onTap: _shareWord,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: AppSession.instance.favoritesNotifier,
            builder: (_, favs, __) {
              final saved = favs.contains(widget.word.english.toLowerCase());
              return _ActionButton(
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                label: saved ? 'Saved' : 'Save',
                color: const Color(0xFFD4A017),
                isDark: isDark,
                onTap: _toggleFavorite,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GrammarChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _GrammarChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}