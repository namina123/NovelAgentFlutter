import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/book_deconstruction_draft_build_result.dart';

class BookDeconstructionDraftBuilderService {
  BookDeconstructionDraftBuilderService({
    BuildBookDeconstructionApplicationPlanUseCase? buildApplicationPlanUseCase,
    BookDeconstructionFollowupMenuBuilderService? followupMenuBuilderService,
    BookDeconstructionNarrativeBridgeService? narrativeBridgeService,
  }) : _buildApplicationPlanUseCase =
           buildApplicationPlanUseCase ??
           BuildBookDeconstructionApplicationPlanUseCase(),
       _followupMenuBuilderService =
           followupMenuBuilderService ??
           const BookDeconstructionFollowupMenuBuilderService(),
       _narrativeBridgeService =
           narrativeBridgeService ??
           const BookDeconstructionNarrativeBridgeService();

  final BuildBookDeconstructionApplicationPlanUseCase
  _buildApplicationPlanUseCase;
  final BookDeconstructionFollowupMenuBuilderService
  _followupMenuBuilderService;
  final BookDeconstructionNarrativeBridgeService _narrativeBridgeService;

  BookDeconstructionDraftBuildResult build({
    required String sourceTitle,
    required String sourceContent,
    required String sourceAbsolutePath,
    required String operatorNotes,
    required String styleSummary,
    required String worldRulesText,
    required String characterLinesText,
    required String organizationLinesText,
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
  }) {
    // 中文注释: 这里先把 GUI 收集到的源文本和补充字段收束成 core 能识别的拆书输入与应用计划。
    final cleanContent = sourceContent.trim();
    if (cleanContent.isEmpty) {
      throw StateError('请先导入或粘贴拆书源文稿。');
    }
    final resolvedTitle = _resolvedSourceTitle(
      sourceTitle,
      sourceAbsolutePath,
      cleanContent,
    );
    final sourceDocument = BookDeconstructionSourceDocument(
      id: 'source_primary',
      title: resolvedTitle,
      content: cleanContent,
      mediaType: _mediaTypeOf(sourceAbsolutePath),
      relativePathHint: sourceAbsolutePath.trim(),
      sequence: 1,
    );
    final chapterOutlines = _chapterOutlinesOf(cleanContent);
    final storyOutlineSummary = _storyOutlineSummaryOf(
      cleanContent,
      chapterOutlines,
    );
    final premises = <InspirationPremise>[
      InspirationPremise(
        id: 'premise_main',
        displayName: '核心前提',
        summary: _premiseSummaryOf(cleanContent, storyOutlineSummary),
        sourcePath: sourceAbsolutePath.trim(),
      ),
    ];
    final extractionResult = BookDeconstructionExtractionResult(
      extractionId: 'extract_${DateTime.now().microsecondsSinceEpoch}',
      sourceTitle: resolvedTitle,
      premises: premises,
      storyOutlineSummary: storyOutlineSummary,
      chapterOutlines: chapterOutlines,
      styleProfiles: _styleProfilesOf(styleSummary),
      worldRuleSets: _worldRuleSetsOf(worldRulesText),
      characterProfiles: _characterProfilesOf(characterLinesText),
      organizationProfiles: _organizationProfilesOf(organizationLinesText),
      notes: operatorNotes.trim(),
    );
    final input = BookDeconstructionInput(
      extractionId: extractionResult.extractionId,
      title: resolvedTitle,
      sourceDocuments: <BookDeconstructionSourceDocument>[sourceDocument],
      preferredContinuationDirection: preferredContinuationDirection,
      operatorNotes: operatorNotes.trim(),
      metadata: <String, Object?>{
        if (sourceAbsolutePath.trim().isNotEmpty)
          'source_absolute_path': sourceAbsolutePath.trim(),
      },
    );
    final applicationPlan = _buildApplicationPlanUseCase.execute(
      input: input,
      extractionResult: extractionResult,
    );
    final followupMenu = _followupMenuBuilderService.build(
      preferredDirection: preferredContinuationDirection,
    );
    final narrativeArtifacts = _narrativeBridgeService.build(
      input: input,
      extractionResult: extractionResult,
    );
    return BookDeconstructionDraftBuildResult(
      input: input,
      extractionResult: extractionResult,
      applicationPlan: applicationPlan,
      followupMenu: followupMenu,
      narrativeArtifacts: narrativeArtifacts,
    );
  }

  String _resolvedSourceTitle(
    String sourceTitle,
    String sourceAbsolutePath,
    String sourceContent,
  ) {
    final cleanTitle = sourceTitle.trim();
    if (cleanTitle.isNotEmpty) {
      return cleanTitle;
    }
    final cleanPath = sourceAbsolutePath.trim().replaceAll('\\', '/');
    if (cleanPath.isNotEmpty) {
      final fileName = cleanPath.split('/').last;
      final separatorIndex = fileName.lastIndexOf('.');
      if (separatorIndex > 0) {
        return fileName.substring(0, separatorIndex);
      }
      return fileName;
    }
    final firstLine = sourceContent
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '未命名拆书源');
    return _truncate(firstLine, 36);
  }

  String _mediaTypeOf(String sourceAbsolutePath) {
    final lower = sourceAbsolutePath.trim().toLowerCase();
    if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
      return 'text/markdown';
    }
    return 'text/plain';
  }

  List<BookDeconstructionChapterOutline> _chapterOutlinesOf(String content) {
    final paragraphs = _paragraphsOf(content);
    final lines = content.split('\n');
    final headingMatches = <_HeadingMatch>[];
    final headingPattern = RegExp(
      r'^(?:#{1,6}\s*)?(第[^\n]{0,18}[章节回卷]|chapter\s*\d+|CHAPTER\s*\d+)\s*[:：\-]?\s*(.*)$',
      caseSensitive: false,
    );
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        continue;
      }
      final match = headingPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      final chapterLabel = match.group(1)?.trim() ?? '章节';
      final suffix = match.group(2)?.trim() ?? '';
      headingMatches.add(
        _HeadingMatch(
          lineIndex: index,
          title: suffix.isEmpty ? chapterLabel : '$chapterLabel $suffix',
        ),
      );
    }
    if (headingMatches.isEmpty) {
      return _fallbackChapterOutlines(paragraphs);
    }
    final outlines = <BookDeconstructionChapterOutline>[];
    for (var index = 0; index < headingMatches.length; index += 1) {
      final current = headingMatches[index];
      final nextLineIndex = index + 1 < headingMatches.length
          ? headingMatches[index + 1].lineIndex
          : lines.length;
      final buffer = <String>[];
      for (
        var lineIndex = current.lineIndex + 1;
        lineIndex < nextLineIndex;
        lineIndex += 1
      ) {
        final line = lines[lineIndex].trim();
        if (line.isNotEmpty) {
          buffer.add(line);
        }
      }
      outlines.add(
        BookDeconstructionChapterOutline(
          id: 'chapter_${index + 1}',
          title: current.title,
          sequence: index + 1,
          summary: _truncate(buffer.join(' '), 160),
        ),
      );
    }
    return outlines;
  }

  List<BookDeconstructionChapterOutline> _fallbackChapterOutlines(
    List<String> paragraphs,
  ) {
    if (paragraphs.isEmpty) {
      return const <BookDeconstructionChapterOutline>[];
    }
    final chunkCount = paragraphs.length >= 6 ? 3 : 2;
    final result = <BookDeconstructionChapterOutline>[];
    final chunkSize = (paragraphs.length / chunkCount).ceil();
    for (var index = 0; index < chunkCount; index += 1) {
      final start = index * chunkSize;
      if (start >= paragraphs.length) {
        break;
      }
      final end = (start + chunkSize) > paragraphs.length
          ? paragraphs.length
          : start + chunkSize;
      final summary = _truncate(paragraphs.sublist(start, end).join(' '), 160);
      result.add(
        BookDeconstructionChapterOutline(
          id: 'chapter_${index + 1}',
          title: '结构片段 ${index + 1}',
          sequence: index + 1,
          summary: summary,
        ),
      );
    }
    return result;
  }

  String _storyOutlineSummaryOf(
    String content,
    List<BookDeconstructionChapterOutline> chapterOutlines,
  ) {
    if (chapterOutlines.isNotEmpty) {
      final snippets = chapterOutlines
          .take(4)
          .map((item) => '${item.title}：${item.summary}')
          .where((item) => item.trim().isNotEmpty)
          .join('；');
      if (snippets.trim().isNotEmpty) {
        return _truncate(snippets, 320);
      }
    }
    final paragraphs = _paragraphsOf(content);
    return _truncate(paragraphs.take(4).join(' '), 320);
  }

  String _premiseSummaryOf(String content, String storyOutlineSummary) {
    final paragraphs = _paragraphsOf(content);
    final base = paragraphs.take(2).join(' ');
    if (base.trim().isNotEmpty) {
      return _truncate(base, 220);
    }
    return _truncate(storyOutlineSummary, 220);
  }

  List<StyleProfile> _styleProfilesOf(String styleSummary) {
    final cleanSummary = styleSummary.trim();
    if (cleanSummary.isEmpty) {
      return const <StyleProfile>[];
    }
    return <StyleProfile>[
      StyleProfile(
        id: 'deconstruction_style',
        displayName: '拆书风格提要',
        summary: cleanSummary,
      ),
    ];
  }

  List<WorldRuleSet> _worldRuleSetsOf(String worldRulesText) {
    final rules = _lineValues(worldRulesText);
    if (rules.isEmpty) {
      return const <WorldRuleSet>[];
    }
    return <WorldRuleSet>[
      WorldRuleSet(
        id: 'world_rules',
        displayName: '世界规则提要',
        summary: rules.first,
        rules: rules,
      ),
    ];
  }

  List<CharacterProfile> _characterProfilesOf(String characterLinesText) {
    return _lineValues(characterLinesText)
        .asMap()
        .entries
        .map((entry) {
          final parsed = _nameSummaryPair(entry.value);
          return CharacterProfile(
            id: _safeId(parsed.$1, fallback: 'character_${entry.key + 1}'),
            displayName: parsed.$1,
            summary: parsed.$2,
          );
        })
        .toList(growable: false);
  }

  List<OrganizationProfile> _organizationProfilesOf(
    String organizationLinesText,
  ) {
    return _lineValues(organizationLinesText)
        .asMap()
        .entries
        .map((entry) {
          final parsed = _nameSummaryPair(entry.value);
          return OrganizationProfile(
            id: _safeId(parsed.$1, fallback: 'organization_${entry.key + 1}'),
            displayName: parsed.$1,
            summary: parsed.$2,
          );
        })
        .toList(growable: false);
  }

  List<String> _paragraphsOf(String content) {
    return content
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.replaceAll('\n', ' ').trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _lineValues(String rawText) {
    return rawText
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  (String, String) _nameSummaryPair(String rawLine) {
    final match = RegExp(r'^([^:：\-]+)\s*[:：\-]\s*(.+)$').firstMatch(rawLine);
    if (match == null) {
      return (rawLine.trim(), '');
    }
    return ((match.group(1) ?? '').trim(), (match.group(2) ?? '').trim());
  }

  String _safeId(String value, {required String fallback}) {
    // 中文注释: 仅替换路径危险字符与空白，保留中文与其他常见可读字符，避免把显示名清空成下划线。
    final clean = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (clean.isEmpty) {
      return fallback;
    }
    return clean;
  }

  String _truncate(String value, int maxLength) {
    final clean = value.trim();
    if (clean.length <= maxLength) {
      return clean;
    }
    return '${clean.substring(0, maxLength)}...';
  }
}

class _HeadingMatch {
  const _HeadingMatch({required this.lineIndex, required this.title});

  final int lineIndex;
  final String title;
}
