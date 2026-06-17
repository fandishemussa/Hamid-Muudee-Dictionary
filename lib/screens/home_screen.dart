import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/word.dart';
import '../screens/about_screen.dart';
import '../screens/dictionary_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/word_detail_screen.dart';
import '../services/app_session.dart';
import '../themes/app_sizing.dart';
import '../widgets/word_of_day_notification_card.dart';

// ── Tab palette ──────────────────────────────────────────────────────────────
const _kTabColors = <Color>[
  Color(0xFFD4A017), // Dictionary – gold
  Color(0xFF7B68EE), // Saved      – purple
  Color(0xFF00BFA5), // Learn      – teal
  Color(0xFF4A90D9), // Stats      – blue
  Color(0xFF6B7280), // About      – slate
];
const _kTabGradientsLight = <List<Color>>[
  [Color(0xFFD4A017), Color(0xFFB8860B)],
  [Color(0xFF7B68EE), Color(0xFF5A4FCF)],
  [Color(0xFF00BFA5), Color(0xFF00897B)],
  [Color(0xFF4A90D9), Color(0xFF2E6DB4)],
  [Color(0xFF6B7280), Color(0xFF4B5563)],
];
const _kTabGradientsDark = <List<Color>>[
  [Color(0xFF3D2E0A), Color(0xFF1A1A2E)],
  [Color(0xFF1E1B3A), Color(0xFF1A1A2E)],
  [Color(0xFF0D2926), Color(0xFF1A1A2E)],
  [Color(0xFF0F1E30), Color(0xFF1A1A2E)],
  [Color(0xFF1C1F26), Color(0xFF1A1A2E)],
];

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────
  int _currentIndex = 0;
  List<Word> _words = [];
  bool _isLoading = true;
  bool _overlayShown = false;
  bool _wotdSeenToday = false;

  // ── Keys ───────────────────────────────────────────────────────────
  final _dictKey = GlobalKey<DictionaryScreenState>();

  // ── Animations ─────────────────────────────────────────────────────
  late AnimationController _tabAnim;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _tabAnim.forward();
    _loadDictionary();
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────
  Future<void> _loadDictionary() async {
    try {
      final bd = await rootBundle.load('assets/data/dictionary.bin');
      final enc = bd.buffer.asUint8List();
      final iv = encrypt.IV(enc.sublist(0, 16));
      final cipher = enc.sublist(16);
      const pwd = String.fromEnvironment('DICT_PASSWORD');
      final key = encrypt.Key(
        Uint8List.fromList(sha256.convert(utf8.encode(pwd)).bytes),
      );
      final dec = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      ).decrypt(encrypt.Encrypted(cipher), iv: iv);
      final words =
          (json.decode(dec) as List)
              .map((e) => Word.fromJson(e as Map<String, dynamic>))
              .toList();
      AppSession.instance.applyFavoritesToWords(words);
      setState(() {
        _words = words;
        _isLoading = false;
      });
      if (!_overlayShown && mounted) {
        _overlayShown = true;
        Future.delayed(const Duration(milliseconds: 900), _showWotDOverlay);
      }
    } catch (e, st) {
      debugPrint('Dictionary load error: $e\n$st');
      setState(() => _isLoading = false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────
  void _showWotDOverlay() {
    if (_words.isEmpty || !mounted) return;
    setState(() => _wotdSeenToday = true);
    final wotd = _words[DateTime.now().day % _words.length];
    WordOfDayNotificationCard.showOverlay(
      context,
      word: wotd,
      streakDays: AppSession.instance.streakDays,
      onLearnMore:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordDetailScreen(word: wotd, allWords: _words),
            ),
          ),
    );
  }

  void _openRandomWord() {
    if (_words.isEmpty) return;
    HapticFeedback.mediumImpact();
    final word = _words[Random().nextInt(_words.length)];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(word: word, allWords: _words),
      ),
    );
  }

  void _switchTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    _tabAnim.forward(from: 0);
    setState(() => _currentIndex = index);
  }

  void _onFavoriteChanged() => setState(() {});

  // ── Subtitle ───────────────────────────────────────────────────────
  String _subtitle(int i) {
    if (_isLoading) return 'Loading…';
    switch (i) {
      case 0:
        return '${_formatNum(_words.length)} words';
      case 1:
        final c = AppSession.instance.favoritesNotifier.value.length;
        return c > 0 ? '$c saved words' : 'No saved words yet';
      case 2:
        final s = AppSession.instance.streakDays;
        return s > 0 ? '🔥 $s day streak' : 'Start learning today';
      case 3:
        final a = AppSession.instance.accuracyPercent;
        return a > 0 ? '${a.round()}% accuracy' : 'No quizzes yet';
      case 4:
        return 'Afaan Oromoo Dictionary v2.0';
      default:
        return '';
    }
  }

  String _formatNum(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppSizing.of(context);

    final screens = [
      DictionaryScreen(key: _dictKey),
      FavoritesScreen(allWords: _words),
      LearnScreen(words: _words, onFavoriteChanged: _onFavoriteChanged),
      StatsScreen(allWords: _words),
      const AboutScreen(),
    ];

    // Navigation destinations — used by both bottom nav and nav rail
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Dictionary',
      ),
      NavigationDestination(
        icon: Icon(Icons.bookmark_border),
        selectedIcon: Icon(Icons.bookmark),
        label: 'Saved',
      ),
      NavigationDestination(
        icon: Icon(Icons.bolt_outlined),
        selectedIcon: Icon(Icons.bolt),
        label: 'Learn',
      ),
      NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: 'Stats',
      ),
      NavigationDestination(
        icon: Icon(Icons.info_outline),
        selectedIcon: Icon(Icons.info),
        label: 'About',
      ),
    ];

    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFBF0);

    // ── Wide layout (tablet / desktop / web) ──────────────────────
    if (s.isWideBp) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            // Navigation rail — width and label style from AppSizing
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _switchTab,
              labelType: s.navLabelType,
              minWidth: s.navRailWidth,
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onLongPress: () => _showQuickStats(context, isDark, _words),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kTabColors[_currentIndex].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: _kTabColors[_currentIndex],
                      size: 22,
                    ),
                  ),
                ),
              ),
              destinations:
                  destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Main content — full height, capped width
            Expanded(
              child: Column(
                children: [
                  _AdvancedAppBar(
                    currentIndex: _currentIndex,
                    isDark: isDark,
                    words: _words,
                    isLoading: _isLoading,
                    subtitle: _subtitle(_currentIndex),
                    wotdUnseen: !_wotdSeenToday && !_isLoading,
                    tabAnim: _tabAnim,
                    onWotD: _showWotDOverlay,
                    onRandom: _openRandomWord,
                    onSettings:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                    onShowQuickStats:
                        () => _showQuickStats(context, isDark, _words),
                    onGoToSaved: () => _switchTab(1),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizing.maxColumnWidth,
                        ),
                        child:
                            _isLoading
                                ? _buildSplash(isDark, s)
                                : IndexedStack(
                                  index: _currentIndex,
                                  children: screens,
                                ),
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

    // ── Phone layout ──────────────────────────────────────────────
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _AdvancedAppBar(
            currentIndex: _currentIndex,
            isDark: isDark,
            words: _words,
            isLoading: _isLoading,
            subtitle: _subtitle(_currentIndex),
            wotdUnseen: !_wotdSeenToday && !_isLoading,
            tabAnim: _tabAnim,
            onWotD: _showWotDOverlay,
            onRandom: _openRandomWord,
            onSettings:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
            onShowQuickStats: () => _showQuickStats(context, isDark, _words),
            onGoToSaved: () => _switchTab(1),
          ),
          Expanded(
            child:
                _isLoading
                    ? _buildSplash(isDark, s)
                    : IndexedStack(index: _currentIndex, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: _switchTab,
      ),
    );
  }

  // ── Quick stats popup (long-press app icon) ────────────────────────
  void _showQuickStats(BuildContext context, bool isDark, List<Word> words) {
    HapticFeedback.mediumImpact();
    final session = AppSession.instance;
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder:
          (_) => _QuickStatsDialog(
            isDark: isDark,
            totalWords: words.length,
            savedCount: session.favoritesNotifier.value.length,
            streakDays: session.streakDays,
            wordsToday: session.wordsViewedToday,
            accuracy: session.accuracyPercent,
            dailyGoal: session.dailyWordGoal,
            dailyProgress: session.dailyGoalProgress,
          ),
    );
  }

  // ── Splash ────────────────────────────────────────────────────────
  Widget _buildSplash(bool isDark, AppSizing s) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Hamid Muudee's Dictionary",
            style: GoogleFonts.playfairDisplay(
              fontSize: s.fontXxl,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'English ↔ Afaan Oromoo',
            style: GoogleFonts.dmSans(
              fontSize: s.fontSm,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: primary, strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Decrypting dictionary…',
            style: GoogleFonts.dmSans(
              fontSize: s.fontSm,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADVANCED APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _AdvancedAppBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark, isLoading, wotdUnseen;
  final List<Word> words;
  final String subtitle;
  final Animation<double> tabAnim;
  final VoidCallback onWotD,
      onRandom,
      onSettings,
      onShowQuickStats,
      onGoToSaved;

  static const _titles = [
    'Dictionary',
    'Saved Words',
    'Learn',
    'Progress',
    'About',
  ];

  const _AdvancedAppBar({
    required this.currentIndex,
    required this.isDark,
    required this.words,
    required this.isLoading,
    required this.subtitle,
    required this.wotdUnseen,
    required this.tabAnim,
    required this.onWotD,
    required this.onRandom,
    required this.onSettings,
    required this.onShowQuickStats,
    required this.onGoToSaved,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    final gradient =
        isDark
            ? _kTabGradientsDark[currentIndex]
            : _kTabGradientsLight[currentIndex];
    final tabColor = _kTabColors[currentIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(isDark ? 0.2 : 0.35),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main toolbar row ──────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(s.screenPaddingH, 10, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── App icon (long-press → quick stats) ──────────
                  GestureDetector(
                    onLongPress: onShowQuickStats,
                    child: _GlassBox(
                      size: 40,
                      radius: 13,
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Title + subtitle ──────────────────────────────
                  Flexible(
                    child: FadeTransition(
                      key: ValueKey(currentIndex),
                      opacity: tabAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _titles[currentIndex],
                            style: GoogleFonts.playfairDisplay(
                              fontSize: s.fontXxl - 2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _SubtitleRow(
                            subtitle: subtitle,
                            isLoading: isLoading,
                            fontSize: s.fontXs + 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Action buttons ────────────────────────────────
                  if (!isLoading) ...[
                    // 1. Daily goal progress ring — tap opens quick stats
                    _GoalRingBtn(tabColor: tabColor, onTap: onShowQuickStats),

                    // 2. Saved words bookmark badge — tapping goes to Saved tab
                    _BookmarkBadgeBtn(onTap: onGoToSaved),

                    // 3. Random word (Dictionary tab only)
                    if (currentIndex == 0)
                      _PressBtn(
                        icon: Icons.casino_outlined,
                        tooltip: 'Random word',
                        onTap: onRandom,
                      ),

                    // 4. WotD bell with unseen dot
                    _BadgedBtn(
                      icon: Icons.wb_sunny_outlined,
                      tooltip: 'Word of the Day',
                      showBadge: wotdUnseen,
                      onTap: onWotD,
                    ),
                  ],

                  // 5. Settings (always visible)
                  _PressBtn(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onTap: onSettings,
                  ),
                ],
              ),
            ),

            // ── Tab colour indicator strip ────────────────────────
            _TabIndicatorStrip(currentIndex: currentIndex, tabColor: tabColor),

            // ── Hero banner (Dictionary tab only) ─────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              child:
                  currentIndex == 0 && !isLoading && words.isNotEmpty
                      ? _HeroBanner(words: words, isDark: isDark)
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBTITLE ROW — shimmer while loading, static when ready
// ─────────────────────────────────────────────────────────────────────────────
class _SubtitleRow extends StatefulWidget {
  final String subtitle;
  final bool isLoading;
  final double fontSize;
  const _SubtitleRow({
    required this.subtitle,
    required this.isLoading,
    required this.fontSize,
  });

  @override
  State<_SubtitleRow> createState() => _SubtitleRowState();
}

class _SubtitleRowState extends State<_SubtitleRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shimAnim;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimAnim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return AnimatedBuilder(
        animation: _shimAnim,
        builder:
            (_, __) => Container(
              height: 10,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: Alignment(_shimAnim.value - 1, 0),
                  end: Alignment(_shimAnim.value, 0),
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF43E97B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            widget.subtitle,
            style: GoogleFonts.dmSans(
              fontSize: widget.fontSize,
              color: Colors.white.withOpacity(0.78),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB INDICATOR STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _TabIndicatorStrip extends StatelessWidget {
  final int currentIndex;
  final Color tabColor;

  const _TabIndicatorStrip({
    required this.currentIndex,
    required this.tabColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: List.generate(5, (i) {
          final sel = i == currentIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: sel ? 3 : 2,
              decoration: BoxDecoration(
                color: sel ? Colors.white : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER — random word, refreshes each session, flip animation
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatefulWidget {
  final List<Word> words;
  final bool isDark;

  const _HeroBanner({required this.words, required this.isDark});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner>
    with SingleTickerProviderStateMixin {
  late Word _featured;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipping = false;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    // Pick a NEW random word every time the banner is created (app open)
    _featured = widget.words[_rng.nextInt(widget.words.length)];

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  // Flip to a new random word
  Future<void> _refresh() async {
    if (_isFlipping) return;
    HapticFeedback.lightImpact();
    setState(() => _isFlipping = true);

    await _flipCtrl.forward();

    // Pick word (different from current)
    Word next;
    do {
      next = widget.words[_rng.nextInt(widget.words.length)];
    } while (next.english == _featured.english && widget.words.length > 1);

    setState(() => _featured = next);
    await _flipCtrl.reverse();
    setState(() => _isFlipping = false);
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => WordDetailScreen(word: _featured, allWords: widget.words),
      ),
    );
  }

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map(
          (w) =>
              w.isNotEmpty
                  ? w[0].toUpperCase() + w.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }

  String _dayLabel() {
    final n = DateTime.now();
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${d[n.weekday - 1]}, ${m[n.month - 1]} ${n.day}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (context, child) {
        // Flip on Y axis — first half hides, second half reveals new word
        final angle = _flipAnim.value * pi;
        final isBack = angle > pi / 2;
        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(isBack ? angle - pi : angle),
          alignment: Alignment.center,
          child: Opacity(opacity: isBack ? 0.0 : 1.0, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(
            s.screenPaddingH,
            10,
            s.screenPaddingH,
            14,
          ),
          padding: EdgeInsets.all(s.md),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.2),
            borderRadius: BorderRadius.circular(s.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────
              Row(
                children: [
                  // "Featured Word" badge
                  _WBadge(emoji: '✨', label: 'Featured Word'),
                  const Spacer(),
                  // Date
                  Text(
                    _dayLabel(),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh button
                  GestureDetector(
                    onTap: _refresh,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: AnimatedRotation(
                        turns: _isFlipping ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: const Icon(
                          Icons.shuffle_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: s.sm),

              // ── Word row ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // English word
                        Text(
                          _tc(_featured.english),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: s.fontDisplay,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.05,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),

                        // Pronunciation + POS
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (_featured.pronunciation.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  '/${_featured.pronunciation}/',
                                  style: GoogleFonts.dmSans(
                                    fontSize: s.fontXs + 1,
                                    color: Colors.white.withOpacity(0.72),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_featured.partOfSpeech.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _featured.partOfSpeech.toLowerCase(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Definition preview
                        if (_featured.englishDefinition.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _featured.englishDefinition,
                            style: GoogleFonts.dmSans(
                              fontSize: s.fontXs + 1,
                              color: Colors.white.withOpacity(0.65),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Oromo translation pill
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: s.sm + 2,
                            vertical: s.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(s.radiusSm),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.translate,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _tc(_featured.oromoTranslation),
                                  style: GoogleFonts.dmSans(
                                    fontSize: s.fontSm + 1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right: stat pills + tap hint ──────────────
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatPill(
                        icon: Icons.menu_book_outlined,
                        value: _formatNum(widget.words.length),
                        label: 'words',
                      ),
                      const SizedBox(height: 5),
                      ValueListenableBuilder<Set<String>>(
                        valueListenable: AppSession.instance.favoritesNotifier,
                        builder:
                            (_, favs, __) => _StatPill(
                              icon: Icons.bookmark_outline,
                              value: '${favs.length}',
                              label: 'saved',
                            ),
                      ),
                      const SizedBox(height: 5),
                      _StatPill(
                        icon: Icons.local_fire_department_outlined,
                        value: '${AppSession.instance.streakDays}',
                        label: 'streak',
                      ),
                      const SizedBox(height: 10),
                      // Tap hint
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 10,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'tap to explore',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNum(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// ── Banner badge ──────────────────────────────────────────────────────────────
class _WBadge extends StatelessWidget {
  final String emoji, label;
  const _WBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS BOX (app icon container)
// ─────────────────────────────────────────────────────────────────────────────
class _GlassBox extends StatelessWidget {
  final double size, radius;
  final Widget child;
  const _GlassBox({
    required this.size,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESS BUTTON — AppBar action with visual press feedback
// ─────────────────────────────────────────────────────────────────────────────
class _PressBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  const _PressBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color:
                  widget.active
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color:
                    widget.active
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.18),
              ),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGED BUTTON — WotD button with notification dot
// ─────────────────────────────────────────────────────────────────────────────
class _BadgedBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool showBadge;
  final VoidCallback onTap;

  const _BadgedBtn({
    required this.icon,
    required this.tooltip,
    required this.showBadge,
    required this.onTap,
  });

  @override
  State<_BadgedBtn> createState() => _BadgedBtnState();
}

class _BadgedBtnState extends State<_BadgedBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
              if (widget.showBadge)
                Positioned(
                  top: 3,
                  right: 3,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder:
                        (_, v, child) =>
                            Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL RING BUTTON
// A circular progress ring showing today's daily word goal.
// Tap → opens quick stats dialog.
// ─────────────────────────────────────────────────────────────────────────────
class _GoalRingBtn extends StatelessWidget {
  final Color tabColor;
  final VoidCallback onTap;

  const _GoalRingBtn({required this.tabColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final progress = session.dailyGoalProgress;
    final wordsToday = session.wordsViewedToday;
    final goal = session.dailyWordGoal;
    final done = progress >= 1.0;
    final ringColor = done ? const Color(0xFF43E97B) : Colors.white;

    return Tooltip(
      message:
          done
              ? 'Daily goal complete! ($wordsToday/$goal words)'
              : 'Daily goal: $wordsToday / $goal words',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
              // Centre icon / checkmark
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    done
                        ? Icon(
                          Icons.check,
                          key: const ValueKey('done'),
                          size: 14,
                          color: const Color(0xFF43E97B),
                        )
                        : Text(
                          '$wordsToday',
                          key: const ValueKey('count'),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKMARK BADGE BUTTON
// Shows the live saved-words count as a badge. Tapping navigates to Saved tab.
// ─────────────────────────────────────────────────────────────────────────────
class _BookmarkBadgeBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BookmarkBadgeBtn({required this.onTap});

  @override
  State<_BookmarkBadgeBtn> createState() => _BookmarkBadgeBtnState();
}

class _BookmarkBadgeBtnState extends State<_BookmarkBadgeBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppSession.instance.favoritesNotifier,
      builder: (_, favs, __) {
        final count = favs.length;
        return Tooltip(
          message:
              count == 0
                  ? 'No saved words'
                  : '$count saved word${count == 1 ? '' : 's'}',
          child: GestureDetector(
            onTapDown: (_) => _ctrl.reverse(),
            onTapUp: (_) {
              _ctrl.forward();
              widget.onTap();
            },
            onTapCancel: () => _ctrl.forward(),
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bookmark icon
                    Center(
                      child: Icon(
                        count > 0 ? Icons.bookmark : Icons.bookmark_border,
                        color:
                            count > 0 ? const Color(0xFFFFD700) : Colors.white,
                        size: 18,
                      ),
                    ),
                    // Count badge (only shown when > 0)
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(count),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.elasticOut,
                          builder:
                              (_, v, child) =>
                                  Transform.scale(scale: v, child: child),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS DIALOG (long-press app icon)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStatsDialog extends StatelessWidget {
  final bool isDark;
  final int totalWords, savedCount, streakDays, wordsToday, dailyGoal;
  final double accuracy, dailyProgress;

  const _QuickStatsDialog({
    required this.isDark,
    required this.totalWords,
    required this.savedCount,
    required this.streakDays,
    required this.wordsToday,
    required this.accuracy,
    required this.dailyGoal,
    required this.dailyProgress,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: AppSizing.maxContentWidth - 48),
        padding: EdgeInsets.all(s.lg),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(s.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Stats",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: s.fontXl,
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                      ),
                      Text(
                        "Hamid Muudee's Dictionary",
                        style: GoogleFonts.dmSans(
                          fontSize: s.fontXs,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                _QStat(
                  label: 'Total Words',
                  value: _fmt(totalWords),
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFFD4A017),
                  isDark: isDark,
                ),
                _QStat(
                  label: 'Saved',
                  value: '$savedCount',
                  icon: Icons.bookmark_outline,
                  color: const Color(0xFF7B68EE),
                  isDark: isDark,
                ),
                _QStat(
                  label: 'Streak',
                  value: '$streakDays days',
                  icon: Icons.local_fire_department_outlined,
                  color: const Color(0xFFFF6B35),
                  isDark: isDark,
                ),
                _QStat(
                  label: 'Accuracy',
                  value: '${accuracy.round()}%',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF00BFA5),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Daily goal progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: const Color(0xFF4A90D9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Daily Goal',
                      style: GoogleFonts.dmSans(
                        fontSize: s.fontSm,
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$wordsToday / $dailyGoal words',
                      style: GoogleFonts.dmSans(
                        fontSize: s.fontXs + 1,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A90D9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: dailyProgress,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? const Color(0xFF252540) : Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4A90D9)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _QStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _QStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs + 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(s.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: s.fontMd,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: s.fontXs,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  static const _items = [
    _NI(Icons.menu_book_outlined, Icons.menu_book, 'Dictionary'),
    _NI(Icons.bookmark_border, Icons.bookmark, 'Saved'),
    _NI(Icons.bolt_outlined, Icons.bolt, 'Learn'),
    _NI(Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
    _NI(Icons.info_outline, Icons.info, 'About'),
  ];

  const _BottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    final primary = _kTabColors[currentIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: s.xs + 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (i) => _NavItem(
                item: _items[i],
                selected: currentIndex == i,
                primary: primary,
                isDark: isDark,
                onTap: () => onTap(i),
                s: s,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NI item;
  final bool selected, isDark;
  final Color primary;
  final VoidCallback onTap;
  final AppSizing s;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = isDark ? Colors.white38 : Colors.grey.shade400;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: s.md - 2, vertical: s.xs + 2),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(s.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder:
                  (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                color: selected ? primary : inactive,
                size: s.iconMd + 2,
              ),
            ),
            SizedBox(height: s.xs - 1),
            Text(
              item.label,
              style: GoogleFonts.dmSans(
                fontSize: s.fontXs,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? primary : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NI {
  final IconData icon, activeIcon;
  final String label;
  const _NI(this.icon, this.activeIcon, this.label);
}
