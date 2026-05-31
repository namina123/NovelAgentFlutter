import 'package:novel_agent_core/novel_agent_core.dart';

class ConversationDraftAutosavePolicyService {
  const ConversationDraftAutosavePolicyService();

  bool shouldAutoSave({
    required DraftGenerationResult result,
    required String activeDocumentPath,
    required bool wasModeGuidanceActive,
  }) {
    // 中文注释: 自动落盘只给真正“已经像正式产物”的结果，避免引导问答和解释性回复误写进正文目录。
    final content = result.draftMarkdown.trim();
    if (wasModeGuidanceActive ||
        result.waitingForUserChoice ||
        result.stoppedByToolError ||
        content.isEmpty) {
      return false;
    }
    if (result.writtenPaths.isNotEmpty || result.changedPaths.isNotEmpty) {
      return false;
    }
    if (_containsChoiceTool(result.executedTools) ||
        _looksLikeGuidance(content)) {
      return false;
    }
    if (_isContentDocumentPath(activeDocumentPath)) {
      return true;
    }
    return _looksLikeNarrativeDraft(content);
  }

  bool _containsChoiceTool(List<Object?> executedTools) {
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name == 'present_user_options') {
        return true;
      }
    }
    return false;
  }

  bool _isContentDocumentPath(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/').trim().toLowerCase();
    return normalized.startsWith('chapters/') ||
        normalized.startsWith('scenes/');
  }

  bool _looksLikeGuidance(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return true;
    }
    const guidanceMarkers = <String>[
      '还没确认',
      '需要你回答',
      '请选择',
      '你倾向',
      '你希望',
      '你更想',
      '以下几个',
      '我先总结',
      '我来总结',
      '先选一个',
      '请告诉我',
      '如果你愿意',
    ];
    for (final marker in guidanceMarkers) {
      if (normalized.contains(marker)) {
        return true;
      }
    }
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final bulletCount = lines.where(_isBulletLine).length;
    final questionLineCount = lines
        .where((line) => line.endsWith('？') || line.endsWith('?'))
        .length;
    final optionLineCount = lines.where(_isOptionLine).length;
    final questionMarkCount =
        '?'.allMatches(normalized).length + '？'.allMatches(normalized).length;
    if (optionLineCount >= 2) {
      return true;
    }
    if (bulletCount >= 3 && questionLineCount >= 1) {
      return true;
    }
    if (questionMarkCount >= 2 && normalized.length < 2200) {
      return true;
    }
    return false;
  }

  bool _looksLikeNarrativeDraft(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trim();
    if (normalized.length < 420) {
      return false;
    }
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.length < 4) {
      return false;
    }
    final bulletCount = lines.where(_isBulletLine).length;
    final proseLines = lines
        .where((line) => !_isBulletLine(line))
        .toList(growable: false);
    if (proseLines.length < 3) {
      return false;
    }
    final proseLength = proseLines.fold<int>(
      0,
      (sum, line) => sum + line.runes.length,
    );
    final averageProseLength = proseLength / proseLines.length;
    final bulletRatio = bulletCount / lines.length;
    return averageProseLength >= 22 && bulletRatio < 0.35;
  }

  bool _isBulletLine(String line) {
    return RegExp(r'^(\*|-|•|\d+\.|[A-Z]\.|[A-Z]：|\*\*[A-Z]\.)').hasMatch(line);
  }

  bool _isOptionLine(String line) {
    return RegExp(r'^(\*\*)?[A-Z][\.\：]').hasMatch(line);
  }
}
