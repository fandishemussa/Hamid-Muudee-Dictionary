import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../widgets/word_of_day_notification_card.dart';

/// Standalone showcase for every WordOfDayNotificationCard variant.
/// Add a nav route to this during development:
///   Navigator.push(ctx, MaterialPageRoute(builder: (_) => const WotDDemoScreen()));
class WotDDemoScreen extends StatefulWidget {
  const WotDDemoScreen({super.key});

  @override
  State<WotDDemoScreen> createState() => _WotDDemoScreenState();
}

class _WotDDemoScreenState extends State<WotDDemoScreen> {
  // ── Sample words covering different parts of speech ───────────────
  static final _samples = [
    Word(
      english: 'Resilience',
      pronunciation: 'rɪˈzɪl.i.əns',
      partOfSpeech: 'noun',
      englishDefinition:
      'The capacity to recover quickly from difficulties; toughness and the ability to spring back into shape.',
      oromoTranslation: 'Obsaa jabaa',
    ),
    Word(
      english: 'Illuminate',
      pronunciation: 'ɪˈluː.mɪ.neɪt',
      partOfSpeech: 'verb',
      englishDefinition:
      'To light up or make something clearer and easier to understand.',
      oromoTranslation: 'Ibsuu',
    ),
    Word(
      english: 'Serene',
      pronunciation: 'səˈriːn',
      partOfSpeech: 'adjective',
      englishDefinition:
      'Calm, peaceful, and untroubled; tranquil in nature or appearance.',
      oromoTranslation: 'Nagayaa',
    ),
    Word(
      english: 'Swiftly',
      pronunciation: 'ˈswɪft.li',
      partOfSpeech: 'adverb',
      englishDefinition: 'In a quick and rapid manner; without delay.',
      oromoTranslation: 'Ariitiin',
    ),
  ];

  int _sampleIndex = 0;
  bool _showLoading = false;

  Word get _current => _samples[_sampleIndex];

  void _nextSample() =>
      setState(() => _sampleIndex = (_sampleIndex + 1) % _samples.length);

  void _toggleLoading() => setState(() => _showLoading = !_showLoading);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFBF0),
      appBar: AppBar(
        title: Text('WotD Card Showcase',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        actions: [
          // Cycle sample word
          IconButton(
            tooltip: 'Next sample word',
            icon: const Icon(Icons.refresh),
            onPressed: _nextSample,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Controls bar ────────────────────────────────────────
            _ControlsBar(
              isDark: isDark,
              primary: primary,
              showLoading: _showLoading,
              onToggleLoading: _toggleLoading,
              onShowOverlay: () => WordOfDayNotificationCard.showOverlay(
                context,
                word: _current,
                streakDays: 7,
                onLearnMore: () => _snack('Navigating to detail…'),
              ),
            ),

            // ── Section: Full card (default) ─────────────────────────
            _SectionLabel(
              label: '1 · Full inline card',
              sub: 'Default mode — embed in any Column',
              isDark: isDark,
            ),
            WordOfDayNotificationCard(
              word: _showLoading ? null : _current,
              streakDays: 12,
              onLearnMore: () => _snack('→ WordDetailScreen'),
              onDismiss: () => _snack('Card dismissed'),
              onSpeak: () => _snack('🔊 Speaking: ${_current.english}'),
            ),

            // ── Section: Auto-reveal ────────────────────────────────
            _SectionLabel(
              label: '2 · Auto-reveal (autoReveal: true)',
              sub: 'Translation shown immediately — good for review mode',
              isDark: isDark,
            ),
            WordOfDayNotificationCard(
              word: _showLoading ? null : _samples[1 % _samples.length],
              streakDays: 30,
              autoReveal: true,
              showStreakBadge: true,
              onLearnMore: () => _snack('→ WordDetailScreen'),
            ),

            // ── Section: No streak badge ────────────────────────────
            _SectionLabel(
              label: '3 · No streak badge',
              sub: 'showStreakBadge: false — use when streak shown elsewhere',
              isDark: isDark,
            ),
            WordOfDayNotificationCard(
              word: _showLoading ? null : _samples[2 % _samples.length],
              streakDays: 5,
              showStreakBadge: false,
              onLearnMore: () => _snack('→ WordDetailScreen'),
            ),

            // ── Section: Compact banner ─────────────────────────────
            // (uses the sibling WordOfDayCard widget in compact mode)
            _SectionLabel(
              label: '4 · Compact banner strip',
              sub: 'Use at the top of DictionaryScreen or as a pinned header',
              isDark: isDark,
            ),
            _CompactBannerPreview(
                word: _showLoading ? null : _current,
                isDark: isDark,
                primary: primary),

            // ── Section: Overlay trigger info ───────────────────────
            _SectionLabel(
              label: '5 · Floating overlay',
              sub: 'Tap the button above — slides in from top, auto-dismisses in 8s',
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                  isDark ? const Color(0xFF252540) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A5C)
                          : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How the overlay works:',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    const SizedBox(height: 10),
                    ...[
                      'Inserted via Overlay.of(context).insert()',
                      'Slides in from the top (SlideTransition + FadeTransition)',
                      'Auto-dismisses after 8 seconds',
                      'Swipe up to dismiss manually',
                      'Tapping "Full Details" closes the overlay then navigates',
                      'Called once per session from HomeScreen._loadDictionary()',
                    ].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14,
                              color: primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade700)),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // ── Section: Streak badge variants ──────────────────────
            _SectionLabel(
              label: '6 · Streak badge variants',
              sub: '< 7 days = red-orange ⚡  |  7-29 = orange 🔥  |  30+ = gold 🏆',
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BadgePreview(days: 3, isDark: isDark),
                  _BadgePreview(days: 14, isDark: isDark),
                  _BadgePreview(days: 45, isDark: isDark),
                  _BadgePreview(days: 100, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans()),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controls bar
// ─────────────────────────────────────────────────────────────────────────────
class _ControlsBar extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool showLoading;
  final VoidCallback onToggleLoading;
  final VoidCallback onShowOverlay;

  const _ControlsBar({
    required this.isDark,
    required this.primary,
    required this.showLoading,
    required this.onToggleLoading,
    required this.onShowOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? const Color(0xFF3A3A5C) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Skeleton toggle
          GestureDetector(
            onTap: onToggleLoading,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: showLoading
                    ? const Color(0xFF7B68EE).withOpacity(0.15)
                    : (isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: showLoading
                        ? const Color(0xFF7B68EE).withOpacity(0.4)
                        : Colors.transparent),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  showLoading
                      ? Icons.hourglass_empty
                      : Icons.hourglass_full,
                  size: 14,
                  color: showLoading
                      ? const Color(0xFF7B68EE)
                      : (isDark ? Colors.white38 : Colors.grey.shade500),
                ),
                const SizedBox(width: 6),
                Text(
                  showLoading ? 'Hide skeleton' : 'Show skeleton',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: showLoading
                          ? const Color(0xFF7B68EE)
                          : (isDark
                          ? Colors.white54
                          : Colors.grey.shade600)),
                ),
              ]),
            ),
          ),
          const Spacer(),
          // Overlay trigger
          GestureDetector(
            onTap: onShowOverlay,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.notification_important_outlined,
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('Show overlay',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact banner preview wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _CompactBannerPreview extends StatelessWidget {
  final Word? word;
  final bool isDark;
  final Color primary;

  const _CompactBannerPreview(
      {required this.word, required this.isDark, required this.primary});

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
    w.isNotEmpty
        ? w[0].toUpperCase() + w.substring(1).toLowerCase()
        : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (word == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252540) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [primary, primary.withOpacity(0.75)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Center(
              child: Text('☀️', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Word of the Day',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 0.5)),
                Text(_tc(word!.english),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          child: Text('Learn',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final String sub;
  final bool isDark;

  const _SectionLabel(
      {required this.label, required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(sub,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                color:
                isDark ? Colors.white38 : Colors.grey.shade500)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak badge preview
// ─────────────────────────────────────────────────────────────────────────────
class _BadgePreview extends StatelessWidget {
  final int days;
  final bool isDark;

  const _BadgePreview({required this.days, required this.isDark});

  Color get _color {
    if (days >= 30) return const Color(0xFFD4A017);
    if (days >= 7) return const Color(0xFFFF8C00);
    return const Color(0xFFFF6B35);
  }

  String get _emoji {
    if (days >= 30) return '🏆';
    if (days >= 7) return '🔥';
    return '⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_color, _color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _color.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        Text(_emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text('$days d',
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ]),
    );
  }
}