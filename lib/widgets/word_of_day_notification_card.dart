import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../services/app_session.dart';
import '../services/tts_service.dart';
import '../services/share_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USAGE
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. In-line inside a Column / page:
//
//      WordOfDayNotificationCard(
//        word: myWord,
//        streakDays: 5,
//        onLearnMore: () => Navigator.push(...),
//        onDismiss: () {},
//      )
//
// 2. As a floating overlay (slides in from the top):
//
//      WordOfDayNotificationCard.showOverlay(
//        context,
//        word: myWord,
//        streakDays: AppSession.instance.streakDays,
//        onLearnMore: () { ... },
//      );
//
// ─────────────────────────────────────────────────────────────────────────────

// ── Notification states ───────────────────────────────────────────────────────
enum _CardState { loading, visible, dismissed }

// ── Main widget ───────────────────────────────────────────────────────────────
class WordOfDayNotificationCard extends StatefulWidget {
  final Word? word;               // null → show skeleton loader
  final int streakDays;
  final VoidCallback? onLearnMore;
  final VoidCallback? onDismiss;
  final VoidCallback? onSpeak;    // wire flutter_tts here
  final bool autoReveal;          // true → show translation immediately
  final bool showStreakBadge;

  const WordOfDayNotificationCard({
    super.key,
    required this.word,
    this.streakDays = 0,
    this.onLearnMore,
    this.onDismiss,
    this.onSpeak,
    this.autoReveal = false,
    this.showStreakBadge = true,
  });

  // ── Static overlay launcher ───────────────────────────────────────
  static void showOverlay(
      BuildContext context, {
        required Word? word,
        int streakDays = 0,
        VoidCallback? onLearnMore,
        VoidCallback? onSpeak,
      }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _NotificationOverlay(
        word: word,
        streakDays: streakDays,
        onLearnMore: onLearnMore,
        onSpeak: onSpeak,
        onClose: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<WordOfDayNotificationCard> createState() =>
      _WordOfDayNotificationCardState();
}

class _WordOfDayNotificationCardState extends State<WordOfDayNotificationCard>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late AnimationController _speakController;

  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _revealAnim;
  late Animation<double> _speakAnim;

  // State
  _CardState _state = _CardState.loading;
  bool _revealed = false;
  bool _isSpeaking = false;
  double _dragOffset = 0;
  static const double _dismissThreshold = 80;

  @override
  void initState() {
    super.initState();

    // Entry animation: slide down + fade in
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<double>(begin: -40, end: 0).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.95, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack));

    // Pulse on the sun icon
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Translation reveal flip
    _revealController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _revealAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack));

    // TTS speak ripple
    _speakController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _speakAnim = Tween<double>(begin: 1, end: 1.4).animate(
        CurvedAnimation(parent: _speakController, curve: Curves.easeOut));

    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() {
      _state = widget.word != null ? _CardState.visible : _CardState.loading;
      if (widget.autoReveal) _revealed = true;
    });
    _entryController.forward();
  }

  @override
  void didUpdateWidget(covariant WordOfDayNotificationCard old) {
    super.didUpdateWidget(old);
    if (old.word == null && widget.word != null) {
      setState(() => _state = _CardState.visible);
      if (widget.autoReveal) setState(() => _revealed = true);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _revealController.dispose();
    _speakController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────
  void _reveal() {
    if (_revealed) return;
    HapticFeedback.selectionClick();
    setState(() => _revealed = true);
    _revealController.forward();
  }

  void _speak() async {
    final w = widget.word;
    if (w == null) return;
    final tts = TtsService.instance;
    if (tts.isSpeaking.value) {
      await tts.stop();
      _speakController.stop();
      _speakController.reset();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSpeaking = true);
    _speakController.repeat(reverse: true);
    widget.onSpeak?.call();
    await tts.speak(w.english);
    if (!mounted) return;
    _speakController.stop();
    _speakController.reset();
    setState(() => _isSpeaking = false);
  }

  void _share() {
    final w = widget.word;
    if (w == null) return;
    HapticFeedback.lightImpact();
    ShareService.instance.shareWordOfDay(w);
  }

  void _copy() {
    final w = widget.word;
    if (w == null) return;
    Clipboard.setData(
        ClipboardData(text: '${_tc(w.english)}: ${_tc(w.oromoTranslation)}'));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied!', style: GoogleFonts.dmSans()),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 1),
    ));
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    _entryController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _state = _CardState.dismissed);
      widget.onDismiss?.call();
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────
  String _tc(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
  }

  String _dayLabel() {
    final n = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }

  Color get _posColor {
    final pos = widget.word?.partOfSpeech.toLowerCase() ?? '';
    if (pos.contains('noun') || pos == 'n') return const Color(0xFF4A90D9);
    if (pos.contains('verb') || pos == 'v') return const Color(0xFF7B68EE);
    if (pos.contains('adj')) return const Color(0xFF00BFA5);
    if (pos.contains('adv')) return const Color(0xFFFF8C00);
    if (pos.contains('prep')) return const Color(0xFFE91E63);
    if (pos.contains('pron')) return const Color(0xFF4CAF50);
    return const Color(0xFFD4A017);
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_state == _CardState.dismissed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value + _dragOffset),
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(opacity: _fadeAnim.value, child: child),
          ),
        );
      },
      child: GestureDetector(
        onVerticalDragUpdate: (d) {
          setState(() => _dragOffset =
              (d.localPosition.dy - d.delta.dy).clamp(-_dismissThreshold * 2, 20));
        },
        onVerticalDragEnd: (d) {
          if (_dragOffset < -_dismissThreshold) {
            _dismiss();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: _state == _CardState.loading
            ? _buildSkeleton(isDark)
            : _buildCard(isDark, primary),
      ),
    );
  }

  // ── Skeleton loader ────────────────────────────────────────────────
  Widget _buildSkeleton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? const Color(0xFF3A3A5C) : Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Shimmer(width: 120, height: 22, radius: 8, isDark: isDark),
          const Spacer(),
          _Shimmer(width: 70, height: 14, radius: 6, isDark: isDark),
        ]),
        const SizedBox(height: 18),
        _Shimmer(width: 180, height: 32, radius: 8, isDark: isDark),
        const SizedBox(height: 8),
        _Shimmer(width: 90, height: 16, radius: 6, isDark: isDark),
        const SizedBox(height: 12),
        _Shimmer(width: double.infinity, height: 14, radius: 6, isDark: isDark),
        const SizedBox(height: 6),
        _Shimmer(width: 200, height: 14, radius: 6, isDark: isDark),
        const SizedBox(height: 16),
        _Shimmer(width: double.infinity, height: 46, radius: 12, isDark: isDark),
      ]),
    );
  }

  // ── Full notification card ─────────────────────────────────────────
  Widget _buildCard(bool isDark, Color primary) {
    final w = widget.word!;
    final posColor = _posColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: posColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: posColor.withOpacity(isDark ? 0.12 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured accent strip ────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [posColor, posColor.withOpacity(0.4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ─────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sun pulse
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.wb_sunny, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Word of the Day',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: primary)),
                            Text(_dayLabel(),
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: isDark ? Colors.white30 : Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      // Streak badge
                      if (widget.showStreakBadge && widget.streakDays > 0)
                        _StreakBadge(days: widget.streakDays),
                      const SizedBox(width: 6),
                      // Dismiss button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 14,
                              color: isDark ? Colors.white38 : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Word + pronunciation ───────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tc(w.english),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                height: 1.1,
                              ),
                            ),
                            if (w.pronunciation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('/${w.pronunciation}/',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: const Color(0xFF00BFA5),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                      ),
                      // TTS button
                      GestureDetector(
                        onTap: _speak,
                        child: AnimatedBuilder(
                          animation: _speakAnim,
                          builder: (_, child) => Transform.scale(
                            scale: _isSpeaking ? _speakAnim.value : 1.0,
                            child: child,
                          ),
                          child: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: _isSpeaking
                                  ? const Color(0xFF00BFA5)
                                  : posColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isSpeaking
                                    ? const Color(0xFF00BFA5)
                                    : posColor.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              _isSpeaking ? Icons.volume_up : Icons.play_arrow_rounded,
                              size: 22,
                              color: _isSpeaking ? Colors.white : posColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── POS badge ──────────────────────────────────
                  if (w.partOfSpeech.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: posColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: posColor.withOpacity(0.25)),
                      ),
                      child: Text(w.partOfSpeech.toLowerCase(),
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: posColor,
                              letterSpacing: 0.3)),
                    ),
                  ],

                  // ── English definition ─────────────────────────
                  if (w.englishDefinition.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(w.englishDefinition,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.6,
                            color: isDark ? Colors.white60 : Colors.grey.shade700),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],

                  const SizedBox(height: 14),

                  // ── Translation reveal tile ────────────────────
                  _TranslationRevealTile(
                    oromoText: _tc(w.oromoTranslation),
                    revealed: _revealed,
                    onReveal: _reveal,
                    isDark: isDark,
                    posColor: posColor,
                    revealAnim: _revealAnim,
                  ),

                  const SizedBox(height: 14),

                  // ── Action row ─────────────────────────────────
                  Row(children: [
                    if (widget.onLearnMore != null) ...[
                      Expanded(
                        flex: 3,
                        child: _ActionBtn(
                          icon: Icons.open_in_new_rounded,
                          label: 'Full Details',
                          primary: true,
                          color: posColor,
                          onTap: widget.onLearnMore!,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _ActionIconBtn(
                        icon: Icons.copy_outlined,
                        color: const Color(0xFF4A90D9),
                        tooltip: 'Copy',
                        isDark: isDark,
                        onTap: _copy),
                    const SizedBox(width: 8),
                    _ActionIconBtn(
                        icon: Icons.share_outlined,
                        color: const Color(0xFF00BFA5),
                        tooltip: 'Share',
                        isDark: isDark,
                        onTap: _share),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: AppSession.instance.favoritesNotifier,
                      builder: (_, favs, __) {
                        final saved = w != null &&
                            favs.contains(w.english.toLowerCase());
                        return _ActionIconBtn(
                          icon: saved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: const Color(0xFFD4A017),
                          tooltip: saved ? 'Saved' : 'Save',
                          isDark: isDark,
                          onTap: () {
                            if (w == null) return;
                            HapticFeedback.lightImpact();
                            final newVal = !saved;
                            w.isFavorite = newVal;
                            AppSession.instance.toggleFavorite(
                                w.english, value: newVal);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  newVal
                                      ? 'Saved to bookmarks!'
                                      : 'Removed from bookmarks',
                                  style: GoogleFonts.dmSans()),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
                              duration: const Duration(seconds: 1),
                            ));
                          },
                        );
                      },
                    ),
                  ]),

                  // ── Swipe-to-dismiss hint ──────────────────────
                  const SizedBox(height: 12),
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.keyboard_arrow_up,
                          size: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade300),
                      const SizedBox(width: 4),
                      Text('Swipe up to dismiss',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.grey.shade400)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY wrapper — slides in from top of screen, auto-dismisses after 8s
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationOverlay extends StatefulWidget {
  final Word? word;
  final int streakDays;
  final VoidCallback? onLearnMore;
  final VoidCallback? onSpeak;
  final VoidCallback onClose;

  const _NotificationOverlay({
    required this.word,
    required this.streakDays,
    required this.onClose,
    this.onLearnMore,
    this.onSpeak,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
    _ctrl.forward();
    // Auto-dismiss after 8 seconds
    _autoTimer = Timer(const Duration(seconds: 8), _close);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    _ctrl.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: WordOfDayNotificationCard(
              word: widget.word,
              streakDays: widget.streakDays,
              onLearnMore: widget.onLearnMore != null
                  ? () {
                _close();
                widget.onLearnMore!();
              }
                  : null,
              onSpeak: widget.onSpeak,
              onDismiss: _close,
              showStreakBadge: true,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSLATION REVEAL TILE  — flips from "hidden" to revealed state
// ─────────────────────────────────────────────────────────────────────────────
class _TranslationRevealTile extends StatelessWidget {
  final String oromoText;
  final bool revealed;
  final VoidCallback onReveal;
  final bool isDark;
  final Color posColor;
  final Animation<double> revealAnim;

  const _TranslationRevealTile({
    required this.oromoText,
    required this.revealed,
    required this.onReveal,
    required this.isDark,
    required this.posColor,
    required this.revealAnim,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: revealed ? null : onReveal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: revealed
              ? const Color(0xFF00BFA5).withOpacity(isDark ? 0.15 : 0.08)
              : (isDark ? const Color(0xFF252540) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: revealed
                ? const Color(0xFF00BFA5).withOpacity(0.4)
                : (isDark ? const Color(0xFF3A3A5C) : Colors.grey.shade200),
            width: revealed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                revealed ? Icons.translate : Icons.visibility_outlined,
                key: ValueKey(revealed),
                size: 18,
                color: revealed
                    ? const Color(0xFF00BFA5)
                    : (isDark ? Colors.white38 : Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                      begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: revealed
                    ? Column(
                  key: const ValueKey('revealed'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Afaan Oromoo',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: const Color(0xFF00BFA5))),
                    const SizedBox(height: 2),
                    Text(oromoText,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00BFA5))),
                  ],
                )
                    : Row(
                  key: const ValueKey('hidden'),
                  children: [
                    Expanded(
                      child: Text(
                        'Tap to reveal Afaan Oromoo translation',
                        softWrap: true,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white38
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: posColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Reveal',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: posColor)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAK BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  Color get _color {
    if (days >= 30) return const Color(0xFFD4A017); // gold
    if (days >= 7) return const Color(0xFFFF8C00);  // orange
    return const Color(0xFFFF6B35);                  // red-orange
  }

  String get _emoji {
    if (days >= 30) return '🏆';
    if (days >= 7) return '🔥';
    return '⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color, _color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _color.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text('$days',
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTONS
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.primary,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: primary
              ? LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: primary ? null : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: primary
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: primary ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary ? Colors.white : color)),
        ]),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool isDark;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.radius,
    required this.isDark,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? const Color(0xFF2A2A48) : Colors.grey.shade200;
    final highlight =
    widget.isDark ? const Color(0xFF3A3A60) : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width == double.infinity ? double.infinity : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}