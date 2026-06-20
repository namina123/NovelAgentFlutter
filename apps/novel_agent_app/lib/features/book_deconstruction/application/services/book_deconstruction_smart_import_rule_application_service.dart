import 'book_deconstruction_smart_import_rules.dart';
import 'book_deconstruction_smart_import_workspace_service.dart';

class BookDeconstructionSmartImportRuleApplicationService {
  const BookDeconstructionSmartImportRuleApplicationService();

  String apply({
    required BookDeconstructionSmartImportWorkspace workspace,
    required BookDeconstructionSmartImportRules rules,
  }) {
    final selectedPaths = _resolvedSourcePaths(workspace, rules);
    if (selectedPaths.isEmpty) {
      return '';
    }
    final chapterMatchers = _compilePatterns(rules.chapterHeadingPatterns);
    final dropMatchers = _compilePatterns(rules.dropLinePatterns);
    final dropContains = rules.dropLineContains
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final buffer = StringBuffer();
    var wroteNonBlankLine = false;
    var pendingBlankLine = false;

    for (var sourceIndex = 0; sourceIndex < selectedPaths.length; sourceIndex += 1) {
      final path = selectedPaths[sourceIndex];
      final rawText = workspace.stagedSourceTexts[path] ?? '';
      if (rawText.trim().isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty && rules.insertBlankLineBetweenSources) {
        if (!buffer.toString().endsWith('\n\n')) {
          buffer.writeln();
        }
        pendingBlankLine = false;
      }
      for (final rawLine in rawText.replaceAll('\r\n', '\n').split('\n')) {
        final line = rules.trimTrailingWhitespace
            ? rawLine.replaceFirst(RegExp(r'\s+$'), '')
            : rawLine;
        if (_shouldDropLine(
          line: line,
          dropContains: dropContains,
          dropMatchers: dropMatchers,
        )) {
          continue;
        }
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          if (rules.collapseBlankLines) {
            pendingBlankLine = wroteNonBlankLine;
          } else {
            buffer.writeln();
          }
          continue;
        }
        final isChapterHeading = _matchesAny(trimmed, chapterMatchers);
        if ((pendingBlankLine || isChapterHeading) && buffer.isNotEmpty) {
          if (!buffer.toString().endsWith('\n\n')) {
            buffer.writeln();
          }
        }
        pendingBlankLine = false;
        buffer.writeln(line);
        wroteNonBlankLine = true;
      }
    }
    return buffer.toString().trim();
  }

  BookDeconstructionSmartImportRules fallbackRules({
    required BookDeconstructionSmartImportWorkspace workspace,
  }) {
    final combinedSample = workspace.stagedRelativePaths
        .take(3)
        .map((path) => workspace.stagedSourceTexts[path] ?? '')
        .join('\n');
    final chapterPatterns = <String>[
      if (RegExp(r'(^|\n)\s*第[0-9一二三四五六七八九十百千零两]+[章节回集卷]').hasMatch(combinedSample))
        r'^\s*第[0-9一二三四五六七八九十百千零两]+[章节回集卷].*$',
      if (RegExp(r'(^|\n)\s*chapter\s+\d+', caseSensitive: false).hasMatch(combinedSample))
        r'^\s*chapter\s+\d+.*$',
    ];
    return BookDeconstructionSmartImportRules(
      selectedSourcePaths: workspace.stagedRelativePaths,
      chapterHeadingPatterns: chapterPatterns,
      dropLineContains: const <String>[
        '最新网址',
        '备用网址',
        '手机用户请',
        '收藏本站',
        '本书首发',
        '广告赞助',
        '关注公众号',
      ],
      collapseBlankLines: true,
      insertBlankLineBetweenSources: true,
      trimTrailingWhitespace: true,
    );
  }

  List<String> _resolvedSourcePaths(
    BookDeconstructionSmartImportWorkspace workspace,
    BookDeconstructionSmartImportRules rules,
  ) {
    final selected = rules.selectedSourcePaths
        .where(workspace.stagedSourceTexts.containsKey)
        .toList(growable: false);
    if (selected.isNotEmpty) {
      return selected;
    }
    return workspace.stagedRelativePaths;
  }

  bool _shouldDropLine({
    required String line,
    required List<String> dropContains,
    required List<RegExp> dropMatchers,
  }) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    for (final item in dropContains) {
      if (trimmed.contains(item)) {
        return true;
      }
    }
    return _matchesAny(trimmed, dropMatchers);
  }

  bool _matchesAny(String value, List<RegExp> patterns) {
    for (final pattern in patterns) {
      if (pattern.hasMatch(value)) {
        return true;
      }
    }
    return false;
  }

  List<RegExp> _compilePatterns(List<String> patterns) {
    final compiled = <RegExp>[];
    for (final pattern in patterns) {
      final normalized = pattern.trim();
      if (normalized.isEmpty) {
        continue;
      }
      try {
        compiled.add(RegExp(normalized, caseSensitive: false));
      } catch (_) {
        continue;
      }
    }
    return compiled;
  }
}
