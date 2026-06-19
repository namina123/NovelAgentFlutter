import 'package:novel_agent_core/novel_agent_core.dart';

class ConversationToolPayloadCompactionService {
  const ConversationToolPayloadCompactionService({
    this.maxReadPreviewChars = 2200,
    this.maxSelectedLines = 24,
    this.maxSearchMatches = 20,
    this.maxDirectoryEntries = 80,
    this.maxGenericStringChars = 1200,
  });

  final int maxReadPreviewChars;
  final int maxSelectedLines;
  final int maxSearchMatches;
  final int maxDirectoryEntries;
  final int maxGenericStringChars;

  DraftGenerationProgress compactProgress(DraftGenerationProgress source) {
    return DraftGenerationProgress(
      phase: source.phase,
      roundIndex: source.roundIndex,
      draftMarkdown: source.draftMarkdown,
      reasoningContent: source.reasoningContent,
      pendingToolCalls: source.pendingToolCalls
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
      executedTools: _compactExecutedTools(source.executedTools),
      cancelledByUser: source.cancelledByUser,
      stopPhase: source.stopPhase,
      partialContentAccepted: source.partialContentAccepted,
    );
  }

  DraftGenerationResult compactResult(DraftGenerationResult source) {
    return DraftGenerationResult(
      project: source.project,
      projectInfo: source.projectInfo,
      userPrompt: source.userPrompt,
      prompt: source.prompt,
      modelId: source.modelId,
      draftMarkdown: source.draftMarkdown,
      contextPack: source.contextPack,
      selectedPaths: source.selectedPaths,
      executedTools: _compactExecutedTools(source.executedTools),
      writtenPaths: source.writtenPaths,
      changedPaths: source.changedPaths,
      transcriptMessages: source.transcriptMessages,
      waitingForUserChoice: source.waitingForUserChoice,
      reasoningContent: source.reasoningContent,
      stoppedByToolError: source.stoppedByToolError,
      toolErrorSummary: source.toolErrorSummary,
      cancelledByUser: source.cancelledByUser,
      stopPhase: source.stopPhase,
      partialContentAccepted: source.partialContentAccepted,
    );
  }

  List<Object?> _compactExecutedTools(List<Object?> executedTools) {
    return executedTools
        .map(ValueReaders.mapValue)
        .map(_compactTool)
        .toList(growable: false);
  }

  JsonMap _compactTool(JsonMap tool) {
    final result = ValueReaders.mapValue(tool['result']);
    if (result.isEmpty) {
      return ValueReaders.deepCopyMap(tool);
    }
    final toolName = ValueReaders.stringValue(tool['name']).trim();
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(tool),
      'arguments': _compactGenericMap(ValueReaders.mapValue(tool['arguments'])),
      'result': switch (toolName) {
        'read_project_file' => _compactReadProjectFileResult(result),
        'get_project_file_info' => _compactProjectFileInfoResult(result),
        'search_project_files' => _compactSearchResult(result),
        'list_project_files' => _compactListResult(result),
        _ => _compactGenericMap(result),
      },
    };
  }

  JsonMap _compactReadProjectFileResult(JsonMap result) {
    final next = _compactGenericMap(result);
    final content = ValueReaders.stringValue(result['content']);
    if (content.isNotEmpty) {
      next['content'] = _truncateText(
        content,
        maxReadPreviewChars,
        suffix: '\n\n[已截断，仅保留预览用于界面展示]',
      );
      next['content_preview_chars'] = _truncateLength(
        content,
        maxReadPreviewChars,
      );
      next['content_full_chars'] = content.length;
    }
    final selectedLines = ValueReaders.objectList(result['selected_lines']);
    if (selectedLines.length > maxSelectedLines) {
      next['selected_lines'] = selectedLines
          .take(maxSelectedLines)
          .map(ValueReaders.mapValue)
          .map(_compactGenericMap)
          .toList(growable: false);
      next['selected_lines_truncated'] = true;
      next['selected_line_count'] = selectedLines.length;
    }
    return next;
  }

  JsonMap _compactProjectFileInfoResult(JsonMap result) {
    final next = _compactGenericMap(result);
    final selectedLines = ValueReaders.objectList(result['selected_lines']);
    if (selectedLines.length > maxSelectedLines) {
      next['selected_lines'] = selectedLines
          .take(maxSelectedLines)
          .map(ValueReaders.mapValue)
          .map(_compactGenericMap)
          .toList(growable: false);
      next['selected_lines_truncated'] = true;
      next['selected_line_count'] = selectedLines.length;
    }
    return next;
  }

  JsonMap _compactSearchResult(JsonMap result) {
    final next = _compactGenericMap(result);
    final matches = ValueReaders.objectList(result['matches']);
    if (matches.length > maxSearchMatches) {
      next['matches'] = matches
          .take(maxSearchMatches)
          .map(ValueReaders.mapValue)
          .map(_compactGenericMap)
          .toList(growable: false);
      next['matches_truncated'] = true;
      next['match_count'] = matches.length;
    }
    return next;
  }

  JsonMap _compactListResult(JsonMap result) {
    final next = _compactGenericMap(result);
    final entries = ValueReaders.objectList(result['entries']);
    if (entries.length > maxDirectoryEntries) {
      next['entries'] = entries
          .take(maxDirectoryEntries)
          .map(ValueReaders.mapValue)
          .map(_compactGenericMap)
          .toList(growable: false);
      next['entries_truncated'] = true;
      next['entry_count'] = entries.length;
    }
    return next;
  }

  JsonMap _compactGenericMap(JsonMap source) {
    final next = <String, Object?>{};
    source.forEach((key, value) {
      next[key] = _compactValue(value);
    });
    return next;
  }

  Object? _compactValue(Object? value) {
    if (value is Map<String, Object?>) {
      return _compactGenericMap(value);
    }
    if (value is Map) {
      return _compactGenericMap(ValueReaders.mapValue(value));
    }
    if (value is List) {
      return value.map(_compactValue).toList(growable: false);
    }
    if (value is String) {
      return _truncateText(value, maxGenericStringChars);
    }
    return value;
  }

  String _truncateText(String value, int maxChars, {String suffix = '…'}) {
    if (value.length <= maxChars) {
      return value;
    }
    final safeMax = maxChars <= suffix.length
        ? maxChars
        : maxChars - suffix.length;
    return '${value.substring(0, safeMax)}$suffix';
  }

  int _truncateLength(String value, int maxChars) {
    return value.length <= maxChars ? value.length : maxChars;
  }
}
