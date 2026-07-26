import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_chapter_label_parser_service.dart';
import 'project_chaptered_writing_task_service.dart';
import 'project_relative_path_canonicalizer_service.dart';

class ProjectChapterContinuityPriorityService {
  const ProjectChapterContinuityPriorityService({
    ProjectChapteredWritingTaskService? chapteredWritingTaskService,
    ProjectChapterLabelParserService? parserService,
  }) : _chapteredWritingTaskService =
           chapteredWritingTaskService ??
           const ProjectChapteredWritingTaskService(),
       _parserService =
           parserService ?? const ProjectChapterLabelParserService(),
       _pathCanonicalizerService =
           const ProjectRelativePathCanonicalizerService();

  final ProjectChapteredWritingTaskService _chapteredWritingTaskService;
  final ProjectChapterLabelParserService _parserService;
  final ProjectRelativePathCanonicalizerService _pathCanonicalizerService;

  Map<String, int> buildPriorityWeights(
    List<JsonMap> entries, {
    required String taskType,
    required String chapterLabel,
  }) {
    if (!_chapteredWritingTaskService.canApplyContinuity(
      taskType: taskType,
      chapterLabel: chapterLabel,
    )) {
      return const <String, int>{};
    }
    final focus = _focusChapter(chapterLabel);
    if (focus == null) {
      return const <String, int>{};
    }
    final result = <String, int>{};
    for (final entry in entries) {
      if (ValueReaders.boolValue(entry['is_dir'])) {
        continue;
      }
      final rawPath = ValueReaders.stringValue(
        entry['relative_path'],
      ).trim().replaceAll('\\', '/');
      if (rawPath.isEmpty) {
        continue;
      }
      final canonicalPath = _pathCanonicalizerService.canonicalize(rawPath);
      if (canonicalPath.isEmpty) {
        continue;
      }
      final weight = _weightForPath(canonicalPath, focus);
      if (weight > 0) {
        result[rawPath] = weight;
      }
    }
    return result;
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
    if (chapterNumber > 3) {
      recent.add(chapterNumber - 3);
    }
    return _ChapterFocus(
      previousChapterNumber: chapterNumber - 1,
      recentChapterNumbers: recent,
    );
  }

  int _weightForPath(String path, _ChapterFocus focus) {
    final normalized = path.toLowerCase();
    if (_matchesContinuityBundlePath(normalized)) {
      return 1790;
    }
    if (_matchesContinuityScopePath(normalized)) {
      return 1780;
    }
    if (_matchesContinuityFramePath(normalized)) {
      return 1770;
    }
    final pathChapterNumber = _parserService.extractChapterNumber(path);
    if (pathChapterNumber == null) {
      return 0;
    }
    for (var index = 0; index < focus.recentChapterNumbers.length; index += 1) {
      final chapterNumber = focus.recentChapterNumbers[index];
      final distance = index + 1;
      final summaryWeight = 1700 - (distance * 120);
      final timelineWeight = 1660 - (distance * 120);
      final deliveryWeight = 1620 - (distance * 120);
      if (_matchesSummaryPath(path, chapterNumber, pathChapterNumber)) {
        return summaryWeight;
      }
      if (_matchesTimelinePath(path, chapterNumber, pathChapterNumber)) {
        return timelineWeight;
      }
      if (_matchesDeliveryPath(path, chapterNumber, pathChapterNumber)) {
        return deliveryWeight;
      }
    }
    if (normalized.startsWith('chapters/') &&
        normalized.endsWith('.md') &&
        pathChapterNumber == focus.previousChapterNumber) {
      return 1090;
    }
    return 0;
  }

  bool _matchesContinuityBundlePath(String normalizedPath) {
    // 中文注释: 章级连续写作必须先看见当前项目的连续性总包，避免只带着零散章节文件就开始续写。
    return normalizedPath == 'tracking/continuity/bundle.json';
  }

  bool _matchesContinuityScopePath(String normalizedPath) {
    // 中文注释: scope 文件承载当前连续性作用域与默认全局边界，必须在章级激活里稳定前置。
    return normalizedPath.startsWith('tracking/continuity/scopes/') &&
        normalizedPath.endsWith('.json');
  }

  bool _matchesContinuityFramePath(String normalizedPath) {
    // 中文注释: frame 文件承载主线连续性框架，优先级要高于普通章节清单，才能让承接锚点更稳定。
    return normalizedPath.startsWith('tracking/continuity/frames/') &&
        normalizedPath.endsWith('.json');
  }

  bool _matchesSummaryPath(
    String path,
    int chapterNumber,
    int pathChapterNumber,
  ) {
    final normalized = path.toLowerCase();
    return pathChapterNumber == chapterNumber &&
        normalized.startsWith('summaries/') &&
        normalized.endsWith('.summary.md');
  }

  bool _matchesTimelinePath(
    String path,
    int chapterNumber,
    int pathChapterNumber,
  ) {
    final normalized = path.toLowerCase();
    return pathChapterNumber == chapterNumber &&
        normalized.startsWith('assets/timeline/') &&
        normalized.endsWith('.timeline.md');
  }

  bool _matchesDeliveryPath(
    String path,
    int chapterNumber,
    int pathChapterNumber,
  ) {
    final normalized = path.toLowerCase();
    return pathChapterNumber == chapterNumber &&
        normalized.startsWith('.novel_agent/continuity/deliveries/') &&
        normalized.endsWith('.json');
  }
}

class _ChapterFocus {
  const _ChapterFocus({
    required this.previousChapterNumber,
    required this.recentChapterNumbers,
  });

  final int previousChapterNumber;
  final List<int> recentChapterNumbers;
}
