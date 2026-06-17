import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../screens/flashcard_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/word_detail_screen.dart';
import '../services/app_session.dart';
import '../themes/app_sizing.dart';
import '../widgets/word_of_day_notification_card.dart';

class LearnScreen extends StatefulWidget {
  final List<Word> words;
  final VoidCallback? onFavoriteChanged;   // ← bubbles up to HomeScreen

  const LearnScreen({
    super.key,
    required this.words,
    this.onFavoriteChanged,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final session = AppSession.instance;

  Word get _wordOfDay {
    if (widget.words.isEmpty) {
      return Word(english: 'Loading…', oromoTranslation: '', englishDefinition: '', partOfSpeech: '', pronunciation: '');
    }
    return widget.words[DateTime.now().day % widget.words.length];
  }

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
  }

  void _launchFlashcards(int count) {
    if (widget.words.isEmpty) return;
    final words = (List<Word>.from(widget.words)..shuffle()).take(count).toList();
    Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardScreen(words: words)))
        .then((_) {
      setState(() {});
      widget.onFavoriteChanged?.call();
    });
  }

  void _showQuizLauncher() {
    QuizDifficulty selectedDiff = QuizDifficulty.easy;
    QuizDirection selectedDir = QuizDirection.englishToOromo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primary = Theme.of(context).colorScheme.primary;

        return StatefulBuilder(builder: (ctx, setModal) {
          return Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 20),
                Text('Start a Quiz', style: GoogleFonts.playfairDisplay(
                    fontSize: 24, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                Text('Choose difficulty and direction', style: GoogleFonts.dmSans(
                    fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                const SizedBox(height: 24),

                // Difficulty
                Text('Difficulty', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Row(children: QuizDifficulty.values.map((d) {
                  final colors = {
                    QuizDifficulty.easy: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
                    QuizDifficulty.medium: [const Color(0xFFFFB300), const Color(0xFFFF8C00)],
                    QuizDifficulty.hard: [const Color(0xFFFF5722), const Color(0xFFE91E63)],
                  };
                  final icons = {
                    QuizDifficulty.easy: Icons.sentiment_satisfied_outlined,
                    QuizDifficulty.medium: Icons.sentiment_neutral_outlined,
                    QuizDifficulty.hard: Icons.local_fire_department_outlined,
                  };
                  final descs = {
                    QuizDifficulty.easy: '20s · 3 opts',
                    QuizDifficulty.medium: '15s · 4 opts',
                    QuizDifficulty.hard: '10s · 4 opts',
                  };
                  final sel = selectedDiff == d;
                  final cols = colors[d]!;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); setModal(() => selectedDiff = d); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: sel ? LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                          color: sel ? null : (isDark ? const Color(0xFF252540) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? Colors.transparent : (isDark ? const Color(0xFF3A3A5C) : Colors.grey.shade200)),
                          boxShadow: sel ? [BoxShadow(color: cols.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                        ),
                        child: Column(children: [
                          Icon(icons[d], size: 22, color: sel ? Colors.white : (isDark ? Colors.white54 : Colors.grey)),
                          const SizedBox(height: 6),
                          Text(d.name[0].toUpperCase() + d.name.substring(1),
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF374151)))),
                          Text(descs[d]!, style: GoogleFonts.dmSans(fontSize: 10,
                              color: sel ? Colors.white.withOpacity(0.7) : (isDark ? Colors.white38 : Colors.grey.shade500))),
                        ]),
                      ),
                    ),
                  );
                }).toList()),

                const SizedBox(height: 24),

                // Direction
                Text('Direction', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Row(children: QuizDirection.values.map((dir) {
                  final sel = selectedDir == dir;
                  final label = dir == QuizDirection.englishToOromo
                      ? 'EN → Oromo'
                      : 'Oromo → EN';
                  final icon = dir == QuizDirection.englishToOromo
                      ? Icons.arrow_forward
                      : Icons.arrow_back;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); setModal(() => selectedDir = dir); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: dir == QuizDirection.englishToOromo ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: sel ? primary : (isDark ? const Color(0xFF252540) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? Colors.transparent : (isDark ? const Color(0xFF3A3A5C) : Colors.grey.shade200)),
                          boxShadow: sel ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(icon, size: 14, color: sel ? Colors.white : (isDark ? Colors.white54 : Colors.grey)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(label,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade600))),
                          ),
                        ]),
                      ),
                    ),
                  );
                }).toList()),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Start Quiz', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.words.length < 4) return;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => QuizScreen(words: widget.words, difficulty: selectedDiff, direction: selectedDir),
                      )).then((_) {
                        setState(() {});
                        widget.onFavoriteChanged?.call();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final s = AppSizing.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(s.screenPaddingH, s.md, s.screenPaddingH, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(isDark, primary),
          const SizedBox(height: 20),
          _buildWordOfDay(isDark, primary),
          const SizedBox(height: 24),
          _sectionTitle('Flashcards', isDark),
          const SizedBox(height: 10),
          _buildFlashcardRow(),
          const SizedBox(height: 24),
          _sectionTitle('Quiz Modes', isDark),
          const SizedBox(height: 10),
          _buildQuizLaunchCard(isDark, primary),
        ],
      ),
    );
  }

  Widget _buildTopRow(bool isDark, Color primary) {
    final streak = session.streakDays;
    final progress = session.dailyGoalProgress;
    final viewed = session.wordsViewedToday;
    final goal = session.dailyWordGoal;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Streak pill — capped width so it never pushes out goal card
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: streak > 0
                      ? [const Color(0xFFFF6B35), const Color(0xFFFF8C00)]
                      : [isDark ? const Color(0xFF252540) : Colors.grey.shade100,
                    isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade50],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$streak d',   // shortened to prevent overflow
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700,
                            color: streak > 0 ? Colors.white : Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Streak', style: GoogleFonts.dmSans(fontSize: 10,
                          color: streak > 0 ? Colors.white.withOpacity(0.75) : Colors.grey.shade400)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // Daily goal — takes all remaining space
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252540) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withOpacity(0.12)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text('Daily Goal', overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF1A1A2E))),
                  ),
                  Text('$viewed/$goal', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700,
                      color: progress >= 1.0 ? Colors.green : primary)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.green : primary),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordOfDay(bool isDark, Color primary) {
    final w = widget.words.isEmpty ? null : _wordOfDay;
    return WordOfDayNotificationCard(
      word: w,
      streakDays: session.streakDays,
      showStreakBadge: false,
      onLearnMore: w == null
          ? null
          : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WordDetailScreen(word: w, allWords: widget.words),
        ),
      ).then((_) {
        setState(() {});
        widget.onFavoriteChanged?.call(); // word detail may have toggled bookmark
      }),
    );
  }

  Widget _buildFlashcardRow() {
    final cards = [
      _FCD('Quick 5', '5 random words', Icons.bolt, [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], 5),
      _FCD('Daily 10', '10 random words', Icons.style_outlined, [const Color(0xFFF093FB), const Color(0xFFF5576C)], 10),
      _FCD('Big 20', '20 word sprint', Icons.local_fire_department_outlined, [const Color(0xFFFF6B35), const Color(0xFFFF8C00)], 20),
    ];
    return Row(
      children: cards.map((c) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: c == cards.last ? 0 : 10),
          child: GestureDetector(
            onTap: () => _launchFlashcards(c.count),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: c.colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(children: [
                Icon(c.icon, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(c.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(c.sub, style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.75)), textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildQuizLaunchCard(bool isDark, Color primary) {
    return GestureDetector(
      onTap: _showQuizLauncher,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Take a Quiz', style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Choose difficulty · timed questions · streak tracking',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.75))),
              const SizedBox(height: 8),
              Row(children: [
                _DiffBadge('Easy', const Color(0xFF43E97B)),
                const SizedBox(width: 6),
                _DiffBadge('Medium', const Color(0xFFFFB300)),
                const SizedBox(width: 6),
                _DiffBadge('Hard', const Color(0xFFFF5722)),
              ]),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t, bool isDark) => Text(t,
      style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E)));
}

class _FCD {
  final String label, sub;
  final IconData icon;
  final List<Color> colors;
  final int count;
  const _FCD(this.label, this.sub, this.icon, this.colors, this.count);
}

class _DiffBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _DiffBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}