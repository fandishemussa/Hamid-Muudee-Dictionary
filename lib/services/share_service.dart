import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/word.dart';

/// Singleton share service wrapping share_plus.
///
/// Usage:
///   await ShareService.instance.shareWord(word);
///   await ShareService.instance.shareText('Any text');
class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  // ── Share a Word object ───────────────────────────────────────────
  Future<void> shareWord(Word word, {String? subject}) async {
    final text = _buildWordText(word);
    await _share(text, subject: subject ?? word.english);
  }

  // ── Share plain text ─────────────────────────────────────────────
  Future<void> shareText(String text, {String? subject}) async {
    await _share(text, subject: subject);
  }

  // ── Share word of the day ─────────────────────────────────────────
  Future<void> shareWordOfDay(Word word) async {
    final text =
        '☀️ Word of the Day — ${_formatDate()}\n\n'
        '${_buildWordText(word)}';
    await _share(text, subject: 'Word of the Day: ${_tc(word.english)}');
  }

  // ── Internal ──────────────────────────────────────────────────────
  Future<void> _share(String text, {String? subject}) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
    } catch (_) {
      // Fallback: copy to clipboard if share sheet fails
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  String _buildWordText(Word word) {
    final sb = StringBuffer();
    sb.writeln('📖 ${_tc(word.english)}');
    if (word.partOfSpeech.isNotEmpty) {
      sb.writeln('🏷  ${word.partOfSpeech}');
    }
    if (word.pronunciation.isNotEmpty) {
      sb.writeln('🔊 /${word.pronunciation}/');
    }
    if (word.englishDefinition.isNotEmpty) {
      sb.writeln('📝 ${word.englishDefinition}');
    }
    sb.writeln('🇪🇹 Afaan Oromoo: ${_tc(word.oromoTranslation)}');
    sb.writeln();
    sb.write('— Hamid Muudee\'s Dictionary');
    return sb.toString();
  }

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  String _formatDate() {
    final n = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[n.month - 1]} ${n.day}, ${n.year}';
  }
}