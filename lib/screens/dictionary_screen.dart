import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../models/word.dart';
import '../widgets/word_card.dart';
import '../services/app_session.dart';
import '../themes/app_sizing.dart';
import '../services/share_service.dart';
import 'word_detail_screen.dart';

enum SortMode { alphabetical, partOfSpeech, recentlyAdded }

// ── POS normalisation helpers ────────────────────────────────────────────────

/// Extracts the single primary POS tag from a raw value like
/// "Adj.Allprep.AllorAllconj." → "adj"
String _normalisePOS(String raw) {
  if (raw.trim().isEmpty) return '';
  // Lower, strip trailing dots/spaces
  var s = raw.toLowerCase().trim().replaceAll(RegExp(r'\.+$'), '');
  // Take only the first segment before any dot or 'or' or 'all'
  s = s.split(RegExp(r'\.|or|all'))[0].trim();
  // Normalise known abbreviations
  const map = {
    'adj': 'adj', 'adjective': 'adj',
    'adv': 'adv', 'adverb': 'adv',
    'n': 'noun',  'noun': 'noun',
    'v': 'verb',  'verb': 'verb',
    'prep': 'prep', 'preposition': 'prep',
    'conj': 'conj', 'conjunction': 'conj',
    'pron': 'pron', 'pronoun': 'pron',
    'interj': 'interj', 'interjection': 'interj',
    'fn': 'phr',  'phrase': 'phr',
    'm': 'misc',
  };
  return map[s] ?? s;
}

// POS display config: tag → (label, icon, color)
const _posConfig = <String, (String, IconData, Color)>{
  'all':    ('All',    Icons.apps,                    Color(0xFFD4A017)),
  'noun':   ('Noun',   Icons.label_outline,           Color(0xFF4A90D9)),
  'verb':   ('Verb',   Icons.electric_bolt,           Color(0xFF7B68EE)),
  'adj':    ('Adj',    Icons.palette_outlined,        Color(0xFF00BFA5)),
  'adv':    ('Adv',    Icons.speed,                   Color(0xFFFF8C00)),
  'prep':   ('Prep',   Icons.link,                    Color(0xFFE91E63)),
  'conj':   ('Conj',   Icons.merge,                   Color(0xFF9C27B0)),
  'pron':   ('Pron',   Icons.person_outline,          Color(0xFF4CAF50)),
  'interj': ('Interj', Icons.sentiment_very_satisfied_outlined, Color(0xFFFF5722)),
  'phr':    ('Phrase', Icons.format_quote_outlined,   Color(0xFF00ACC1)),
  'misc':   ('Misc',   Icons.more_horiz,              Color(0xFF8D6E63)),
};

(String, IconData, Color) _posInfo(String tag) =>
    _posConfig[tag] ?? (tag.toUpperCase(), Icons.label_outline, const Color(0xFF9E9E9E));

// ── Screen ───────────────────────────────────────────────────────────────────

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => DictionaryScreenState();
}

// Public state so HomeScreen can hold a GlobalKey<DictionaryScreenState>
// and call focusSearch() from the AppBar search button.
class DictionaryScreenState extends State<DictionaryScreen>
    with AutomaticKeepAliveClientMixin {
  // Controllers
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final ScrollController _filterScrollCtrl = ScrollController();

  // Data
  List<Word> _words = [];
  List<Word> _filtered = [];
  bool _isLoading = true;
  String _selectedPOS = 'all';
  List<String> _posFilters = ['all'];
  SortMode _sortMode = SortMode.recentlyAdded;
  bool _showScrollTop = false;
  bool _showHistorySuggestions = false;
  Map<String, int> _letterIndex = {};
  final session = AppSession.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 400;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });
    _searchFocus.addListener(() {
      setState(() => _showHistorySuggestions =
          _searchFocus.hasFocus && _searchCtrl.text.isEmpty);
    });
  }

  /// Called externally (from AppBar search button) to focus the search field
  void focusSearch() {
    _searchFocus.requestFocus();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  /// Called from the AppBar inline search bar to filter the word list
  void filterFromExternal(String query) {
    _searchCtrl.text = query;
    setState(() {
      _showHistorySuggestions = false;
      _applyFilters(query, _selectedPOS);
    });
    if (query.isNotEmpty) session.addSearch(query);
  }

  /// Clears any external search and resets the list
  void clearExternalFilter() {
    _searchCtrl.clear();
    setState(() {
      _showHistorySuggestions = false;
      _applyFilters('', _selectedPOS);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    _filterScrollCtrl.dispose();
    super.dispose();
  }

  // ── Load ────────────────────────────────────────────────────────
  Future<void> _loadDictionary() async {
    try {
      final bd = await rootBundle.load('assets/data/dictionary.bin');
      final enc = bd.buffer.asUint8List();
      final iv = encrypt.IV(enc.sublist(0, 16));
      final cipher = enc.sublist(16);
      const pwd = String.fromEnvironment('DICT_PASSWORD');
      final key = encrypt.Key(
          Uint8List.fromList(sha256.convert(utf8.encode(pwd)).bytes));
      final dec = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc))
          .decrypt(encrypt.Encrypted(cipher), iv: iv);
      final words =
      (json.decode(dec) as List).map((e) => Word.fromJson(e)).toList();

      // Build normalised POS filter list (ordered by _posConfig)
      final seen = <String>{};
      for (final w in words) {
        final tag = _normalisePOS(w.partOfSpeech);
        if (tag.isNotEmpty) seen.add(tag);
      }
      // Keep config-defined order, then append any unknown tags
      final ordered = _posConfig.keys
          .where((k) => k != 'all' && seen.contains(k))
          .toList();
      for (final tag in seen) {
        if (!ordered.contains(tag)) ordered.add(tag);
      }

      setState(() {
        _words = words;
        _posFilters = ['all', ...ordered];
        _isLoading = false;
        _applyFilters('', 'all');
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Filter + sort ────────────────────────────────────────────────
  void _applyFilters(String query, String pos) {
    List<Word> result = List<Word>.from(_words);

    if (pos != 'all') {
      result = result
          .where((w) => _normalisePOS(w.partOfSpeech) == pos)
          .toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where((w) =>
      w.english.toLowerCase().contains(q) ||
          w.oromoTranslation.toLowerCase().contains(q))
          .toList();
    }
    switch (_sortMode) {
      case SortMode.alphabetical:
        result.sort((a, b) =>
            a.english.toLowerCase().compareTo(b.english.toLowerCase()));
        break;
      case SortMode.partOfSpeech:
        result.sort((a, b) => a.partOfSpeech.compareTo(b.partOfSpeech));
        break;
      case SortMode.recentlyAdded:
        break;
    }
    _filtered = result;
    _buildLetterIndex();
  }

  void _buildLetterIndex() {
    _letterIndex = {};
    for (int i = 0; i < _filtered.length; i++) {
      final l = _filtered[i].english.isNotEmpty
          ? _filtered[i].english[0].toUpperCase()
          : '#';
      _letterIndex.putIfAbsent(l, () => i);
    }
  }

  void _onSearch(String q) {
    if (q.isNotEmpty) session.addSearch(q);
    setState(() {
      _showHistorySuggestions = false;
      _applyFilters(q, _selectedPOS);
    });
  }

  void _scrollToLetter(String letter) {
    final idx = _letterIndex[letter];
    if (idx == null) return;
    _scrollCtrl.animateTo(
      idx * 84.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _openDetail(Word word) {
    session.addRecentWord(word.english);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => WordDetailScreen(word: word, allWords: _words)),
    ).then((_) => setState(() {}));
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (_isLoading) return _buildLoading(primary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      floatingActionButton: _showScrollTop
          ? FloatingActionButton.small(
        backgroundColor: primary,
        onPressed: () => _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut),
        child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
      )
          : null,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(isDark, primary),
          if (_showHistorySuggestions && session.searchHistory.isNotEmpty)
            _buildHistoryPanel(isDark, primary),
          if (!_showHistorySuggestions) ...[
            _buildPOSFilterRow(isDark),
            _buildInfoRow(isDark, primary),
          ],
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty(isDark)
                : Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                    const EdgeInsets.fromLTRB(16, 4, 4, 100),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final word = _filtered[i];
                      final letter = word.english.isNotEmpty
                          ? word.english[0].toUpperCase()
                          : '#';
                      final showSep =
                          _letterIndex[letter] == i &&
                              _sortMode == SortMode.alphabetical &&
                              _searchCtrl.text.isEmpty;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showSep)
                            _buildLetterSeparator(letter, isDark),
                          GestureDetector(
                            onLongPress: () =>
                                _showWordContextMenu(context, word),
                            child: WordCard(
                              word: word,
                              onFavoriteToggle: () => setState(() {}),
                              onTapDetail: () => _openDetail(word),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_sortMode == SortMode.alphabetical &&
                    _searchCtrl.text.isEmpty)
                  _buildAZSidebar(isDark, primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark, Color primary) {
    final s = AppSizing.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(s.screenPaddingH, s.sm + 2, s.screenPaddingH, s.xs + 2),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: (q) => setState(() {
          _showHistorySuggestions = q.isEmpty && _searchFocus.hasFocus;
          _applyFilters(q, _selectedPOS);
        }),
        onSubmitted: (q) {
          if (q.isNotEmpty) session.addSearch(q);
          setState(() => _showHistorySuggestions = false);
        },
        style: GoogleFonts.dmSans(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search English or Afaan Oromoo…',
          hintStyle:
          GoogleFonts.dmSans(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: primary, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearch('');
                    _searchFocus.unfocus();
                  },
                ),
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 20, color: primary),
                tooltip: 'Sort',
                onPressed: _showSortSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── POS filter pills ─────────────────────────────────────────────
  Widget _buildPOSFilterRow(bool isDark) {
    if (_posFilters.length <= 1) return const SizedBox.shrink();
    final s = AppSizing.of(context);

    return SizedBox(
      height: AppSizing.isSmall(context) ? 44 : 48,
      child: ListView.builder(
        controller: _filterScrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: _posFilters.length,
        itemBuilder: (context, i) {
          final tag = _posFilters[i];
          final info = _posInfo(tag);
          final label = info.$1;
          final icon  = info.$2;
          final color = info.$3;
          final sel   = _selectedPOS == tag;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPOS = tag;
                _applyFilters(_searchCtrl.text, tag);
              });
              // Scroll the selected chip into view
              _filterScrollCtrl.animateTo(
                i * 84.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? color
                    : (isDark
                    ? const Color(0xFF252540)
                    : Colors.white),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: sel
                      ? color
                      : (isDark
                      ? const Color(0xFF3A3A5C)
                      : Colors.grey.shade200),
                  width: sel ? 0 : 1,
                ),
                boxShadow: sel
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: sel
                        ? Colors.white
                        : (isDark ? Colors.white54 : color.withOpacity(0.8)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel
                          ? Colors.white
                          : (isDark
                          ? Colors.white60
                          : const Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Info row ─────────────────────────────────────────────────────
  Widget _buildInfoRow(bool isDark, Color primary) {
    final info = _posInfo(_selectedPOS);
    final activeColor = _selectedPOS == 'all' ? primary : info.$3;
    final s = AppSizing.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(s.screenPaddingH + 4, 4, s.screenPaddingH, 4),
      child: Row(
        children: [
          // Count + badge — in Expanded so sort button never gets pushed off
          Expanded(
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${_filtered.length}',
                    key: ValueKey(_filtered.length),
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: activeColor),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _filtered.length == 1 ? 'word' : 'words',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade500),
                ),
                if (_selectedPOS != 'all') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(info.$1,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, fontWeight: FontWeight.w600, color: activeColor)),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252540)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF3A3A5C)
                        : Colors.grey.shade200),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swap_vert_rounded, size: 13, color: primary),
                const SizedBox(width: 4),
                Text(_sortLabel,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_sortMode) {
      case SortMode.alphabetical:  return 'A–Z';
      case SortMode.partOfSpeech:  return 'By POS';
      case SortMode.recentlyAdded: return 'Default';
    }
  }

  // ── History suggestions ──────────────────────────────────────────
  Widget _buildHistoryPanel(bool isDark, Color primary) {
    final hist = session.searchHistory.take(6).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
            child: Row(children: [
              Icon(Icons.history_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.grey.shade400),
              const SizedBox(width: 6),
              Text('Recent searches',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade500)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  session.clearSearchHistory();
                  _showHistorySuggestions = false;
                }),
                child: Text('Clear',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primary)),
              ),
            ]),
          ),
          ...hist.map((q) => InkWell(
            onTap: () {
              _searchCtrl.text = q;
              _onSearch(q);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              child: Row(children: [
                Icon(Icons.search_rounded,
                    size: 15,
                    color:
                    isDark ? Colors.white30 : Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(q,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF374151)))),
                GestureDetector(
                  onTap: () =>
                      setState(() => session.removeSearch(q)),
                  child: Icon(Icons.close_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.white30
                          : Colors.grey.shade400),
                ),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  // ── A–Z sidebar ──────────────────────────────────────────────────
  Widget _buildAZSidebar(bool isDark, Color primary) {
    final letters = _letterIndex.keys.toList()..sort();
    return Container(
      width: 22,
      margin: const EdgeInsets.only(right: 4),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: letters.length,
        itemBuilder: (context, i) {
          final l = letters[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _scrollToLetter(l);
            },
            child: Container(
              height: 18,
              alignment: Alignment.center,
              child: Text(l,
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primary.withOpacity(0.7))),
            ),
          );
        },
      ),
    );
  }

  // ── Letter separator ─────────────────────────────────────────────
  Widget _buildLetterSeparator(String letter, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(letter,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primary)),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Divider(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
                height: 1)),
      ]),
    );
  }

  // ── Context menu ─────────────────────────────────────────────────
  void _showWordContextMenu(BuildContext context, Word word) {
    final primary = Theme.of(context).colorScheme.primary;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Text(_tc(word.english),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color:
                    isDark ? Colors.white : const Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text(_tc(word.oromoTranslation),
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white54
                        : Colors.grey.shade600)),
            const SizedBox(height: 20),
            _ContextAction(
                icon: Icons.open_in_new_rounded,
                label: 'View Full Details',
                color: primary,
                onTap: () {
                  Navigator.pop(context);
                  _openDetail(word);
                }),
            _ContextAction(
                icon: Icons.copy_outlined,
                label: 'Copy Word',
                color: const Color(0xFF4A90D9),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(
                      text: '${word.english}: ${word.oromoTranslation}'));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Copied!', style: GoogleFonts.dmSans()),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 1),
                  ));
                }),
            _ContextAction(
                icon: Icons.share_outlined,
                label: 'Share Word',
                color: const Color(0xFF00BFA5),
                onTap: () {
                  Navigator.pop(context);
                  ShareService.instance.shareWord(word);
                }),
            ValueListenableBuilder<Set<String>>(
              valueListenable: AppSession.instance.favoritesNotifier,
              builder: (_, favs, __) {
                final saved = favs.contains(word.english.toLowerCase());
                return _ContextAction(
                  icon: saved ? Icons.bookmark : Icons.bookmark_border,
                  label: saved ? 'Remove from Saved' : 'Save Word',
                  color: const Color(0xFFD4A017),
                  onTap: () {
                    Navigator.pop(context);
                    final newVal = !saved;
                    word.isFavorite = newVal;
                    AppSession.instance
                        .toggleFavorite(word.english, value: newVal);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  // ── Sort sheet ───────────────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primary = Theme.of(context).colorScheme.primary;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Text('Sort Words',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            ...SortMode.values.map((mode) {
              final labels = {
                SortMode.alphabetical:
                ('A–Z Alphabetical', Icons.sort_by_alpha),
                SortMode.partOfSpeech:
                ('By Part of Speech', Icons.label_outline),
                SortMode.recentlyAdded: ('Default Order', Icons.list),
              };
              final info = labels[mode]!;
              return ListTile(
                leading: Icon(info.$2,
                    color:
                    _sortMode == mode ? primary : Colors.grey),
                title: Text(info.$1,
                    style: GoogleFonts.dmSans(
                        fontWeight: _sortMode == mode
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E))),
                trailing: _sortMode == mode
                    ? Icon(Icons.check_circle, color: primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _sortMode = mode;
                    _applyFilters(_searchCtrl.text, _selectedPOS);
                  });
                },
              );
            }),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  // ── Loading / empty ──────────────────────────────────────────────
  Widget _buildLoading(Color primary) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text('Loading dictionary…',
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        ]));
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No words found',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Try a different search or filter',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: Colors.grey.shade400)),
        ]));
  }

  String _tc(String s) => s.isEmpty
      ? s
      : s
      .split(' ')
      .map((w) => w.isNotEmpty
      ? w[0].toUpperCase() + w.substring(1).toLowerCase()
      : '')
      .join(' ');
}

// ── Context action tile ──────────────────────────────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
      onTap: onTap,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}