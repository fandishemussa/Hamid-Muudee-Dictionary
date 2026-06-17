import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../screens/word_detail_screen.dart';
import '../services/app_session.dart';
import '../services/tts_service.dart';
import '../services/share_service.dart';
import '../themes/app_sizing.dart';

class WordCard extends StatefulWidget {
  final Word word;
  final List<Word> allWords;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTapDetail;

  const WordCard({
    super.key,
    required this.word,
    this.allWords = const [],
    this.onFavoriteToggle,
    this.onTapDetail,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isSpeaking = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

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

  Color _posColor(String pos) {
    final p = pos.toLowerCase().trim();
    for (final k in _posColors.keys) {
      if (p.contains(k)) return _posColors[k]!;
    }
    return const Color(0xFF9E9E9E);
  }

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    // Read current status from the single source of truth
    final newVal = !AppSession.instance.isFavorite(widget.word.english);
    widget.word.isFavorite = newVal;
    AppSession.instance.toggleFavorite(widget.word.english, value: newVal);
    // favoritesNotifier fires → every ValueListenableBuilder rebuilds
    widget.onFavoriteToggle?.call();
  }

  void _openDetail() {
    if (widget.onTapDetail != null) {
      widget.onTapDetail!();
      return;
    }
    AppSession.instance.addRecentWord(widget.word.english);
    AppSession.instance.recordWordViewed();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          word: widget.word,
          allWords: widget.allWords,
        ),
      ),
    );
  }

  void _speakWord() async {
    final tts = TtsService.instance;
    if (tts.isSpeaking.value) {
      await tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSpeaking = true);
    await tts.speak(widget.word.english);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _shareWord() {
    ShareService.instance.shareWord(widget.word);
  }

  void _showContextMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordContextMenu(
        word: widget.word,
        posColor: _posColor(widget.word.partOfSpeech),
        onDetail: () { Navigator.pop(context); _openDetail(); },
        onSpeak: () { Navigator.pop(context); _speakWord(); },
        onShare: () { Navigator.pop(context); _shareWord(); },
        onCopy: () {
          Navigator.pop(context);
          Clipboard.setData(ClipboardData(
              text: '${widget.word.english}: ${widget.word.oromoTranslation}'));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Copied!', style: GoogleFonts.dmSans()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ));
        },
        onFavorite: () {
          Navigator.pop(context);
          _toggleFavorite();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posColor = _posColor(widget.word.partOfSpeech);
    final s = AppSizing.of(context);

    return GestureDetector(
      onLongPress: _showContextMenu,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: s.xs + 1, horizontal: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252540) : Colors.white,
          borderRadius: BorderRadius.circular(s.radiusLg),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : Colors.grey.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
            _isExpanded ? posColor.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(s.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(s.radiusLg),
            onTap: _toggleExpand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main row ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(s.md, s.md, s.sm, s.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Colour strip
                      Container(
                        width: 4,
                        height: s.avatarMd + 12,
                        decoration: BoxDecoration(
                            color: posColor,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      SizedBox(width: s.sm + 4),
                      // Text content — must be Expanded to prevent overflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // English word + pronunciation on same line
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  flex: 3,
                                  child: Text(
                                    _tc(widget.word.english),
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: s.fontXxl - 4,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A2E),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (widget.word.pronunciation.isNotEmpty) ...[
                                  SizedBox(width: s.xs + 2),
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      '/${widget.word.pronunciation}/',
                                      style: GoogleFonts.dmSans(
                                        fontSize: s.fontSm,
                                        color: const Color(0xFF00BFA5),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: s.xs + 1),
                            // POS badge + oromo translation
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _PosBadge(
                                    pos: widget.word.partOfSpeech,
                                    color: posColor,
                                    fontSize: s.fontXs + 1),
                                SizedBox(width: s.xs + 3),
                                Expanded(
                                  child: Text(
                                    _tc(widget.word.oromoTranslation),
                                    style: GoogleFonts.dmSans(
                                      fontSize: s.fontMd,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF6B7280),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action icons — fixed width column, never competes with text
                      SizedBox(width: s.xs),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bookmark — reacts instantly to AppSession changes
                          ValueListenableBuilder<Set<String>>(
                            valueListenable:
                            AppSession.instance.favoritesNotifier,
                            builder: (_, favs, __) {
                              final saved = favs.contains(
                                  widget.word.english.toLowerCase());
                              return _SmallIconBtn(
                                icon: saved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: saved
                                    ? const Color(0xFFD4A017)
                                    : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                                onTap: _toggleFavorite,
                              );
                            },
                          ),
                          // Expand chevron
                          RotationTransition(
                            turns: _rotateAnim,
                            child: Icon(Icons.keyboard_arrow_down,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                                size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Expanded panel ──────────────────────────────────
                SizeTransition(
                  sizeFactor: _expandAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      color: posColor.withOpacity(isDark ? 0.07 : 0.04),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: posColor.withOpacity(0.2), height: 16),
                        if (widget.word.englishDefinition.isNotEmpty) ...[
                          _DetailRow(
                            icon: Icons.menu_book_outlined,
                            label: 'Definition',
                            value: widget.word.englishDefinition,
                            color: posColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _DetailRow(
                          icon: Icons.translate,
                          label: 'Oromo',
                          value: _tc(widget.word.oromoTranslation),
                          color: posColor,
                          isDark: isDark,
                          bold: true,
                        ),
                        const SizedBox(height: 10),
                        // Action row — use Wrap to prevent overflow on narrow screens
                        Row(
                          children: [
                            Flexible(
                              child: _PillBtn(
                                icon: _isSpeaking
                                    ? Icons.volume_up
                                    : Icons.play_circle_outline,
                                label: _isSpeaking ? 'Playing…' : 'Listen',
                                color: const Color(0xFF00BFA5),
                                onTap: _speakWord,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _PillBtn(
                                icon: Icons.open_in_new,
                                label: 'Detail',
                                color: posColor,
                                onTap: _openDetail,
                              ),
                            ),
                            const Spacer(),
                            _SmallIconBtn(
                              icon: Icons.copy_outlined,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text:
                                    '${widget.word.english}: ${widget.word.oromoTranslation}'));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Copied!',
                                      style: GoogleFonts.dmSans()),
                                  duration: const Duration(seconds: 1),
                                ));
                              },
                            ),
                            _SmallIconBtn(
                              icon: Icons.share_outlined,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                              onTap: _shareWord,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Context menu sheet ────────────────────────────────────────────
class _WordContextMenu extends StatelessWidget {
  final Word word;
  final Color posColor;
  final VoidCallback onDetail;
  final VoidCallback onSpeak;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;

  const _WordContextMenu({
    required this.word,
    required this.posColor,
    required this.onDetail,
    required this.onSpeak,
    required this.onShare,
    required this.onCopy,
    required this.onFavorite,
  });

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          // Word header
          Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                    color: posColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tc(word.english),
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                    Text(_tc(word.oromoTranslation),
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ContextAction(
                  icon: Icons.open_in_new,
                  label: 'Full Detail',
                  color: posColor,
                  onTap: onDetail),
              _ContextAction(
                  icon: Icons.volume_up_outlined,
                  label: 'Listen',
                  color: const Color(0xFF00BFA5),
                  onTap: onSpeak),
              _ContextAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: const Color(0xFF4A90D9),
                  onTap: onShare),
              _ContextAction(
                  icon: Icons.copy_outlined,
                  label: 'Copy',
                  color: const Color(0xFF9C27B0),
                  onTap: onCopy),
              ValueListenableBuilder<Set<String>>(
                valueListenable: AppSession.instance.favoritesNotifier,
                builder: (_, favs, __) {
                  final saved = favs.contains(word.english.toLowerCase());
                  return _ContextAction(
                    icon: saved ? Icons.bookmark : Icons.bookmark_border,
                    label: saved ? 'Remove from Saved' : 'Save Word',
                    color: const Color(0xFFD4A017),
                    onTap: onFavorite,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContextAction(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────
class _PosBadge extends StatelessWidget {
  final String pos;
  final Color color;
  final double fontSize;
  const _PosBadge({required this.pos, required this.color, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.xs + 3, vertical: s.xs - 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(s.radiusSm - 2),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(pos.toLowerCase(),
          style: GoogleFonts.dmSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool bold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Text('$label: ',
            style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                height: 1.4,
              )),
        ),
      ],
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillBtn(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        // Row is inside a Flexible — must NOT use MainAxisSize.min
        // because the parent Flexible already gives it a bounded width.
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallIconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}