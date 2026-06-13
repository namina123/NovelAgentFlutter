import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectChapterOpeningContinuityGuardService {
  const ProjectChapterOpeningContinuityGuardService({
    required ProjectWorkspacePort workspacePort,
    ChapterOpeningContinuityGuardService? continuityGuardService,
  }) : _workspacePort = workspacePort,
       _continuityGuardService =
           continuityGuardService ??
           const ChapterOpeningContinuityGuardService();

  final ProjectWorkspacePort _workspacePort;
  final ChapterOpeningContinuityGuardService _continuityGuardService;

  Future<ChapterOpeningContinuityGuardResult> evaluate({
    required ProjectDescriptor project,
    required String chapterPath,
    required String chapterContent,
  }) async {
    final previousChapterPath = await _previousChapterPath(
      project,
      chapterPath,
    );
    if (previousChapterPath.isEmpty) {
      return const ChapterOpeningContinuityGuardResult(blocked: false);
    }
    final previousChapterContent =
        await _workspacePort.readTextFile(
          project.rootPath,
          previousChapterPath,
        ) ??
        '';
    final previousDelivery = await _previousDelivery(
      project: project,
      previousChapterPath: previousChapterPath,
    );
    final finalState = ValueReaders.mapValue(
      ValueReaders.mapValue(
        previousDelivery['submission'],
      )['final_state_summary'],
    );
    return _continuityGuardService.evaluate(
      currentChapterContent: chapterContent,
      previousChapterContent: previousChapterContent,
      previousChapterEndExcerpt: ValueReaders.stringValue(
        finalState['chapter_end_excerpt'],
      ),
      nextChapterHandoff: ValueReaders.stringValue(
        finalState['next_chapter_handoff'],
      ),
    );
  }

  Future<String> _previousChapterPath(
    ProjectDescriptor project,
    String chapterPath,
  ) async {
    final clean = chapterPath.trim().replaceAll('\\', '/');
    if (clean.isEmpty) {
      return '';
    }
    final leaf = clean.split('/').last;
    final directory = clean.contains('/')
        ? clean.substring(0, clean.lastIndexOf('/'))
        : '';
    final targetLabel = _previousChapterLabel(leaf);
    if (targetLabel.isEmpty) {
      return '';
    }
    final entries = await _workspacePort.listEntries(project.rootPath);
    final candidates = entries
        .map(ValueReaders.mapValue)
        .where(
          (entry) =>
              !ValueReaders.boolValue(entry['is_dir']) &&
              ValueReaders.stringValue(entry['relative_path'])
                  .replaceAll('\\', '/')
                  .startsWith(directory.isEmpty ? '' : '$directory/'),
        )
        .map(
          (entry) => ValueReaders.stringValue(
            entry['relative_path'],
          ).replaceAll('\\', '/'),
        )
        .where((path) => path.split('/').last.startsWith(targetLabel))
        .toList(growable: false);
    if (candidates.isEmpty) {
      return '';
    }
    candidates.sort();
    return candidates.first;
  }

  String _previousChapterLabel(String leaf) {
    final cjk = RegExp(r'^(第)(\d+)(章)');
    final cjkMatch = cjk.firstMatch(leaf);
    if (cjkMatch != null) {
      final rawNumber = cjkMatch.group(2) ?? '';
      final current = int.tryParse(rawNumber) ?? 0;
      if (current <= 1) {
        return '';
      }
      final previous = (current - 1).toString().padLeft(rawNumber.length, '0');
      return '${cjkMatch.group(1)}$previous${cjkMatch.group(3)}';
    }
    final latin = RegExp(r'^(chapter[_-]?)(\d+)', caseSensitive: false);
    final latinMatch = latin.firstMatch(leaf);
    if (latinMatch != null) {
      final rawNumber = latinMatch.group(2) ?? '';
      final current = int.tryParse(rawNumber) ?? 0;
      if (current <= 1) {
        return '';
      }
      final previous = (current - 1).toString().padLeft(rawNumber.length, '0');
      return '${latinMatch.group(1)}$previous';
    }
    return '';
  }

  Future<JsonMap> _previousDelivery({
    required ProjectDescriptor project,
    required String previousChapterPath,
  }) async {
    final fileName = previousChapterPath.split('/').last.trim();
    if (fileName.isEmpty) {
      return const <String, Object?>{};
    }
    final path =
        '.novel_agent/continuity/deliveries/submission_chapters_$fileName.json';
    final raw = await _workspacePort.readTextFile(project.rootPath, path);
    final clean = raw?.trim() ?? '';
    if (clean.isEmpty) {
      return const <String, Object?>{};
    }
    try {
      return ValueReaders.mapValue(jsonDecode(clean));
    } catch (_) {
      return const <String, Object?>{};
    }
  }
}
