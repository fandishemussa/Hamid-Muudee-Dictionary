import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_sizing.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final s = AppSizing.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(s.screenPaddingH, s.lg, s.screenPaddingH, 100),
      child: Column(
        children: [
          // App icon & name
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2D2D5A), const Color(0xFF1A1A3E)]
                    : [const Color(0xFFFFF8E1), const Color(0xFFFFF3E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 16),
                Text(
                  "Hamid Muudee's Dictionary",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'English ↔ Afaan Oromoo',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Author section
          _SectionCard(
            title: 'About the Author',
            icon: Icons.person_outline,
            isDark: isDark,
            primary: primary,
            children: [
              _InfoRow(
                label: 'Professor',
                value: 'Mahdi Hamid Muudeetiin',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'A dedicated scholar and linguist who has made significant contributions to the documentation and preservation of the Afaan Oromoo language.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Developer section
          _SectionCard(
            title: 'Development Team',
            icon: Icons.code_outlined,
            isDark: isDark,
            primary: primary,
            children: [
              _InfoRow(
                label: 'Developed by',
                value: 'Horn Development Team',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Features section
          _SectionCard(
            title: 'App Features',
            icon: Icons.star_outline,
            isDark: isDark,
            primary: primary,
            children: [
              _FeatureItem(icon: Icons.search, text: 'Full-text search in English & Oromo', primary: primary),
              _FeatureItem(icon: Icons.filter_list, text: 'Filter by part of speech', primary: primary),
              _FeatureItem(icon: Icons.bookmark_border, text: 'Save favorite words', primary: primary),
              _FeatureItem(icon: Icons.style_outlined, text: 'Interactive flashcards with flip animation', primary: primary),
              _FeatureItem(icon: Icons.quiz_outlined, text: 'Quick quiz to test knowledge', primary: primary),
              _FeatureItem(icon: Icons.wb_sunny_outlined, text: 'Word of the day', primary: primary),
              _FeatureItem(icon: Icons.copy_outlined, text: 'Copy words to clipboard', primary: primary),
              _FeatureItem(icon: Icons.dark_mode_outlined, text: 'Dark & light mode', primary: primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Color primary;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.primary,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color primary;

  const _FeatureItem({required this.icon, required this.text, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}