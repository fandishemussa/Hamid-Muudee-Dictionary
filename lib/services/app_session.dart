import 'package:flutter/foundation.dart';
import '../models/word.dart';
import 'prefs_service.dart';
/// App-wide session singleton.
///
/// **All data survives app restarts** via SharedPreferences through PrefsService.
///
/// Call [AppSession.init()] once in main() before runApp():
///
///   void main() async {
///     WidgetsFlutterBinding.ensureInitialized();
///     await AppSession.init();
///     runApp(const OromoDictionaryApp());
///   }
class AppSession {
  AppSession._();
  static final AppSession instance = AppSession._();

  final _prefs = PrefsService.instance;
  bool _ready = false;

  // ── Bootstrap ────────────────────────────────────────────────────
  /// Must be awaited once before the app renders.
  static Future<void> init() async {
    await PrefsService.instance.init();
    await instance._load();
  }

  Future<void> _load() async {
    if (_ready) return;
    _ready = true;

    // Search history
    _searchHistory
      ..clear()
      ..addAll(_prefs.loadSearchHistory());

    // Recently viewed
    _recentWords
      ..clear()
      ..addAll(_prefs.loadRecentWords());

    // Streak & activity
    _streakDays      = _prefs.loadStreakDays();
    _lastActiveDate  = _prefs.loadLastActiveDate();

    // Daily counters — reset if it's a new day
    final savedDay = _prefs.loadLastCountedDay();
    final todayStr = _dayString(DateTime.now());
    if (savedDay == todayStr) {
      _wordsViewedToday       = _prefs.loadWordsViewedToday();
      _quizzesCompletedToday  = _prefs.loadQuizzesToday();
    } else {
      // New day — wipe daily counters but keep streak
      _wordsViewedToday      = 0;
      _quizzesCompletedToday = 0;
      await Future.wait([
        _prefs.saveWordsViewedToday(0),
        _prefs.saveQuizzesToday(0),
        _prefs.saveLastCountedDay(todayStr),
      ]);
    }

    // Quiz totals
    _correctAnswersTotal = _prefs.loadCorrectTotal();
    _totalAnswers        = _prefs.loadTotalAnswers();

    // Daily goal
    _dailyWordGoal = _prefs.loadDailyGoal();

    // Font size
    fontSizeScale.value = _prefs.loadFontSize();

    // Favorites
    favoritesNotifier.value = _prefs.loadFavorites();
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH HISTORY
  // ═══════════════════════════════════════════════════════════════════
  final List<String> _searchHistory = [];
  static const int _maxHistory = 20;

  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > _maxHistory) _searchHistory.removeLast();
    await _prefs.saveSearchHistory(_searchHistory);
  }

  Future<void> removeSearch(String query) async {
    _searchHistory.remove(query);
    await _prefs.saveSearchHistory(_searchHistory);
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    await _prefs.saveSearchHistory([]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECENTLY VIEWED
  // ═══════════════════════════════════════════════════════════════════
  final List<String> _recentWords = [];
  static const int _maxRecent = 30;

  List<String> get recentWords => List.unmodifiable(_recentWords);

  Future<void> addRecentWord(String english) async {
    _recentWords.remove(english);
    _recentWords.insert(0, english);
    if (_recentWords.length > _maxRecent) _recentWords.removeLast();
    await _prefs.saveRecentWords(_recentWords);
  }

  Future<void> clearRecentWords() async {
    _recentWords.clear();
    await _prefs.saveRecentWords([]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // FONT SIZE  (ValueNotifier so MaterialApp rebuilds reactively)
  // ═══════════════════════════════════════════════════════════════════
  /// 0.8 = Small · 1.0 = Medium · 1.2 = Large
  final ValueNotifier<double> fontSizeScale = ValueNotifier(1.0);

  Future<void> setFontSize(double scale) async {
    fontSizeScale.value = scale;
    await _prefs.saveFontSize(scale);
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITES  — ValueNotifier so every screen rebuilds automatically
  // ═══════════════════════════════════════════════════════════════════

  /// The reactive set of lowercased english keys that are bookmarked.
  /// Wrap any bookmark UI in ValueListenableBuilder(valueListenable:
  /// AppSession.instance.favoritesNotifier, ...) to auto-rebuild.
  final ValueNotifier<Set<String>> favoritesNotifier =
  ValueNotifier(<String>{});

  /// Convenience getter — unmodifiable snapshot.
  Set<String> get favorites => Set.unmodifiable(favoritesNotifier.value);

  /// Returns true if [english] is currently bookmarked.
  bool isFavorite(String english) =>
      favoritesNotifier.value.contains(english.toLowerCase());

  /// Toggle bookmark, notify listeners, persist to prefs.
  Future<void> toggleFavorite(String english, {required bool value}) async {
    final updated = Set<String>.from(favoritesNotifier.value);
    if (value) {
      updated.add(english.toLowerCase());
    } else {
      updated.remove(english.toLowerCase());
    }
    // Assign new set so ValueNotifier fires (same-ref mutations are ignored)
    favoritesNotifier.value = updated;
    await _prefs.saveFavorites(updated);
  }

  /// Apply persisted favorites onto a list of Word objects.
  /// Call once after loading the dictionary.
  void applyFavoritesToWords(List<Word> words) {
    final favs = favoritesNotifier.value;
    for (final w in words) {
      w.isFavorite = favs.contains(w.english.toLowerCase());
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // STREAK & DAILY ACTIVITY
  // ═══════════════════════════════════════════════════════════════════
  int _streakDays            = 0;
  DateTime? _lastActiveDate;
  int _wordsViewedToday      = 0;
  int _quizzesCompletedToday = 0;

  int get streakDays            => _streakDays;
  int get wordsViewedToday      => _wordsViewedToday;
  int get quizzesCompletedToday => _quizzesCompletedToday;

  Future<void> _recordActivity() async {
    final today = DateTime.now();
    final todayStr = _dayString(today);

    if (_lastActiveDate == null) {
      _streakDays = 1;
    } else {
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(
        _lastActiveDate!.year,
        _lastActiveDate!.month,
        _lastActiveDate!.day,
      ))
          .inDays;
      if (diff == 1) {
        _streakDays++;
      } else if (diff > 1) {
        _streakDays = 1;
      }
      // diff == 0 → same day → streak unchanged
    }
    _lastActiveDate = today;

    await Future.wait([
      _prefs.saveStreakDays(_streakDays),
      _prefs.saveLastActiveDate(_lastActiveDate),
      _prefs.saveLastCountedDay(todayStr),
    ]);
  }

  Future<void> recordWordViewed() async {
    _wordsViewedToday++;
    await Future.wait([
      _prefs.saveWordsViewedToday(_wordsViewedToday),
      _recordActivity(),
    ]);
  }

  Future<void> recordQuizCompleted() async {
    _quizzesCompletedToday++;
    await Future.wait([
      _prefs.saveQuizzesToday(_quizzesCompletedToday),
      _recordActivity(),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUIZ ACCURACY
  // ═══════════════════════════════════════════════════════════════════
  int _correctAnswersTotal = 0;
  int _totalAnswers        = 0;

  int    get correctAnswersTotal => _correctAnswersTotal;
  int    get totalAnswers        => _totalAnswers;
  double get accuracyPercent     =>
      _totalAnswers == 0 ? 0.0 : _correctAnswersTotal / _totalAnswers * 100;

  Future<void> recordQuizAnswer({required bool correct}) async {
    _totalAnswers++;
    if (correct) _correctAnswersTotal++;
    await Future.wait([
      _prefs.saveTotalAnswers(_totalAnswers),
      _prefs.saveCorrectTotal(_correctAnswersTotal),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // DAILY GOAL
  // ═══════════════════════════════════════════════════════════════════
  int _dailyWordGoal = 10;

  int get dailyWordGoal => _dailyWordGoal;

  double get dailyGoalProgress =>
      (_wordsViewedToday / _dailyWordGoal).clamp(0.0, 1.0);

  Future<void> setDailyGoal(int goal) async {
    _dailyWordGoal = goal;
    await _prefs.saveDailyGoal(goal);
  }

  // ═══════════════════════════════════════════════════════════════════
  // DAILY RESET (call in initState of long-lived screens as a guard)
  // ═══════════════════════════════════════════════════════════════════
  void resetDailyIfNeeded() {
    final today = DateTime.now();
    if (_lastActiveDate != null &&
        _lastActiveDate!.day != today.day) {
      _wordsViewedToday      = 0;
      _quizzesCompletedToday = 0;
      _prefs.saveWordsViewedToday(0);
      _prefs.saveQuizzesToday(0);
      _prefs.saveLastCountedDay(_dayString(today));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // FULL RESET
  // ═══════════════════════════════════════════════════════════════════
  Future<void> resetAll() async {
    _searchHistory.clear();
    _recentWords.clear();
    favoritesNotifier.value = {};
    _streakDays            = 0;
    _lastActiveDate        = null;
    _wordsViewedToday      = 0;
    _quizzesCompletedToday = 0;
    _correctAnswersTotal   = 0;
    _totalAnswers          = 0;
    _dailyWordGoal         = 10;
    fontSizeScale.value    = 1.0;
    await _prefs.clearAll();
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════
  String _dayString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}