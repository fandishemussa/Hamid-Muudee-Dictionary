import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';

/// A self-contained "Word of the Day" banner card.
/// Drop it at the top of any screen or inside a notification-style overlay.
class WordOfDayCard extends StatefulWidget {
  final Word word;
  final VoidCallback? onLearnMore;
  final bool compact;

  const WordOfDayCard({
    super.key,
    required this.word,
    this.onLearnMore,
    this.compact = false,
  });

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  String _dayLabel() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (widget.compact) return _buildCompact(isDark, primary);
    return _buildFull(isDark, primary);
  }

  // ── Full card ────────────────────────────────────────────────────
  Widget _buildFull(bool isDark, Color primary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2D5A), const Color(0xFF1A1A3E)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFF0CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Shimmer overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, __) => ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment(_shimmerAnim.value - 1, 0),
                    end: Alignment(_shimmerAnim.value, 0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ).createShader(rect),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.wb_sunny_outlined, size: 13, color: primary),
                        const SizedBox(width: 5),
                        Text('Word of the Day',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
                      ]),
                    ),
                    const Spacer(),
                    Text(_dayLabel(),
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: isDark ? Colors.white30 : Colors.grey.shade500)),
                  ],
                ),

                const SizedBox(height: 16),

                // Word
                Text(_tc(widget.word.english),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),

                // Pronunciation
                if (widget.word.pronunciation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('/${widget.word.pronunciation}/',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: const Color(0xFF00BFA5),
                          fontStyle: FontStyle.italic)),
                ],

                // POS badge
                if (widget.word.partOfSpeech.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(widget.word.partOfSpeech.toLowerCase(),
                        style: GoogleFonts.dmSans(
                            fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                  ),
                ],

                // Definition
                if (widget.word.englishDefinition.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(widget.word.englishDefinition,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          height: 1.55,
                          color: isDark ? Colors.white60 : Colors.grey.shade700),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],

                const SizedBox(height: 14),

                // Translation reveal / display
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _revealed = true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _revealed
                          ? const Color(0xFF00BFA5).withOpacity(0.12)
                          : (isDark ? const Color(0xFF252540) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _revealed
                            ? const Color(0xFF00BFA5).withOpacity(0.35)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        _revealed ? Icons.translate : Icons.visibility_outlined,
                        size: 16,
                        color: _revealed ? const Color(0xFF00BFA5) : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _revealed
                            ? _tc(widget.word.oromoTranslation)
                            : 'Tap to reveal Afaan Oromoo',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: _revealed ? FontWeight.w700 : FontWeight.w400,
                          color: _revealed
                              ? const Color(0xFF00BFA5)
                              : (isDark ? Colors.white38 : Colors.grey.shade500),
                        ),
                      ),
                    ]),
                  ),
                ),

                // Learn more button
                if (widget.onLearnMore != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text('View Full Details',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      onPressed: widget.onLearnMore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact banner (e.g. for notification-style at top of screen) ─
  Widget _buildCompact(bool isDark, Color primary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.75)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Center(child: Text('☀️', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Word of the Day',
                style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.75), letterSpacing: 0.5)),
            Text(_tc(widget.word.english),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        if (widget.onLearnMore != null)
          TextButton(
            onPressed: widget.onLearnMore,
            style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            child: Text('Learn', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}