import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/sub_agent_run_view_data.dart';

class SubAgentRunProjectionService {
  const SubAgentRunProjectionService();

  SubAgentRunViewData? projectFromToolResult(JsonMap result) {
    final runId = ValueReaders.stringValue(
      result['sub_agent_run_id'],
      ValueReaders.stringValue(result['sub_session_id']),
    ).trim();
    if (runId.isEmpty) {
      return null;
    }
    final collaborationPackage = CollaborationResultPackage.fromJson(
      ValueReaders.mapValue(result['collaboration_result_package']),
    );
    final expertOpinion = _expertOpinion(result, collaborationPackage);
    final evidenceItems = _evidenceItems(collaborationPackage);
    final adoptionSummary = _adoptionSummary(collaborationPackage);
    final degradationSummary = _degradationSummary(
      result,
      collaborationPackage,
    );
    return SubAgentRunViewData(
      id: runId,
      agentName: ValueReaders.stringValue(result['agent_name'], '子智能体'),
      task: ValueReaders.stringValue(result['task']),
      status: _statusLabel(result, collaborationPackage),
      summary: _summary(result, collaborationPackage, degradationSummary),
      content: ValueReaders.stringValue(result['result_markdown']),
      reasoning: ValueReaders.stringValue(result['reasoning_content']),
      toolCount: ValueReaders.intValue(result['tool_count']),
      events: _eventSummaries(result),
      expertOpinion: expertOpinion,
      evidenceItems: evidenceItems,
      adoptionSummary: adoptionSummary,
      degradationSummary: degradationSummary,
      diagnosticItems: _diagnosticItems(result, collaborationPackage),
    );
  }

  String _statusLabel(JsonMap result, CollaborationResultPackage package) {
    final failureDisposition = ValueReaders.stringValue(
      result['failure_disposition'],
      ValueReaders.stringValue(package.metadata['failure_disposition']),
    ).trim();
    if (failureDisposition == ChildFailureDispositions.fallbackSingleMain) {
      return '已降级返回';
    }
    if (!ValueReaders.boolValue(result['ok'], true)) {
      return '需降级处理';
    }
    if (package.arbitrationResult.requiresUserConfirmation) {
      return '等待主链确认';
    }
    if (package.arbitrationResult.requiresRepair) {
      return '需主链修订';
    }
    return '完成';
  }

  String _summary(
    JsonMap result,
    CollaborationResultPackage package,
    String degradationSummary,
  ) {
    final summary = ValueReaders.stringValue(
      result['summary'],
      package.resultSummary,
    ).trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    if (degradationSummary.isNotEmpty) {
      return degradationSummary;
    }
    final expertOpinion = _expertOpinion(result, package);
    if (expertOpinion.isNotEmpty) {
      return expertOpinion;
    }
    return '子智能体已返回处理结果。';
  }

  String _expertOpinion(JsonMap result, CollaborationResultPackage package) {
    if (package.conflicts.isNotEmpty) {
      return package.conflicts
          .map((entry) => entry.suggestion.trim())
          .where((entry) => entry.isNotEmpty)
          .join('\n');
    }
    return ValueReaders.stringValue(
      result['result_markdown'],
      package.resultMarkdown,
    ).trim();
  }

  List<String> _evidenceItems(CollaborationResultPackage package) {
    final items = <String>[];
    for (final conflict in package.conflicts) {
      for (final evidence in conflict.evidence) {
        final summary = evidence.summary.trim();
        final reference = evidence.reference.trim();
        if (summary.isNotEmpty && reference.isNotEmpty) {
          items.add('$summary（$reference）');
          continue;
        }
        if (summary.isNotEmpty) {
          items.add(summary);
          continue;
        }
        if (reference.isNotEmpty) {
          items.add(reference);
        }
      }
    }
    return items;
  }

  String _adoptionSummary(CollaborationResultPackage package) {
    final arbitration = package.arbitrationResult;
    if (arbitration.summary.trim().isNotEmpty) {
      return arbitration.summary.trim();
    }
    if (package.conflicts.isEmpty) {
      return '';
    }
    final hints = package.conflicts
        .map((entry) => entry.adoptionHint.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (hints.isEmpty) {
      return '';
    }
    return '建议采纳方式：${hints.join('；')}';
  }

  String _degradationSummary(
    JsonMap result,
    CollaborationResultPackage package,
  ) {
    final failureDisposition = ValueReaders.stringValue(
      result['failure_disposition'],
      ValueReaders.stringValue(package.metadata['failure_disposition']),
    ).trim();
    if (failureDisposition == ChildFailureDispositions.fallbackSingleMain) {
      return '该子智能体未能独立完成，本轮已退回单主链继续。';
    }
    if (package.arbitrationResult.requiresRepair) {
      return '该子智能体结果仍需主链修订后再合并。';
    }
    if (package.arbitrationResult.requiresUserConfirmation) {
      return '该子智能体结果需要主链或用户确认后再采纳。';
    }
    return '';
  }

  List<String> _eventSummaries(JsonMap result) {
    return ValueReaders.objectList(result['sub_agent_events'])
        .map(ValueReaders.mapValue)
        .map((event) => ValueReaders.stringValue(event['summary']))
        .where((summary) => summary.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<String> _diagnosticItems(
    JsonMap result,
    CollaborationResultPackage package,
  ) {
    // 中文注释: 诊断项面向用户（在"运行诊断"折叠区），用中文标签而不是 snake_case 字段名。
    final diagnostics = <String>[
      '运行号：${ValueReaders.stringValue(result['sub_agent_run_id']).trim()}',
      '子会话号：${ValueReaders.stringValue(result['sub_session_id']).trim()}',
      '智能体 ID：${ValueReaders.stringValue(result['agent_id'], package.agentId).trim()}',
    ];
    final selectedConflictId = package.arbitrationResult.selectedConflictId
        .trim();
    if (selectedConflictId.isNotEmpty) {
      diagnostics.add('选中的冲突：$selectedConflictId');
    }
    final acceptedConflictIds = package.arbitrationResult.acceptedConflictIds;
    if (acceptedConflictIds.isNotEmpty) {
      diagnostics.add(
        '已采纳的冲突：${acceptedConflictIds.join('、')}',
      );
    }
    return diagnostics
        .where((item) => !item.endsWith('：'))
        .toList(growable: false);
  }
}
