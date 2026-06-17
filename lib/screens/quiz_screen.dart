import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../services/app_session.dart';
import '../themes/app_sizing.dart';

enum QuizDifficulty { easy, medium, hard }
enum QuizDirection { englishToOromo, oromoToEnglish }

class QuizScreen extends StatefulWidget {
  final List<Word> words;
  final QuizDifficulty difficulty;
  final QuizDirection direction;

  const QuizScreen({
    super.key,
    required this.words,
    this.difficulty = QuizDifficulty.easy,
    this.direction = QuizDirection.englishToOromo,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // Quiz state
  int _questionIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _isFinished = false;
  late List<_QuizQuestion> _questions;

  // Timer
  late AnimationController _timerController;
  int _secondsLeft = 0;
  Timer? _countdownTimer;

  // Feedback animation
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;

  // Results animation
  late AnimationController _resultsController;

  int get _totalQuestions => _questions.length;
  _QuizQuestion get _current => _questions[_questionIndex];

  int get _timeLimit {
    switch (widget.difficulty) {
      case QuizDifficulty.easy: return 20;
      case QuizDifficulty.medium: return 15;
      case QuizDifficulty.hard: return 10;
    }
  }

  int get _optionCount {
    switch (widget.difficulty) {
      case QuizDifficulty.easy: return 3;
      case QuizDifficulty.medium: return 4;
      case QuizDifficulty.hard: return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    _buildQuestions();

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeLimit),
    );
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _feedbackScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );
    _resultsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _startQuestion();
  }

  void _buildQuestions() {
    final rng = Random();
    final shuffled = List<Word>.from(widget.words)..shuffle(rng);
    final questionWords = shuffled.take(10).toList();

    _questions = questionWords.map((word) {
      // Wrong answers pool
      final others = widget.words
          .where((w) => w.english != word.english)
          .toList()..shuffle(rng);
      final wrongCount = _optionCount - 1;

      final wrongOptions = widget.direction == QuizDirection.englishToOromo
          ? others.take(wrongCount).map((w) => w.oromoTranslation).toList()
          : others.take(wrongCount).map((w) => w.english).toList();

      final correct = widget.direction == QuizDirection.englishToOromo
          ? word.oromoTranslation
          : word.english;

      final options = [correct, ...wrongOptions]..shuffle(rng);

      return _QuizQuestion(
        word: word,
        question: widget.direction == QuizDirection.englishToOromo
            ? word.english
            : word.oromoTranslation,
        correctAnswer: correct,
        options: options,
      );
    }).toList();
  }

  void _startQuestion() {
    setState(() {
      _selectedAnswer = null;
      _answered = false;
      _secondsLeft = _timeLimit;
    });
    _timerController.reset();
    _timerController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (!_answered) _autoTimeout();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _autoTimeout() {
    if (_answered) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _answered = true;
      _streak = 0;
    });
    AppSession.instance.recordQuizAnswer(correct: false);
    _feedbackController.forward(from: 0);
    _scheduleNext();
  }

  void _answerQuestion(String answer) {
    if (_answered) return;
    _countdownTimer?.cancel();
    _timerController.stop();

    final isCorrect = answer == _current.correctAnswer;
    HapticFeedback.selectionClick();
    if (isCorrect) HapticFeedback.mediumImpact();

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) {
        _score++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });

    AppSession.instance.recordQuizAnswer(correct: isCorrect);
    _feedbackController.forward(from: 0);
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_questionIndex >= _totalQuestions - 1) {
        AppSession.instance.recordQuizCompleted();
        setState(() => _isFinished = true);
        _resultsController.forward();
      } else {
        setState(() => _questionIndex++);
        _startQuestion();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timerController.dispose();
    _feedbackController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  Color get _difficultyColor {
    switch (widget.difficulty) {
      case QuizDifficulty.easy: return const Color(0xFF43E97B);
      case QuizDifficulty.medium: return const Color(0xFFFFB300);
      case QuizDifficulty.hard: return const Color(0xFFFF5722);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isFinished) return _buildResults(isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFBF0),
      appBar: _buildAppBar(isDark),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final isCompact = h < 620;
            final gap = isCompact ? 6.0 : 12.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, isCompact ? 4 : 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Compact header: progress + scores in one row ──
                  _buildCompactHeader(isDark, isCompact),
                  SizedBox(height: gap),
                  // ── Timer bar ─────────────────────────────────────
                  _buildTimerBar(isDark),
                  SizedBox(height: gap),
                  // ── Question card (flexible) ──────────────────────
                  Expanded(child: _buildQuestionCard(isDark)),
                  SizedBox(height: gap),
                  // ── Answer tiles ──────────────────────────────────
                  ..._current.options.map(
                          (opt) => _buildAnswerTile(opt, isDark, compact: isCompact)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Single compact header row combining progress bar + score chips.
  Widget _buildCompactHeader(bool isDark, bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: question count + score chips
        Row(
          children: [
            Text(
              '${_questionIndex + 1} / $_totalQuestions',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            // Score chip
            _ScoreChip(icon: Icons.star, value: '$_score',
                color: const Color(0xFFD4A017), isDark: isDark),
            const SizedBox(width: 6),
            // Streak chip
            _ScoreChip(icon: Icons.bolt, value: '$_streak',
                color: const Color(0xFFFF5722), isDark: isDark),
            const SizedBox(width: 6),
            // Best chip
            _ScoreChip(icon: Icons.emoji_events, value: '$_bestStreak',
                color: const Color(0xFF7B68EE), isDark: isDark),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_questionIndex + 1) / _totalQuestions,
            backgroundColor:
            isDark ? const Color(0xFF252540) : Colors.grey.shade200,
            color: _difficultyColor,
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        onPressed: () => _showQuitDialog(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _difficultyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.difficulty.name.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _difficultyColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildTimerBar(bool isDark) {
    final timerColor = _secondsLeft <= 5
        ? Colors.red
        : _secondsLeft <= 10
        ? Colors.orange
        : _difficultyColor;

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 16, color: timerColor),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _timerController,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 - _timerController.value,
                backgroundColor:
                isDark ? const Color(0xFF252540) : Colors.grey.shade200,
                color: timerColor,
                minHeight: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            '${_secondsLeft}s',
            key: ValueKey(_secondsLeft),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: timerColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    return ScaleTransition(
      scale: _feedbackScale,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2D2D5A), const Color(0xFF1A1A3E)]
                : [Colors.white, const Color(0xFFFFF8E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _answered
                ? (_selectedAnswer == _current.correctAnswer
                ? Colors.green.withOpacity(0.4)
                : Colors.red.withOpacity(0.4))
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.direction == QuizDirection.englishToOromo
                    ? 'What is the Afaan Oromoo for:'
                    : 'What is the English for:',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _toTitleCase(_current.question),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              if (_current.word.pronunciation.isNotEmpty &&
                  widget.direction == QuizDirection.englishToOromo) ...[
                const SizedBox(height: 6),
                Text(
                  '/${_current.word.pronunciation}/',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF00BFA5),
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
              if (_answered) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedAnswer == _current.correctAnswer
                          ? Icons.check_circle
                          : _selectedAnswer == null
                          ? Icons.timer_off
                          : Icons.cancel,
                      color: _selectedAnswer == _current.correctAnswer
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _selectedAnswer == _current.correctAnswer
                            ? _streak > 1 ? '🔥 ${_streak}x Streak!' : 'Correct!'
                            : _selectedAnswer == null
                            ? 'Time\'s up!'
                            : 'Answer: ${_toTitleCase(_current.correctAnswer)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedAnswer == _current.correctAnswer
                              ? Colors.green
                              : Colors.red,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),  // Column
        ),    // SingleChildScrollView
      ),
    );
  }

  Widget _buildAnswerTile(String option, bool isDark, {bool compact = false}) {
    Color? borderColor;
    Color? bgColor;
    Widget? trailingIcon;

    if (_answered) {
      if (option == _current.correctAnswer) {
        bgColor = Colors.green.withOpacity(0.12);
        borderColor = Colors.green;
        trailingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
      } else if (option == _selectedAnswer) {
        bgColor = Colors.red.withOpacity(0.12);
        borderColor = Colors.red;
        trailingIcon = const Icon(Icons.cancel, color: Colors.red, size: 20);
      }
    }

    return GestureDetector(
      onTap: () => _answerQuestion(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: compact ? 6 : 10),
        padding: EdgeInsets.symmetric(
            horizontal: 16, vertical: compact ? 10 : 14),
        decoration: BoxDecoration(
          color: bgColor ?? (isDark ? const Color(0xFF252540) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor ??
                (isDark ? const Color(0xFF3A3A5C) : Colors.grey.shade200),
            width: borderColor != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _toTitleCase(option),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    final percentage = (_score / _totalQuestions * 100).round();
    final grade = percentage >= 90
        ? 'Excellent! 🏆'
        : percentage >= 70
        ? 'Great job! 🎉'
        : percentage >= 50
        ? 'Good effort! 💪'
        : 'Keep practicing! 📚';

    final gradeColor = percentage >= 90
        ? const Color(0xFFD4A017)
        : percentage >= 70
        ? const Color(0xFF43E97B)
        : percentage >= 50
        ? const Color(0xFF4A90D9)
        : const Color(0xFFFF5722);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFBF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Trophy
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  percentage >= 70 ? Icons.emoji_events : Icons.school,
                  size: 48,
                  color: gradeColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                grade,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: gradeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quiz Complete',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 32),

              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [gradeColor, gradeColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradeColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$_score / $_totalQuestions',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Stats grid
              Row(
                children: [
                  Expanded(child: _ResultStat(label: 'Best Streak', value: '🔥 $_bestStreak', isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _ResultStat(label: 'Difficulty', value: widget.difficulty.name, isDark: isDark)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ResultStat(label: 'Time Limit', value: '${_timeLimit}s/q', isDark: isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _ResultStat(
                    label: 'Direction',
                    value: widget.direction == QuizDirection.englishToOromo ? 'EN → OR' : 'OR → EN',
                    isDark: isDark,
                  )),
                ],
              ),

              const SizedBox(height: 32),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text('Try Again', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          words: widget.words,
                          difficulty: widget.difficulty,
                          direction: widget.direction,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Back to Learn', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quit Quiz?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text('Your progress will be lost.', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Quit', style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
  }
}

class _QuizQuestion {
  final Word word;
  final String question;
  final String correctAnswer;
  final List<String> options;

  const _QuizQuestion({
    required this.word,
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}

/// Compact inline chip for score/streak/best shown in the header row.
class _ScoreChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final bool isDark;

  const _ScoreChip({
    required this.icon,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isText;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: isText
                ? GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)
                : GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _ResultStat({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }
}
