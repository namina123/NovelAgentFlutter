import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/conversation_entry_view_data.dart';

class ConversationToolEntryProjectionService {
  ConversationToolEntryProjectionService({
    ToolEventPresenterService? toolEventPresenterService,
  }) : _toolEventPresenterService =
           toolEventPresenterService ?? ToolEventPresenterService();

  final ToolEventPresenterService _toolEventPresenterService;

  List<ConversationEntryViewData> build(List<Object?> executedTools) {
    return buildWithOptions(executedTools);
  }

  List<ConversationEntryViewData> buildWithOptions(
    List<Object?> executedTools, {
    bool includeDetailBodies = true,
  }) {
    // 中文注释: 工具时间线投影单独抽出来，专门负责“轻量展示 + 连续重复压缩”。
    final result = <ConversationEntryViewData>[];
    _ProjectedToolGroup? currentGroup;
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      if (tool.isEmpty || _shouldSuppressFromTimeline(tool)) {
        continue;
      }
      final projected = _project(
        tool,
        includeDetailBodies: includeDetailBodies,
      );
      if (currentGroup != null && currentGroup.canAbsorb(projected)) {
        currentGroup = currentGroup.copyWith(count: currentGroup.count + 1);
        continue;
      }
      if (currentGroup != null) {
        result.add(currentGroup.toEntry());
      }
      currentGroup = _ProjectedToolGroup.fromEntry(projected);
    }
    if (currentGroup != null) {
      result.add(currentGroup.toEntry());
    }
    return result;
  }

  bool _shouldSuppressFromTimeline(JsonMap tool) {
    // 中文注释: 子智能体委派改由专属 preview/detail 流承接，主时间线不再重复刷底层工具回显。
    return ValueReaders.stringValue(tool['name']) == 'call_sub_agent';
  }

  ConversationEntryViewData _project(
    JsonMap tool, {
    required bool includeDetailBodies,
  }) {
    final name = ValueReaders.stringValue(tool['name'], '工具');
    final isError =
        !ValueReaders.boolValue(tool['ok'], true) &&
        !ValueReaders.boolValue(tool['not_executed']);
    return ConversationEntryViewData(
      id: 'tool_${ValueReaders.stringValue(tool['id'], name)}',
      kind: ConversationEntryKind.tool,
      title: name,
      body: _toolEventPresenterService.textForExecutedTool(tool),
      isError: isError,
      detailTitle: '工具细节',
      detailSummary: _detailSummary(tool),
      detailBody: includeDetailBodies ? _detailBody(tool) : '',
      detailExpandedByDefault: false,
    );
  }

  String _detailSummary(JsonMap tool) {
    final target = _primaryTarget(tool);
    if (target.isNotEmpty) {
      return target;
    }
    final arguments = ValueReaders.mapValue(tool['arguments']);
    if (arguments.isNotEmpty) {
      return '含参数';
    }
    final result = ValueReaders.mapValue(tool['result']);
    if (result.isNotEmpty) {
      return '含结果';
    }
    return '';
  }

  String _detailBody(JsonMap tool) {
    final sections = <String>[];
    final arguments = ValueReaders.mapValue(tool['arguments']);
    final result = ValueReaders.mapValue(tool['result']);
    if (arguments.isNotEmpty) {
      sections.add('参数');
      sections.add(_prettyMap(arguments));
    }
    if (result.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add('结果');
      sections.add(_prettyMap(result));
    }
    return sections.join('\n');
  }

  String _primaryTarget(JsonMap tool) {
    final result = ValueReaders.mapValue(tool['result']);
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    if (changedPaths.isNotEmpty) {
      return changedPaths.first;
    }
    final relativePath = ValueReaders.stringValue(
      result['relative_path'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(tool['arguments'])['relative_path'],
      ),
    ).trim();
    if (relativePath.isNotEmpty) {
      return relativePath;
    }
    return ValueReaders.stringValue(result['question']).trim();
  }

  String _prettyMap(JsonMap map) {
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}

class _ProjectedToolGroup {
  const _ProjectedToolGroup({required this.entry, required this.count});

  final ConversationEntryViewData entry;
  final int count;

  factory _ProjectedToolGroup.fromEntry(ConversationEntryViewData entry) {
    return _ProjectedToolGroup(entry: entry, count: 1);
  }

  bool canAbsorb(ConversationEntryViewData candidate) {
    // 中文注释: 只压缩相邻且语义完全一致的工具提示，避免把不同上下文的调用硬并在一起。
    return entry.kind == candidate.kind &&
        entry.title == candidate.title &&
        entry.body == candidate.body &&
        entry.isError == candidate.isError;
  }

  _ProjectedToolGroup copyWith({ConversationEntryViewData? entry, int? count}) {
    return _ProjectedToolGroup(
      entry: entry ?? this.entry,
      count: count ?? this.count,
    );
  }

  ConversationEntryViewData toEntry() {
    if (count <= 1) {
      return entry;
    }
    return ConversationEntryViewData(
      id: '${entry.id}_x$count',
      kind: entry.kind,
      title: '${entry.title} ×$count',
      body: entry.body,
      isError: entry.isError,
      isRetryableFailure: entry.isRetryableFailure,
      detailTitle: entry.detailTitle,
      detailSummary: entry.detailSummary,
      detailBody: entry.detailBody,
      detailExpandedByDefault: entry.detailExpandedByDefault,
    );
  }
}
