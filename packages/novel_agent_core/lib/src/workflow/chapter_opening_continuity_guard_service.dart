import 'chapter_opening_continuity_guard_result.dart';

class ChapterOpeningContinuityGuardService {
  const ChapterOpeningContinuityGuardService({
    this.openingExcerptChars = 240,
    this.previousExcerptChars = 320,
    this.minComparableChars = 24,
    this.ngramLength = 4,
    this.clauseNgramLength = 2,
  });

  final int openingExcerptChars;
  final int previousExcerptChars;
  final int minComparableChars;
  final int ngramLength;
  final int clauseNgramLength;

  ChapterOpeningContinuityGuardResult evaluate({
    required String currentChapterContent,
    String previousChapterContent = '',
    String previousChapterEndExcerpt = '',
    String nextChapterHandoff = '',
  }) {
    final openingExcerpt = _openingExcerpt(currentChapterContent);
    final previousExcerpt = previousChapterEndExcerpt.trim().isNotEmpty
        ? previousChapterEndExcerpt.trim()
        : _tailExcerpt(previousChapterContent);
    if (openingExcerpt.isEmpty || previousExcerpt.isEmpty) {
      return ChapterOpeningContinuityGuardResult(
        blocked: false,
        openingExcerpt: openingExcerpt,
        previousExcerpt: previousExcerpt,
      );
    }

    final normalizedOpening = _normalizeComparable(openingExcerpt);
    final normalizedPrevious = _normalizeComparable(previousExcerpt);
    if (normalizedOpening.length < minComparableChars ||
        normalizedPrevious.length < minComparableChars) {
      return ChapterOpeningContinuityGuardResult(
        blocked: false,
        openingExcerpt: openingExcerpt,
        previousExcerpt: previousExcerpt,
      );
    }

    final openingGrams = _ngrams(normalizedOpening);
    final previousGrams = _ngrams(normalizedPrevious);
    if (openingGrams.isEmpty || previousGrams.isEmpty) {
      return ChapterOpeningContinuityGuardResult(
        blocked: false,
        openingExcerpt: openingExcerpt,
        previousExcerpt: previousExcerpt,
      );
    }

    final overlap = openingGrams.intersection(previousGrams).length;
    final openingCoverage = overlap / openingGrams.length;
    final previousCoverage = overlap / previousGrams.length;
    final replayedClauses = _replayedClauses(
      previousExcerpt: previousExcerpt,
      openingExcerpt: openingExcerpt,
    );
    final replayedActionAnchors = _replayedActionAnchors(
      previousExcerpt: previousExcerpt,
      openingExcerpt: openingExcerpt,
    );
    final longestCommonSpan = _longestCommonSpan(
      normalizedOpening,
      normalizedPrevious,
    );
    final handoffRequiresAdvance = _handoffRequiresAdvance(nextChapterHandoff);

    final blocked =
        replayedClauses.length >= 2 ||
        (handoffRequiresAdvance && replayedClauses.isNotEmpty) ||
        (handoffRequiresAdvance && replayedActionAnchors.length >= 2) ||
        (openingCoverage >= 0.24 &&
            previousCoverage >= 0.18 &&
            longestCommonSpan >= 10) ||
        (handoffRequiresAdvance &&
            openingCoverage >= 0.18 &&
            previousCoverage >= 0.14 &&
            longestCommonSpan >= 8);
    if (!blocked) {
      return ChapterOpeningContinuityGuardResult(
        blocked: false,
        openingExcerpt: openingExcerpt,
        previousExcerpt: previousExcerpt,
        longestCommonSpan: longestCommonSpan,
        openingCoverage: openingCoverage,
        previousCoverage: previousCoverage,
        replayedClauses: replayedClauses,
        replayedActionAnchors: replayedActionAnchors,
      );
    }

    final summary = handoffRequiresAdvance
        ? '章节开篇疑似回退重演上一章末尾已完成动作，没有直接承接下一章入口。'
        : '章节开篇疑似回退重演上一章末尾已完成动作。';
    return ChapterOpeningContinuityGuardResult(
      blocked: true,
      reason: 'chapter_opening_replays_previous_tail',
      summary: summary,
      openingExcerpt: openingExcerpt,
      previousExcerpt: previousExcerpt,
      longestCommonSpan: longestCommonSpan,
      openingCoverage: openingCoverage,
      previousCoverage: previousCoverage,
      replayedClauses: replayedClauses,
      replayedActionAnchors: replayedActionAnchors,
    );
  }

  String _openingExcerpt(String chapterContent) {
    final body = _chapterBodyWithoutHeading(chapterContent);
    if (body.isEmpty) {
      return '';
    }
    final excerpt = body.length <= openingExcerptChars
        ? body
        : body.substring(0, openingExcerptChars);
    return excerpt.trim();
  }

  String _tailExcerpt(String chapterContent) {
    final body = _chapterBodyWithoutHeading(chapterContent);
    if (body.isEmpty) {
      return '';
    }
    if (body.length <= previousExcerptChars) {
      return body.trim();
    }
    final start = body.length - previousExcerptChars;
    final boundary = body.indexOf('\n', start);
    if (boundary >= start && boundary < body.length - 80) {
      return body.substring(boundary + 1).trim();
    }
    return body.substring(start).trim();
  }

  String _chapterBodyWithoutHeading(String chapterContent) {
    final lines = chapterContent.replaceAll('\r\n', '\n').split('\n');
    var index = 0;
    while (index < lines.length && lines[index].trim().isEmpty) {
      index += 1;
    }
    if (index < lines.length && lines[index].trim().startsWith('#')) {
      index += 1;
      while (index < lines.length && lines[index].trim().isEmpty) {
        index += 1;
      }
    } else {
      index = 0;
    }
    return lines.skip(index).join('\n').trim();
  }

  String _normalizeComparable(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      if (_isComparableRune(rune, char)) {
        buffer.write(char.toLowerCase());
      }
    }
    return buffer.toString();
  }

  bool _isComparableRune(int rune, String char) {
    final isAsciiLetterOrDigit =
        (rune >= 48 && rune <= 57) ||
        (rune >= 65 && rune <= 90) ||
        (rune >= 97 && rune <= 122);
    if (isAsciiLetterOrDigit) {
      return true;
    }
    if (rune >= 0x4e00 && rune <= 0x9fff) {
      return true;
    }
    return false;
  }

  Set<String> _ngrams(String value) {
    if (value.length < ngramLength) {
      return const <String>{};
    }
    final result = <String>{};
    for (var index = 0; index <= value.length - ngramLength; index += 1) {
      result.add(value.substring(index, index + ngramLength));
    }
    return result;
  }

  Set<String> _clauseNgrams(String value) {
    if (value.length < clauseNgramLength) {
      return const <String>{};
    }
    final result = <String>{};
    for (var index = 0; index <= value.length - clauseNgramLength; index += 1) {
      result.add(value.substring(index, index + clauseNgramLength));
    }
    return result;
  }

  List<String> _replayedClauses({
    required String previousExcerpt,
    required String openingExcerpt,
  }) {
    final result = <String>[];
    final seen = <String>{};
    final previousClauses = _splitClauses(
      previousExcerpt,
    ).toList(growable: false);
    for (final clause in _splitClauses(openingExcerpt)) {
      final normalizedClause = _normalizeComparable(clause);
      if (normalizedClause.length < 8 || !seen.add(normalizedClause)) {
        continue;
      }
      final clauseGrams = _clauseNgrams(normalizedClause);
      if (clauseGrams.isEmpty) {
        continue;
      }
      for (final previousClause in previousClauses) {
        final normalizedPreviousClause = _normalizeComparable(previousClause);
        if (normalizedPreviousClause.length < 8) {
          continue;
        }
        final previousClauseGrams = _clauseNgrams(normalizedPreviousClause);
        if (previousClauseGrams.isEmpty) {
          continue;
        }
        final overlap = clauseGrams.intersection(previousClauseGrams).length;
        final denominator = clauseGrams.length <= previousClauseGrams.length
            ? clauseGrams.length
            : previousClauseGrams.length;
        final ratio = denominator <= 0 ? 0 : overlap / denominator;
        if (overlap >= 2 && ratio >= 0.34) {
          result.add(clause.trim());
          break;
        }
      }
    }
    return List<String>.unmodifiable(result);
  }

  Iterable<String> _splitClauses(String value) sync* {
    final normalized = value.replaceAll('\r\n', '\n');
    for (final raw in normalized.split(RegExp(r'[\n。！？!?；;，,]'))) {
      final clean = raw.trim();
      if (clean.isNotEmpty) {
        yield clean;
      }
    }
  }

  List<String> _replayedActionAnchors({
    required String previousExcerpt,
    required String openingExcerpt,
  }) {
    final previous = previousExcerpt.replaceAll(RegExp(r'\s+'), '');
    final opening = openingExcerpt.replaceAll(RegExp(r'\s+'), '');
    final result = <String>[];
    const markerGroups = <Map<String, Object>>[
      <String, Object>{
        'label': 'door_position',
        'phrases': <String>['门口', '门前'],
      },
      <String, Object>{
        'label': 'hand_raise',
        'phrases': <String>['抬手', '伸手'],
      },
      <String, Object>{
        'label': 'knock_action',
        'phrases': <String>['敲门', '敲了', '敲三下', '敲'],
      },
      <String, Object>{
        'label': 'inside_response',
        'phrases': <String>['门里', '门内', '里头', '里面'],
      },
      <String, Object>{
        'label': 'door_open',
        'phrases': <String>['开门', '门开', '门才开', '开了条缝'],
      },
    ];
    for (final group in markerGroups) {
      final label = group['label'] as String;
      final phrases = group['phrases'] as List<String>;
      var previousMatched = false;
      var openingMatched = false;
      for (final phrase in phrases) {
        if (!previousMatched && previous.contains(phrase)) {
          previousMatched = true;
        }
        if (!openingMatched && opening.contains(phrase)) {
          openingMatched = true;
        }
      }
      if (previousMatched && openingMatched && !result.contains(label)) {
        result.add(label);
      }
    }
    return List<String>.unmodifiable(result);
  }

  int _longestCommonSpan(String left, String right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    var best = 0;
    final table = List<int>.filled(right.length + 1, 0);
    for (var i = 1; i <= left.length; i += 1) {
      var previous = 0;
      for (var j = 1; j <= right.length; j += 1) {
        final cached = table[j];
        if (left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1)) {
          table[j] = previous + 1;
          if (table[j] > best) {
            best = table[j];
          }
        } else {
          table[j] = 0;
        }
        previous = cached;
      }
    }
    return best;
  }

  bool _handoffRequiresAdvance(String handoff) {
    final clean = handoff.trim();
    if (clean.isEmpty) {
      return false;
    }
    return clean.contains('不要回退重演') ||
        clean.contains('直接从') ||
        clean.contains('继续') ||
        clean.contains('回应') ||
        clean.contains('回答');
  }
}
