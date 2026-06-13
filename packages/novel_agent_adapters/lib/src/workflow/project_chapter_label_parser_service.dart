class ProjectChapterLabelParseResult {
  const ProjectChapterLabelParseResult({
    required this.chapterNumber,
    required this.width,
    required this.matchedText,
    required this.start,
    required this.end,
  });

  final int chapterNumber;
  final int width;
  final String matchedText;
  final int start;
  final int end;

  String get canonicalLabel =>
      '第${chapterNumber.toString().padLeft(width, '0')}章';
}

class ProjectChapterLabelParserService {
  const ProjectChapterLabelParserService();

  static final RegExp _arabicPattern = RegExp(r'第\s*([0-9０-９]+)\s*章');
  static final RegExp _chinesePattern = RegExp(
    r'第\s*([零〇一二三四五六七八九十百千万两]+)\s*章',
  );
  static final RegExp _targetCuePattern = RegExp(
    r'(继续写|续写|写到|写出|写成|写完|写出来|补完|补写|生成|推进|进入|创作|修订|修复|重写|改写|审一下|审稿|review|rewrite|repair)',
    caseSensitive: false,
  );
  static final RegExp _targetSuffixPattern = RegExp(r'(正文|开头|本章|正式|一章)');
  static final RegExp _referenceCuePattern = RegExp(
    r'(章末|末尾|门前动作|前文|上一章|上章|前一章|参考|承接|呼应|对照|回看|摘要|时间线|交付)',
  );

  ProjectChapterLabelParseResult? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final matches = findAll(trimmed);
    if (matches.isEmpty) {
      return null;
    }
    return matches.first;
  }

  List<ProjectChapterLabelParseResult> findAll(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const <ProjectChapterLabelParseResult>[];
    }
    final results = <ProjectChapterLabelParseResult>[
      ..._collectMatches(
        trimmed,
        _arabicPattern,
        numericParser: (rawDigits) {
          final normalizedDigits = _normalizeDigits(rawDigits);
          final chapterNumber = int.tryParse(normalizedDigits);
          if (chapterNumber == null || chapterNumber <= 0) {
            return null;
          }
          return (chapterNumber, _normalizedWidth(normalizedDigits.length));
        },
      ),
      ..._collectMatches(
        trimmed,
        _chinesePattern,
        numericParser: (rawDigits) {
          final chapterNumber = _parseChineseNumber(rawDigits);
          if (chapterNumber == null || chapterNumber <= 0) {
            return null;
          }
          return (
            chapterNumber,
            _normalizedWidth(chapterNumber.toString().length),
          );
        },
      ),
    ]..sort((left, right) => left.start.compareTo(right.start));
    return List<ProjectChapterLabelParseResult>.unmodifiable(results);
  }

  bool hasChapterLabel(String text) => findAll(text).isNotEmpty;

  int? extractChapterNumber(String text) => parse(text)?.chapterNumber;

  String extractCanonicalLabel(String text) =>
      parse(text)?.canonicalLabel ?? '';

  int? extractLikelyTargetChapterNumber(String text) =>
      _likelyTarget(text)?.chapterNumber;

  String extractLikelyTargetCanonicalLabel(String text) =>
      _likelyTarget(text)?.canonicalLabel ?? '';

  String canonicalLabelForNumber(int chapterNumber, {int width = 2}) {
    if (chapterNumber <= 0) {
      return '';
    }
    return '第${chapterNumber.toString().padLeft(_normalizedWidth(width), '0')}章';
  }

  int _normalizedWidth(int width) {
    final digitWidth = width <= 0 ? 2 : width;
    return digitWidth.clamp(2, 4);
  }

  String _normalizeDigits(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    for (final codeUnit in raw.codeUnits) {
      if (codeUnit >= 0xFF10 && codeUnit <= 0xFF19) {
        buffer.writeCharCode(codeUnit - 0xFF10 + 0x30);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  int? _parseChineseNumber(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (!normalized.contains(RegExp(r'[十百千万]'))) {
      final digitString = normalized
          .split('')
          .map((char) => _digitValue(char))
          .whereType<int>()
          .map((value) => value.toString())
          .join();
      return digitString.isEmpty ? null : int.tryParse(digitString);
    }

    final wanIndex = normalized.indexOf('万');
    if (wanIndex >= 0) {
      final high = normalized.substring(0, wanIndex);
      final low = normalized.substring(wanIndex + 1);
      final highValue = _parseChineseSection(high);
      final lowValue = low.isEmpty ? 0 : _parseChineseSection(low);
      if (highValue == null || lowValue == null) {
        return null;
      }
      return (highValue * 10000) + lowValue;
    }
    return _parseChineseSection(normalized);
  }

  int? _parseChineseSection(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return 0;
    }
    var result = 0;
    var currentDigit = 0;
    for (final char in normalized.split('')) {
      final unitValue = _unitValue(char);
      if (unitValue != null) {
        final factor = currentDigit == 0 ? 1 : currentDigit;
        result += factor * unitValue;
        currentDigit = 0;
        continue;
      }
      final digitValue = _digitValue(char);
      if (digitValue == null) {
        return null;
      }
      currentDigit = digitValue;
    }
    return result + currentDigit;
  }

  int? _digitValue(String char) {
    return switch (char) {
      '零' || '〇' => 0,
      '一' => 1,
      '二' || '两' => 2,
      '三' => 3,
      '四' => 4,
      '五' => 5,
      '六' => 6,
      '七' => 7,
      '八' => 8,
      '九' => 9,
      _ => null,
    };
  }

  int? _unitValue(String char) {
    return switch (char) {
      '十' => 10,
      '百' => 100,
      '千' => 1000,
      _ => null,
    };
  }

  List<ProjectChapterLabelParseResult> _collectMatches(
    String text,
    RegExp pattern, {
    required (int, int)? Function(String rawDigits) numericParser,
  }) {
    final results = <ProjectChapterLabelParseResult>[];
    for (final match in pattern.allMatches(text)) {
      final rawDigits = match.group(1) ?? '';
      final parsed = numericParser(rawDigits);
      if (parsed == null) {
        continue;
      }
      final (chapterNumber, width) = parsed;
      results.add(
        ProjectChapterLabelParseResult(
          chapterNumber: chapterNumber,
          width: width,
          matchedText: (match.group(0) ?? '').trim(),
          start: match.start,
          end: match.end,
        ),
      );
    }
    return results;
  }

  ProjectChapterLabelParseResult? _likelyTarget(String text) {
    final matches = findAll(text);
    if (matches.isEmpty) {
      return null;
    }
    if (matches.length == 1) {
      return matches.single;
    }
    ProjectChapterLabelParseResult? best;
    var bestScore = -1 << 20;
    for (var index = 0; index < matches.length; index += 1) {
      final candidate = matches[index];
      final score = _targetScore(
        text,
        candidate,
        index: index,
        totalMatches: matches.length,
      );
      if (best == null ||
          score > bestScore ||
          (score == bestScore && candidate.start > best.start)) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  int _targetScore(
    String text,
    ProjectChapterLabelParseResult candidate, {
    required int index,
    required int totalMatches,
  }) {
    var score = index * 8;
    if (index == totalMatches - 1) {
      score += 12;
    }
    final before = _window(text, candidate.start - 18, candidate.start);
    final after = _window(text, candidate.end, candidate.end + 18);
    final combined = '$before ${candidate.matchedText} $after';
    if (_targetCuePattern.hasMatch(before) ||
        _targetCuePattern.hasMatch(combined)) {
      score += 120;
    }
    if (_targetSuffixPattern.hasMatch(after)) {
      score += 35;
    }
    if (_referenceCuePattern.hasMatch(after)) {
      score -= 80;
    }
    if (_referenceCuePattern.hasMatch(before) &&
        !_targetCuePattern.hasMatch(before)) {
      score -= 20;
    }
    return score;
  }

  String _window(String text, int start, int end) {
    final safeStart = start < 0 ? 0 : start;
    final safeEnd = end > text.length ? text.length : end;
    if (safeStart >= safeEnd) {
      return '';
    }
    return text.substring(safeStart, safeEnd);
  }
}
