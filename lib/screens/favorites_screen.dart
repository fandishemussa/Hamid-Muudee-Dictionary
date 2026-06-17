import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';
import 'word_detail_screen.dart';
import '../services/app_session.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Word> allWords;
  const FavoritesScreen({super.key, this.allWords = const []});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _sortAZ = true;

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppSession.instance.favoritesNotifier,
      builder: (context, favKeys, _) {
        // Re-derive the filtered list every time favorites change
        final allFavCount = widget.allWords
            .where((w) => favKeys.contains(w.english.toLowerCase()))
            .length;
        final favorites = _buildFavoritesList(favKeys);

        if (allFavCount == 0) return _buildEmptyState(isDark);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search saved words…',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: primary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close,
                        size: 18, color: Colors.grey.shade400),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Count + sort
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
              child: Row(children: [
                Text('${favorites.length}',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4A017))),
                const SizedBox(width: 4),
                Text(
                    favorites.length == 1 ? 'saved word' : 'saved words',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white38
                            : Colors.grey.shade500)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _sortAZ = !_sortAZ);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFD4A017).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.swap_vert,
                          size: 13, color: const Color(0xFFD4A017)),
                      const SizedBox(width: 4),
                      Text(_sortAZ ? 'A–Z' : 'Default',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD4A017))),
                    ]),
                  ),
                ),
              ]),
            ),
            // List
            Expanded(
              child: favorites.isEmpty
                  ? _buildNoResults(isDark)
                  : ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final word = favorites[index];
                  return WordCard(
                    word: word,
                    allWords: widget.allWords,
                    onFavoriteToggle: () => setState(() {}),
                    onTapDetail: () {
                      AppSession.instance
                          .addRecentWord(word.english);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WordDetailScreen(
                              word: word,
                              allWords: widget.allWords),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Word> _buildFavoritesList(Set<String> favKeys) {
    var list = widget.allWords
        .where((w) => favKeys.contains(w.english.toLowerCase()))
        .toList();

    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((w) =>
      w.english.toLowerCase().contains(q) ||
          w.oromoTranslation.toLowerCase().contains(q))
          .toList();
    }

    if (_sortAZ) {
      list.sort((a, b) =>
          a.english.toLowerCase().compareTo(b.english.toLowerCase()));
    }
    return list;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border, size: 48, color: Color(0xFFD4A017)),
            ),
            const SizedBox(height: 24),
            Text('No saved words yet',
                style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            Text(
              'Tap the 🔖 bookmark on any word\nto save it here for quick access.',
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.7,
                  color: isDark ? Colors.white38 : Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Visual hint chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFFD4A017)),
                const SizedBox(width: 8),
                Text('Long-press any word card for options',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500,
                        color: const Color(0xFFD4A017))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text('No matches in saved words',
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600,
                color: Colors.grey.shade400)),
        const SizedBox(height: 6),
        Text('Try a different search term',
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }
}