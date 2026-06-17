import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_session.dart';
import '../themes/app_sizing.dart';
import '../models/word.dart';
import 'word_detail_screen.dart';

class StatsScreen extends StatefulWidget {
  final List<Word> allWords;
  const StatsScreen({super.key, this.allWords = const []});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final session = AppSession.instance;

  @override
  void initState() {
    super.initState();
    session.resetDailyIfNeeded();
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
          _buildStreakHero(isDark, primary),
          const SizedBox(height: 20),
          _buildStatsGrid(isDark),
          const SizedBox(height: 20),
          _buildDailyGoalCard(isDark, primary),
          const SizedBox(height: 20),
          _buildAccuracyCard(isDark, primary),
          const SizedBox(height: 24),
          if (session.recentWords.isNotEmpty) ...[
            _sectionTitle('Recently Viewed', isDark),
            const SizedBox(height: 10),
            _buildRecentWords(isDark, primary),
            const SizedBox(height: 24),
          ],
          _buildWeeklyActivity(isDark, primary),
        ],
      ),
    );
  }

  Widget _buildStreakHero(bool isDark, Color primary) {
    final streak = session.streakDays;
    final active = streak > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [const Color(0xFFFF6B35), const Color(0xFFD4A017)]
              : isDark
              ? [const Color(0xFF252540), const Color(0xFF1A1A2E)]
              : [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: active
            ? [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]
            : [],
      ),
      child: Row(
        children: [
          // Emoji circle — shrink on small screens
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(active ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(active ? '🔥' : '💤', style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak ${streak == 1 ? "Day" : "Days"}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28, fontWeight: FontWeight.w700,
                    color: active ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  active ? 'Keep going!' : 'Open a word to start!',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: active ? Colors.white.withOpacity(0.85) : (isDark ? Colors.white38 : Colors.grey.shade500),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (active) ...[
                  const SizedBox(height: 8),
                  _nextMilestone(streak),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextMilestone(int streak) {
    final milestones = [3, 7, 14, 30, 60, 100];
    final next = milestones.firstWhere((m) => m > streak, orElse: () => 0);
    return Row(
      children: [
        const Icon(Icons.flag_outlined, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          next > 0 ? 'Next milestone: $next days' : '🏆 100+ day legend!',
          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final items = [
      _SD('Words Viewed', '${session.wordsViewedToday}', Icons.visibility_outlined, const Color(0xFF4A90D9), 'today'),
      _SD('Quizzes Done', '${session.quizzesCompletedToday}', Icons.quiz_outlined, const Color(0xFF7B68EE), 'today'),
      _SD('Correct', '${session.correctAnswersTotal}', Icons.check_circle_outline, const Color(0xFF43E97B), 'all time'),
      _SD('Answered', '${session.totalAnswers}', Icons.bolt_outlined, const Color(0xFFFF8C00), 'all time'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _StatCard(data: items[i], isDark: isDark),
    );
  }

  Widget _buildDailyGoalCard(bool isDark, Color primary) {
    final viewed = session.wordsViewedToday;
    final goal = session.dailyWordGoal;
    final progress = session.dailyGoalProgress;
    final done = progress >= 1.0;
    final col = done ? Colors.green : primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(done ? Icons.check_circle : Icons.flag_outlined, color: col, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Goal',
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    Text(done ? 'Completed! 🎉' : '$viewed / $goal words',
                        style: GoogleFonts.dmSans(fontSize: 12, color: done ? Colors.green : (isDark ? Colors.white38 : Colors.grey))),
                  ],
                ),
              ),
              Text('${(progress * 100).clamp(0, 100).round()}%',
                  style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: col)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, minHeight: 10,
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(col),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Goal: ', style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
              const SizedBox(width: 4),
              ...[5, 10, 15, 20].map((g) => GestureDetector(
                onTap: () {
                  session.setDailyGoal(g);
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.dailyWordGoal == g ? primary : (isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$g', style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: session.dailyWordGoal == g ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
                  )),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard(bool isDark, Color primary) {
    final accuracy = session.accuracyPercent;
    final total = session.totalAnswers;
    final correct = session.correctAnswersTotal;
    final wrong = total - correct;
    final col = accuracy >= 80 ? const Color(0xFF43E97B) : accuracy >= 60 ? const Color(0xFFFFB300) : const Color(0xFFFF5722);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.analytics_outlined, color: col, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Quiz Accuracy', style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              const Spacer(),
              Text('${accuracy.round()}%', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: col)),
            ],
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Complete a quiz to see accuracy',
                  style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? Colors.white30 : Colors.grey.shade400)),
            ))
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  if (correct > 0) Expanded(flex: correct, child: Container(height: 10, color: Colors.green)),
                  if (wrong > 0) Expanded(flex: wrong.clamp(1, 9999), child: Container(height: 10, color: Colors.red.shade300)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _Dot(color: Colors.green, label: '$correct correct'),
              const SizedBox(width: 16),
              _Dot(color: Colors.red.shade300, label: '$wrong wrong'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentWords(bool isDark, Color primary) {
    final recents = session.recentWords.take(10).toList();
    final wordMap = {for (final w in widget.allWords) w.english.toLowerCase(): w};
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recents.length,
        itemBuilder: (context, i) {
          final eng = recents[i];
          final word = wordMap[eng.toLowerCase()];
          return GestureDetector(
            onTap: word == null ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => WordDetailScreen(word: word, allWords: widget.allWords)))
                .then((_) => setState(() {})),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252540) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.15)),
              ),
              child: Text(_tc(eng), style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: primary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyActivity(bool isDark, Color primary) {
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayWd = DateTime.now().weekday; // 1=Mon

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('This Week', isDark),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252540) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final isToday = dayNum == todayWd;
              final isPast = dayNum < todayWd;
              final isActive = isToday
                  ? session.wordsViewedToday > 0
                  : (isPast && session.streakDays > (todayWd - dayNum));
              return Expanded(
                child: Column(
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      final size = (constraints.maxWidth - 8).clamp(24.0, 36.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: size, height: size,
                        decoration: BoxDecoration(
                          color: isActive ? primary : isToday ? primary.withOpacity(0.15)
                              : (isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100),
                          shape: BoxShape.circle,
                          border: isToday ? Border.all(color: primary, width: 2) : null,
                        ),
                        child: Center(
                          child: isActive
                              ? Icon(Icons.check, color: Colors.white, size: size * 0.45)
                              : Text(dayLabels[i][0], style: GoogleFonts.dmSans(
                              fontSize: size * 0.32, fontWeight: FontWeight.w600,
                              color: isToday ? primary : (isDark ? Colors.white38 : Colors.grey.shade400))),
                        ),
                      );
                    }),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(dayLabels[i], style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: isToday ? primary : (isDark ? Colors.white38 : Colors.grey.shade400),
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      )),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t, bool isDark) => Text(t,
      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E)));

  String _tc(String s) => s.isEmpty ? s : s.split(' ').map((w) =>
  w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
}

class _SD {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _SD(this.label, this.value, this.icon, this.color, this.sub);
}

class _StatCard extends StatelessWidget {
  final _SD data;
  final bool isDark;
  const _StatCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm + 4, vertical: s.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, size: 16, color: data.color),
          ),
          SizedBox(width: s.xs + 3),
          // Text — takes remaining width
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.value,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: s.fontXl,
                    fontWeight: FontWeight.w700,
                    color: data.color,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  data.label,
                  style: GoogleFonts.dmSans(
                    fontSize: s.fontXs,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.sub,
                  style: GoogleFonts.dmSans(
                    fontSize: s.fontXs - 1,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
    ]);
  }
}