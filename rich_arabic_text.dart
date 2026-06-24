import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

/// Renders the refined Arabic transcription with:
///  - English medical terms highlighted in teal + bold
///  - Search query matches highlighted in amber
///  - Adjustable font size
///  - Right-to-left paragraph layout
class RichArabicText extends StatelessWidget {
  const RichArabicText({
    super.key,
    required this.text,
    required this.fontSize,
    this.searchQuery = '',
  });

  final String text;
  final double fontSize;
  final String searchQuery;

  // Matches ASCII-only words of 3+ chars (English medical terms)
  static final _enTermPattern = RegExp(r'\b([A-Za-z][A-Za-z0-9\-]{2,})\b');

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs
          .map((para) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildParagraph(para),
              ))
          .toList(),
    );
  }

  Widget _buildParagraph(String para) {
    return Text.rich(
      _buildSpans(para),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      style: GoogleFonts.notoSansArabic(
        fontSize: fontSize,
        height: 2.2,
        color: AppColors.textPrimary,
      ),
    );
  }

  TextSpan _buildSpans(String text) {
    // We need to apply two overlapping highlight layers:
    // 1. English terms → teal bold
    // 2. Search query  → amber background
    // Strategy: tokenise by English terms first, then within each segment
    // apply search highlighting.

    final children = <InlineSpan>[];
    int cursor = 0;

    for (final match in _enTermPattern.allMatches(text)) {
      // Non-English region before this match
      if (match.start > cursor) {
        final segment = text.substring(cursor, match.start);
        children.addAll(_highlightSearch(segment, isEnglish: false));
      }
      // English term
      children.addAll(_highlightSearch(match.group(0)!, isEnglish: true));
      cursor = match.end;
    }

    // Remaining non-English text
    if (cursor < text.length) {
      children.addAll(_highlightSearch(text.substring(cursor), isEnglish: false));
    }

    return TextSpan(children: children);
  }

  List<InlineSpan> _highlightSearch(String segment, {required bool isEnglish}) {
    final baseStyle = isEnglish
        ? TextStyle(
            color: AppColors.enTerm,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          )
        : const TextStyle();

    if (searchQuery.isEmpty) {
      return [TextSpan(text: segment, style: baseStyle)];
    }

    final spans = <InlineSpan>[];
    final lower = segment.toLowerCase();
    final query = searchQuery.toLowerCase();
    int pos = 0;

    while (true) {
      final idx = lower.indexOf(query, pos);
      if (idx == -1) {
        spans.add(TextSpan(text: segment.substring(pos), style: baseStyle));
        break;
      }
      if (idx > pos) {
        spans.add(TextSpan(text: segment.substring(pos, idx), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: segment.substring(idx, idx + query.length),
          style: baseStyle.copyWith(
            backgroundColor: AppColors.amber.withOpacity(0.35),
            color: AppColors.amber,
          ),
        ),
      );
      pos = idx + query.length;
    }

    return spans;
  }
}
