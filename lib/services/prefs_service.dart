import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence layer for AppSession.
///
/// All keys are namespaced under 'hmd_' (Hamid Muudee's Dictionary)
/// to avoid collisions with other apps on the same device.
///
/// Call [PrefsService.load()] once in [AppSession.init()] before the
/// app renders, then call the appropriate [save*] method after every
/// mutation that should survive restarts.
class PrefsService {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  SharedPreferences? _prefs;

  // ── Key constants ─────────────────────────────────────────────────
  static const _kSearchHistory      = 'hmd_search_history';
  static const _kRecentWords        = 'hmd_recent_words';
  static const _kStreakDays         = 'hmd_streak_days';
  static const _kLastActiveDate     = 'hmd_last_active_date';
  static const _kWordsViewedToday   = 'hmd_words_viewed_today';
  static const _kQuizzesToday       = 'hmd_quizzes_today';
  static const _kCorrectTotal       = 'hmd_correct_total';
  static const _kTotalAnswers       = 'hmd_total_answers';
  static const _kDailyGoal         = 'hmd_daily_goal';
  static const _kFavorites          = 'hmd_favorites';
  static const _kLastCountedDay     = 'hmd_last_counted_day';
  static const _kFontSize           = 'hmd_font_size';       // double: 0.8/1.0/1.2

  // ── Initialise ────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null,
    'PrefsService.init() must be awaited before using PrefsService');
    return _prefs!;
  }

  // ── Search history ────────────────────────────────────────────────
  List<String> loadSearchHistory() =>
      _p.getStringList(_kSearchHistory) ?? [];

  Future<void> saveSearchHistory(List<String> history) =>
      _p.setStringList(_kSearchHistory, history);

  // ── Recently viewed ───────────────────────────────────────────────
  List<String> loadRecentWords() =>
      _p.getStringList(_kRecentWords) ?? [];

  Future<void> saveRecentWords(List<String> words) =>
      _p.setStringList(_kRecentWords, words);

  // ── Streak & activity ─────────────────────────────────────────────
  int loadStreakDays() => _p.getInt(_kStreakDays) ?? 0;

  Future<void> saveStreakDays(int days) => _p.setInt(_kStreakDays, days);

  DateTime? loadLastActiveDate() {
    final s = _p.getString(_kLastActiveDate);
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<void> saveLastActiveDate(DateTime? date) => date != null
      ? _p.setString(_kLastActiveDate, date.toIso8601String())
      : _p.remove(_kLastActiveDate);

  // ── Daily counters ────────────────────────────────────────────────
  /// Returns the last day daily counters were recorded, e.g. '2025-06-15'.
  String? loadLastCountedDay() => _p.getString(_kLastCountedDay);

  Future<void> saveLastCountedDay(String day) =>
      _p.setString(_kLastCountedDay, day);

  int loadWordsViewedToday() => _p.getInt(_kWordsViewedToday) ?? 0;
  Future<void> saveWordsViewedToday(int n) => _p.setInt(_kWordsViewedToday, n);

  int loadQuizzesToday() => _p.getInt(_kQuizzesToday) ?? 0;
  Future<void> saveQuizzesToday(int n) => _p.setInt(_kQuizzesToday, n);

  // ── Quiz totals ───────────────────────────────────────────────────
  int loadCorrectTotal() => _p.getInt(_kCorrectTotal) ?? 0;
  Future<void> saveCorrectTotal(int n) => _p.setInt(_kCorrectTotal, n);

  int loadTotalAnswers() => _p.getInt(_kTotalAnswers) ?? 0;
  Future<void> saveTotalAnswers(int n) => _p.setInt(_kTotalAnswers, n);

  // ── Daily goal ────────────────────────────────────────────────────
  int loadDailyGoal() => _p.getInt(_kDailyGoal) ?? 10;
  Future<void> saveDailyGoal(int n) => _p.setInt(_kDailyGoal, n);

  // ── Favorites ─────────────────────────────────────────────────────
  /// Returns the Set of favorited word english strings.
  Set<String> loadFavorites() =>
      (_p.getStringList(_kFavorites) ?? []).toSet();

  Future<void> saveFavorites(Set<String> favorites) =>
      _p.setStringList(_kFavorites, favorites.toList());

  /// Adds/removes a single word from the persisted favorites set.
  Future<void> toggleFavorite(String english, {required bool isFavorite}) async {
    final favs = loadFavorites();
    if (isFavorite) {
      favs.add(english.toLowerCase());
    } else {
      favs.remove(english.toLowerCase());
    }
    await saveFavorites(favs);
  }

  // ── Font size ──────────────────────────────────────────────────────
  double loadFontSize() => _p.getDouble(_kFontSize) ?? 1.0;
  Future<void> saveFontSize(double size) => _p.setDouble(_kFontSize, size);

  // ── Full wipe ─────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await Future.wait([
      _p.remove(_kSearchHistory),
      _p.remove(_kRecentWords),
      _p.remove(_kStreakDays),
      _p.remove(_kLastActiveDate),
      _p.remove(_kWordsViewedToday),
      _p.remove(_kQuizzesToday),
      _p.remove(_kCorrectTotal),
      _p.remove(_kTotalAnswers),
      _p.remove(_kDailyGoal),
      _p.remove(_kFavorites),
      _p.remove(_kLastCountedDay),
      _p.remove(_kFontSize),
    ]);
  }
}