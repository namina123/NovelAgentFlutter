import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_chapter_label_parser_service.dart';
import 'project_chaptered_writing_task_service.dart';
import 'project_relative_path_canonicalizer_service.dart';

class ProjectChapterContinuityHandoffItemService {
  const ProjectChapterContinuityHandoffItemService({
    this.continuationPointChars = 900,
    ProjectChapteredWritingTaskService? chapteredWritingTaskService,
    ProjectChapterLabelParserService? parserService,
  }) : _chapteredWritingTaskService =
           chapteredWritingTaskService ??
           const ProjectChapteredWritingTaskService(),
       _parserService =
           parserService ?? const ProjectChapterLabelParserService(),
       _pathCanonicalizerService =
           const ProjectRelativePathCanonicalizerService();

  final int continuationPointChars;
  final ProjectChapteredWritingTaskService _chapteredWritingTaskService;
  final ProjectChapterLabelParserService _parserService;
  final ProjectRelativePathCanonicalizerService _pathCanonicalizerService;

  Future<List<ContextActivationItem>> buildItems({
    required ProjectWorkspacePort workspacePort,
    required ProjectDescriptor project,
    required List<JsonMap> visibleEntries,
    required String taskType,
    required String chapterLabel,
  }) async {
    if (!_chapteredWritingTaskService.canApplyContinuity(
      taskType: taskType,
      chapterLabel: chapterLabel,
    )) {
      return const <ContextActivationItem>[];
    }
    final focus = _focusChapter(chapterLabel);
    if (focus == null) {
      return const <ContextActivationItem>[];
    }
    final result = <ContextActivationItem>[];
    for (var index = 0; index < focus.recentChapterNumbers.length; index += 1) {
      final distance = index + 1;
      final chapterNumber = focus.recentChapterNumbers[index];
      final chapterPaths = _matchingChapterPaths(visibleEntries, chapterNumber);
      final resolvedChapterPaths = chapterPaths.isEmpty
          ? <String>[
              'chapters/${_parserService.canonicalLabelForNumber(chapterNumber, width: focus.width)}.md',
            ]
          : chapterPaths;
      for (final chapterPath in resolvedChapterPaths) {
        final deliveryItem = await _buildDeliveryItem(
          workspacePort: workspacePort,
          project: project,
          chapterPath: chapterPath,
          weight: 1680 - (distance * 120),
        );
        if (deliveryItem != null) {
          result.add(deliveryItem);
        }
        final continuationPointItem = await _buildContinuationPointItem(
          workspacePort: workspacePort,
          project: project,
          chapterPath: chapterPath,
          weight: 1640 - (distance * 120),
        );
        if (continuationPointItem != null) {
          result.add(continuationPointItem);
        }
      }
    }
    return result;
  }

  Future<ContextActivationItem?> _buildDeliveryItem({
    required ProjectWorkspacePort workspacePort,
    required ProjectDescriptor project,
    required String chapterPath,
    required int weight,
  }) async {
    final chapterFileName = chapterPath.split('/').last;
    final path =
        '.novel_agent/continuity/deliveries/submission_chapters_${chapterFileName}.json';
    final raw = await workspacePort.readTextFile(project.rootPath, path);
    final clean = raw?.trim() ?? '';
    if (clean.isEmpty) {
      return null;
    }
    final json = _tryParseJson(clean);
    if (json.isEmpty) {
      return null;
    }
    final submission = ValueReaders.mapValue(json['submission']);
    final summary = ValueReaders.stringValue(submission['summary']).trim();
    final finalState = ValueReaders.mapValue(submission['final_state_summary']);
    final effectiveSummary = _effectiveSummary(
      summary: summary,
      finalState: finalState,
    );
    final claims = ValueReaders.mapList(submission['claims']);
    if (effectiveSummary.isEmpty && finalState.isEmpty && claims.isEmpty) {
      return null;
    }
    final location = ValueReaders.stringValue(finalState['location']).trim();
    final activeGoal = ValueReaders.stringValue(
      finalState['active_goal'],
    ).trim();
    final unresolvedHook = ValueReaders.stringValue(
      finalState['unresolved_hook'],
    ).trim();
    final nextChapterHandoff = ValueReaders.stringValue(
      finalState['next_chapter_handoff'],
    ).trim();
    final lines = <String>[
      '# File: $path',
      '',
      '# Chapter Delivery Handoff: $chapterFileName',
    ];
    if (summary.isNotEmpty || nextChapterHandoff.isNotEmpty) {
      lines
        ..add('')
        ..add('continuity_guard:')
        ..add(
          effectiveSummary.isEmpty
              ? '- 上一章已完成剧情：见下方交付摘要。'
              : '- 上一章已完成剧情（不要重复重演）：$effectiveSummary',
        );
      if (nextChapterHandoff.isNotEmpty) {
        lines.add('- 下一章承接锚点（必须直接续上）：$nextChapterHandoff');
      }
      if (location.isNotEmpty) {
        lines.add('- 当前落点：$location');
      }
      if (activeGoal.isNotEmpty) {
        lines.add('- 即时目标/动作：$activeGoal');
      }
      if (unresolvedHook.isNotEmpty) {
        lines.add('- 未完成悬念：$unresolvedHook');
      }
    }
    if (effectiveSummary.isNotEmpty) {
      lines
        ..add('')
        ..add('summary:')
        ..add(effectiveSummary);
    }
    if (finalState.isNotEmpty) {
      lines
        ..add('')
        ..add('final_state_summary:')
        ..add(const JsonEncoder.withIndent('  ').convert(finalState));
    }
    if (claims.isNotEmpty) {
      lines
        ..add('')
        ..add('claims:')
        ..add(
          const JsonEncoder.withIndent(
            '  ',
          ).convert(claims.take(4).toList(growable: false)),
        );
    }
    final activationText = lines.join('\n').trim();
    return _item(
      itemId: 'file:$path',
      title: '${chapterFileName}交付摘要',
      targetPath: path,
      activationText: activationText,
      weight: weight,
      handoffKind: 'chapter_delivery',
    );
  }

  Future<ContextActivationItem?> _buildContinuationPointItem({
    required ProjectWorkspacePort workspacePort,
    required ProjectDescriptor project,
    required String chapterPath,
    required int weight,
  }) async {
    final deliveryJson = await _loadDeliverySubmission(
      workspacePort: workspacePort,
      project: project,
      chapterPath: chapterPath,
    );
    final nextChapterHandoff = ValueReaders.stringValue(
      ValueReaders.mapValue(
        ValueReaders.mapValue(
          deliveryJson['submission'],
        )['final_state_summary'],
      )['next_chapter_handoff'],
    ).trim();
    final raw = await workspacePort.readTextFile(project.rootPath, chapterPath);
    final clean = raw?.trim() ?? '';
    if (clean.isEmpty) {
      return null;
    }
    final excerpt = _continuationPointExcerpt(clean);
    if (excerpt.isEmpty) {
      return null;
    }
    final activationText = [
      '# File: $chapterPath',
      '',
      '# Continuation Point: ${chapterPath.split('/').last}',
      '',
      if (nextChapterHandoff.isNotEmpty) ...<String>[
        '优先承接锚点：$nextChapterHandoff',
        '',
      ],
      '章末原文锚点：${_inlineExcerpt(excerpt)}',
      '',
      '以下摘录上一章章末锚点；下一章应直接承接这里已经落定的状态，不要回退重演章首铺垫。',
      '',
      excerpt,
    ].join('\n');
    return _item(
      itemId: 'chapter_tail:$chapterPath',
      title: '${chapterPath.split('/').last}章末锚点',
      targetPath: chapterPath,
      activationText: activationText,
      weight: weight,
      handoffKind: 'continuation_point',
    );
  }

  ContextActivationItem _item({
    required String itemId,
    required String title,
    required String targetPath,
    required String activationText,
    required int weight,
    required String handoffKind,
  }) {
    return ContextActivationItem(
      itemId: itemId,
      source: 'project_file',
      title: title,
      targetPath: targetPath,
      refs: <NarrativeRef>[
        NarrativeRef(
          refType: NarrativeRefTypes.asset,
          refId: targetPath,
          displayName: title,
          relativePath: targetPath,
          sourcePath: targetPath,
        ),
      ],
      activationReasons: const <String>[
        ContextActivationReasonCodes.manualPin,
        ContextActivationReasonCodes.taskType,
      ],
      reasonDetails: <String, Object?>{
        'task_type': 'chapter',
        'relative_path': targetPath,
        'pinned': true,
        'weight': weight,
        'handoff_kind': handoffKind,
      },
      requestedChars: activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'project_file',
        'relative_path': targetPath,
        'task_type': 'chapter',
        'pinned': true,
        'weight': weight,
        'handoff_kind': handoffKind,
        'activation_text': activationText,
      },
    );
  }

  JsonMap _tryParseJson(String raw) {
    try {
      return ValueReaders.mapValue(jsonDecode(raw));
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  Future<JsonMap> _loadDeliverySubmission({
    required ProjectWorkspacePort workspacePort,
    required ProjectDescriptor project,
    required String chapterPath,
  }) async {
    final chapterFileName = chapterPath.split('/').last;
    final path =
        '.novel_agent/continuity/deliveries/submission_chapters_${chapterFileName}.json';
    final raw = await workspacePort.readTextFile(project.rootPath, path);
    final clean = raw?.trim() ?? '';
    if (clean.isEmpty) {
      return const <String, Object?>{};
    }
    return _tryParseJson(clean);
  }

  String _continuationPointExcerpt(String chapterMarkdown) {
    final normalized = chapterMarkdown.trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.length <= continuationPointChars) {
      return normalized;
    }
    final start = normalized.length - continuationPointChars;
    final newline = normalized.indexOf('\n', start);
    if (newline >= start && newline < normalized.length - 80) {
      return normalized.substring(newline + 1).trim();
    }
    return normalized.substring(start).trim();
  }

  String _effectiveSummary({
    required String summary,
    required JsonMap finalState,
  }) {
    final cleanSummary = summary.trim();
    if (cleanSummary.isNotEmpty &&
        !_looksLikePlaceholderSummary(cleanSummary)) {
      return cleanSummary;
    }
    final chapterEndExcerpt = ValueReaders.stringValue(
      finalState['chapter_end_excerpt'],
    ).trim();
    final nextChapterHandoff = ValueReaders.stringValue(
      finalState['next_chapter_handoff'],
    ).trim();
    final location = ValueReaders.stringValue(finalState['location']).trim();
    final activeGoal = ValueReaders.stringValue(
      finalState['active_goal'],
    ).trim();
    final unresolvedHook = ValueReaders.stringValue(
      finalState['unresolved_hook'],
    ).trim();
    final inlineExcerpt = _inlineExcerpt(chapterEndExcerpt);
    if (inlineExcerpt.isNotEmpty) {
      return '章末落点：$inlineExcerpt';
    }
    if (nextChapterHandoff.isNotEmpty) {
      return '下一章入口：$nextChapterHandoff';
    }
    final fragments = <String>[
      if (location.isNotEmpty) '位置：$location',
      if (activeGoal.isNotEmpty) '动作/目标：$activeGoal',
      if (unresolvedHook.isNotEmpty) '悬念：$unresolvedHook',
    ];
    if (fragments.isEmpty) {
      return '';
    }
    return fragments.join('；');
  }

  bool _looksLikePlaceholderSummary(String summary) {
    final normalized = summary.trim().toLowerCase();
    return normalized == 'ordinary conversation chapter delivery' ||
        normalized == 'chapter delivery' ||
        normalized == 'chapter saved' ||
        normalized == '章节交付' ||
        normalized == '章节已交付' ||
        normalized == '章节已保存';
  }

  String _inlineExcerpt(String excerpt, {int maxChars = 180}) {
    final normalized = excerpt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return normalized.substring(0, maxChars).trimRight();
  }

  _ChapterFocus? _focusChapter(String chapterLabel) {
    final parsed = _parserService.parse(chapterLabel);
    if (parsed == null) {
      return null;
    }
    final chapterNumber = parsed.chapterNumber;
    if (chapterNumber <= 1) {
      return null;
    }
    final recent = <int>[chapterNumber - 1];
    if (chapterNumber > 2) {
      recent.add(chapterNumber - 2);
    }
    return _ChapterFocus(recentChapterNumbers: recent, width: parsed.width);
  }

  List<String> _matchingChapterPaths(
    List<JsonMap> visibleEntries,
    int chapterNumber,
  ) {
    final matches =
        visibleEntries
            .where((entry) => !ValueReaders.boolValue(entry['is_dir']))
            .map(
              (entry) =>
                  ValueReaders.stringValue(entry['relative_path']).trim(),
            )
            .where((path) {
              final normalized = _pathCanonicalizerService
                  .canonicalize(path)
                  .toLowerCase();
              return normalized.startsWith('chapters/') &&
                  normalized.endsWith('.md') &&
                  _parserService.extractChapterNumber(path) == chapterNumber;
            })
            .toList(growable: false)
          ..sort();
    return matches;
  }
}

class _ChapterFocus {
  const _ChapterFocus({
    required this.recentChapterNumbers,
    required this.width,
  });

  final List<int> recentChapterNumbers;
  final int width;
}
