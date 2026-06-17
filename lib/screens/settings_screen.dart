import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_session.dart';
import '../services/tts_service.dart';
import '../themes/app_sizing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode =
  PlatformDispatcher.instance.platformBrightness == Brightness.dark
      ? ThemeMode.dark
      : ThemeMode.light;

  double _speechRate = 0.45;
  final session = AppSession.instance;
  final tts = TtsService.instance;

  // Read the persisted value — AppSession.init() already loaded it from prefs
  double get _fontSize => session.fontSizeScale.value;

  bool get _isDark => _themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _speechRate = tts.speechRate;   // restore current TTS rate
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      final b = PlatformDispatcher.instance.platformBrightness;
      setState(() => _themeMode = b == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: Builder(builder: (context) {
        final s = AppSizing.of(context);
        return ListView(
          padding: EdgeInsets.all(s.screenPaddingH),
          children: [
            // ── Appearance ──────────────────────────────────────────
            _SectionHeader(label: 'Appearance', isDark: isDark),
            const SizedBox(height: 8),
            _Card(isDark: isDark, children: [
              _Tile(
                icon: _isDark ? Icons.dark_mode : Icons.light_mode,
                iconColor: _isDark ? const Color(0xFF7B68EE) : const Color(0xFFFFB300),
                title: 'Dark Mode',
                subtitle: _isDark ? 'Dark theme active' : 'Light theme active',
                isDark: isDark,
                trailing: Switch(
                  value: _isDark,
                  onChanged: (v) => setState(() => _themeMode = v ? ThemeMode.dark : ThemeMode.light),
                  activeColor: primary,
                ),
              ),
              _HDivider(isDark: isDark),
              // Font size
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.text_fields, size: 19, color: Color(0xFF4A90D9)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Font Size', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Text(_fontSizeLabel(_fontSize),
                          style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [0.8, 1.0, 1.2].map((size) {
                      final sel = _fontSize == size;
                      return GestureDetector(
                        onTap: () {
                          session.setFontSize(size);
                          setState(() {}); // rebuild to update selected state
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? primary : (isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _fontSizeLabel(size),
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ]),
              ),
            ]),

            // ── Learning ────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Learning', isDark: isDark),
            const SizedBox(height: 8),
            _Card(isDark: isDark, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A017).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_outlined, size: 19, color: Color(0xFFD4A017)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Daily Word Goal', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Text('${session.dailyWordGoal} words per day',
                          style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Slider(
                    value: session.dailyWordGoal.toDouble(),
                    min: 5, max: 30, divisions: 5,
                    activeColor: primary,
                    label: '${session.dailyWordGoal}',
                    onChanged: (v) {
                      setState(() {});
                      session.setDailyGoal(v.round());
                    },
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('5', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade400)),
                    Text('30', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade400)),
                  ]),
                ]),
              ),
            ]),

            // ── Voice / TTS ─────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Voice & Speech', isDark: isDark),
            const SizedBox(height: 8),
            _Card(isDark: isDark, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.record_voice_over_outlined,
                          size: 19, color: Color(0xFF00BFA5)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Speech Rate',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      Text(_speechRateLabel(_speechRate),
                          style: GoogleFonts.dmSans(fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey.shade500)),
                    ])),
                    // Preview button
                    GestureDetector(
                      onTap: () => tts.speak('Hello, this is a preview'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.play_arrow, size: 14, color: Color(0xFF00BFA5)),
                          const SizedBox(width: 4),
                          Text('Preview', style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: const Color(0xFF00BFA5))),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Slider(
                    value: _speechRate,
                    min: 0.1, max: 1.0, divisions: 9,
                    activeColor: const Color(0xFF00BFA5),
                    label: _speechRateLabel(_speechRate),
                    onChanged: (v) {
                      setState(() => _speechRate = v);
                      tts.applySettings(rate: v);
                    },
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Slow', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade400)),
                    Text('Fast', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade400)),
                  ]),
                ]),
              ),
            ]),

            // ── Data ────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Data', isDark: isDark),
            const SizedBox(height: 8),
            _Card(isDark: isDark, children: [
              _Tile(
                icon: Icons.history,
                iconColor: const Color(0xFF7B68EE),
                title: 'Search History',
                subtitle: '${session.searchHistory.length} recent searches',
                isDark: isDark,
                trailing: TextButton(
                  onPressed: session.searchHistory.isEmpty ? null : () {
                    session.clearSearchHistory();
                    setState(() {});
                    _showSnack('Search history cleared');
                  },
                  child: Text('Clear', style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: session.searchHistory.isEmpty ? Colors.grey : Colors.red.shade400)),
                ),
              ),
              _HDivider(isDark: isDark),
              _Tile(
                icon: Icons.visibility_outlined,
                iconColor: const Color(0xFF00BFA5),
                title: 'Recently Viewed',
                subtitle: '${session.recentWords.length} words',
                isDark: isDark,
                trailing: TextButton(
                  onPressed: session.recentWords.isEmpty ? null : () {
                    setState(() => session.clearRecentWords());
                    _showSnack('Recently viewed cleared');
                  },
                  child: Text('Clear', style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: session.recentWords.isEmpty ? Colors.grey : Colors.red.shade400)),
                ),
              ),
              _HDivider(isDark: isDark),
              _Tile(
                icon: Icons.restart_alt,
                iconColor: const Color(0xFFFF5722),
                title: 'Reset Progress',
                subtitle: 'Clear streak & quiz stats',
                isDark: isDark,
                trailing: TextButton(
                  onPressed: () => _confirmReset(),
                  child: Text('Reset', style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                ),
              ),
            ]),

            // ── About ───────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'About', isDark: isDark),
            const SizedBox(height: 8),
            _Card(isDark: isDark, children: [
              _Tile(icon: Icons.info_outline, iconColor: const Color(0xFF4A90D9),
                  title: 'Version', subtitle: '2.0.0', isDark: isDark),
              _HDivider(isDark: isDark),
              _Tile(icon: Icons.people_outline, iconColor: const Color(0xFF00BFA5),
                  title: 'Developed by', subtitle: 'Horn Development Team', isDark: isDark),
              _HDivider(isDark: isDark),
              _Tile(icon: Icons.book_outlined, iconColor: const Color(0xFFD4A017),
                  title: 'Dictionary author', subtitle: 'Prof. Mahdi Hamid Muudeetiin', isDark: isDark),
            ]),
            const SizedBox(height: 32),
          ],
        );
      }), // Builder
    );
  }

  String _speechRateLabel(double rate) {
    if (rate <= 0.3) return 'Very Slow';
    if (rate <= 0.5) return 'Slow';
    if (rate <= 0.65) return 'Normal';
    if (rate <= 0.8) return 'Fast';
    return 'Very Fast';
  }

  String _fontSizeLabel(double size) {
    if (size <= 0.85) return 'Small';
    if (size <= 1.05) return 'Medium';
    return 'Large';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans()),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Progress?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text('This will clear your streak, quiz stats, and session data.',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => session.resetAll());
              _showSnack('Progress reset successfully');
            },
            child: Text('Reset', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label.toUpperCase(),
          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.5, color: isDark ? Colors.white38 : Colors.grey.shade500)),
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _Card({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.07),
              blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.isDark, this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500)),
          ])),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  final bool isDark;
  const _HDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
      height: 1, indent: 68, endIndent: 16,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100);
}