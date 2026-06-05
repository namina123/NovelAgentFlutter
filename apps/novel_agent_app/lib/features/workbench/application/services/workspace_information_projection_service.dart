import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/workbench_information_view_data.dart';

class WorkspaceInformationProjectionService {
  const WorkspaceInformationProjectionService();

  WorkbenchInformationViewData build({
    required List<JsonMap> workspaceEntries,
    required Map<String, String> fileContents,
  }) {
    final normalizedPaths = workspaceEntries
        .map((entry) => _path(entry['relative_path']))
        .where((path) => path.isNotEmpty)
        .toSet();
    final fileMap = <String, String>{};
    for (final entry in fileContents.entries) {
      final path = _path(entry.key);
      if (path.isNotEmpty) {
        fileMap[path] = entry.value;
        normalizedPaths.add(path);
      }
    }

    final selectedSections = _activationSections(
      fileMap,
      bucket: 'selected_context_sections',
    );
    final omittedSections = _activationSections(
      fileMap,
      bucket: 'omitted_context_sections',
    );

    final usageByPath = <String, _UsageProjection>{};
    for (final section in selectedSections) {
      final targetPath = _path(section['target_path']);
      if (targetPath.isEmpty) {
        continue;
      }
      final current = usageByPath[targetPath] ?? const _UsageProjection();
      usageByPath[targetPath] = current.copyWith(
        selectedCount: current.selectedCount + 1,
        selectedReasons: <String>{
          ...current.selectedReasons,
          _string(section['explanation']),
        },
      );
    }
    for (final section in omittedSections) {
      final targetPath = _path(section['target_path']);
      if (targetPath.isEmpty) {
        continue;
      }
      final current = usageByPath[targetPath] ?? const _UsageProjection();
      usageByPath[targetPath] = current.copyWith(
        omittedCount: current.omittedCount + 1,
        omittedReasons: <String>{
          ...current.omittedReasons,
          _string(section['explanation']),
          _string(section['omission_reason']),
        },
      );
    }

    final entries = <WorkbenchInformationEntryViewData>[
      if (normalizedPaths.contains(
        InformationProjectionDocument.knowledgeSummaryRelativePath,
      ))
        _projectionEntry(
          id: 'knowledge_projection',
          title: '知识摘要',
          subtitle: '已整理的长期设定与世界事实',
          summary: '查看当前 knowledge 卡片的用户可读摘要。',
          statusLabel: '知识',
          relativePath: InformationProjectionDocument.knowledgeSummaryRelativePath,
          usage: usageByPath[InformationProjectionDocument.knowledgeSummaryRelativePath],
        ),
      if (normalizedPaths.contains(
        InformationProjectionDocument.designSummaryRelativePath,
      ))
        _projectionEntry(
          id: 'design_projection',
          title: '巧思与设计',
          subtitle: '角色设计、结构巧思与创作方案',
          summary: '查看 design element 的用户可读投影。',
          statusLabel: '巧思',
          relativePath: InformationProjectionDocument.designSummaryRelativePath,
          usage: usageByPath[InformationProjectionDocument.designSummaryRelativePath],
        ),
      if (normalizedPaths.contains(
        InformationProjectionDocument.researchSummaryRelativePath,
      ))
        _projectionEntry(
          id: 'research_projection',
          title: '研究摘要',
          subtitle: '资料研究、事实摘录与创作建议',
          summary: '查看 research note 的用户可读摘要。',
          statusLabel: '研究',
          relativePath: InformationProjectionDocument.researchSummaryRelativePath,
          usage: usageByPath[InformationProjectionDocument.researchSummaryRelativePath],
        ),
      if (normalizedPaths.contains(
        InformationProjectionDocument.referenceBoundaryRelativePath,
      ))
        _projectionEntry(
          id: 'reference_projection',
          title: '引用边界',
          subtitle: '引用作品关系、用途边界与风险说明',
          summary: '查看 reference work 的边界与风险摘要。',
          statusLabel: '引用',
          relativePath: InformationProjectionDocument.referenceBoundaryRelativePath,
          usage: usageByPath[InformationProjectionDocument.referenceBoundaryRelativePath],
        ),
    ];

    final pendingEntries = _pendingInformationEntries(normalizedPaths, fileMap);
    final usageSummary = _usageSummary(
      selectedSections: selectedSections,
      omittedSections: omittedSections,
    );
    final summary = _summary(entries: entries, pendingEntries: pendingEntries);
    return WorkbenchInformationViewData(
      summary: summary,
      usageSummary: usageSummary,
      entries: entries,
      pendingEntries: pendingEntries,
    );
  }

  WorkbenchInformationEntryViewData _projectionEntry({
    required String id,
    required String title,
    required String subtitle,
    required String summary,
    required String statusLabel,
    required String relativePath,
    required _UsageProjection? usage,
  }) {
    return WorkbenchInformationEntryViewData(
      id: id,
      title: title,
      subtitle: subtitle,
      summary: summary,
      statusLabel: statusLabel,
      usageLabel: _usageLabel(usage),
      riskLabel: _riskLabel(usage),
      actionLabel: '打开摘要',
      relativePath: relativePath,
    );
  }

  List<WorkbenchInformationEntryViewData> _pendingInformationEntries(
    Set<String> normalizedPaths,
    Map<String, String> fileMap,
  ) {
    final entries = <WorkbenchInformationEntryViewData>[];
    for (final path in normalizedPaths.toList()..sort()) {
      if (path.startsWith('.novel_agent/information/knowledge_cards/')) {
        final card = ProjectKnowledgeCard.fromJson(_decodedMap(fileMap[path]));
        if (card.lifecycleStatus == InformationLifecycleStatuses.proposed) {
          entries.add(
            WorkbenchInformationEntryViewData(
              id: card.cardId,
              title: '待确认知识',
              subtitle: card.title,
              summary: card.summary.trim().isEmpty ? '这条长期设定需要确认后再进入主知识层。' : card.summary.trim(),
              statusLabel: '待确认',
              usageLabel: '需要确认后才能稳定复用',
              riskLabel: '会影响后续写作与信息激活',
              actionLabel: '查看待确认',
              relativePath: path,
            ),
          );
        }
      } else if (path.startsWith('.novel_agent/information/design_elements/')) {
        final card = DesignElementCard.fromJson(_decodedMap(fileMap[path]));
        if (card.lifecycleStatus == InformationLifecycleStatuses.proposed) {
          entries.add(
            WorkbenchInformationEntryViewData(
              id: card.designId,
              title: '待确认巧思',
              subtitle: card.designLabel,
              summary: '这条巧思/设计还在提案阶段，确认后才会进入稳定资料层。',
              statusLabel: '待确认',
              usageLabel: '未确认前不应当成既定事实',
              riskLabel: '可能改变后续结构或角色设计',
              actionLabel: '查看待确认',
              relativePath: path,
            ),
          );
        }
      } else if (path.startsWith('.novel_agent/information/research_requests/')) {
        final record = _decodedMap(fileMap[path]);
        final requestState = _string(record['request_state']);
        if (requestState.isNotEmpty && requestState != 'completed') {
          final request = _map(record['research_request']);
          entries.add(
            WorkbenchInformationEntryViewData(
              id: _string(record['request_id'], path),
              title: '待确认研究',
              subtitle: _string(request['query']),
              summary: '这条外部研究请求还没完成确认，相关事实不应直接当作定论。',
              statusLabel: '待确认',
              usageLabel: '需要先明确是否继续研究',
              riskLabel: '可能涉及事实缺口或外部资料风险',
              actionLabel: '查看待确认',
              relativePath: path,
            ),
          );
        }
      } else if (path.startsWith('.novel_agent/information/reference_works/')) {
        final record = ReferenceWorkRecord.fromJson(_decodedMap(fileMap[path]));
        if (record.requiresConfirmation) {
          entries.add(
            WorkbenchInformationEntryViewData(
              id: record.referenceWorkId,
              title: '待确认引用边界',
              subtitle: record.title,
              summary: record.allowedUsageSummary.trim().isEmpty
                  ? record.declaredUsageIntent
                  : record.allowedUsageSummary.trim(),
              statusLabel: '待确认',
              usageLabel: '边界未确认前请谨慎复用',
              riskLabel: '存在引用关系或风险说明需要处理',
              actionLabel: '查看待确认',
              relativePath: path,
            ),
          );
        }
      }
    }
    return entries;
  }

  String _summary({
    required List<WorkbenchInformationEntryViewData> entries,
    required List<WorkbenchInformationEntryViewData> pendingEntries,
  }) {
    if (entries.isEmpty && pendingEntries.isEmpty) {
      return '当前项目还没有形成可回看的资料与巧思摘要。';
    }
    final parts = <String>[];
    if (entries.isNotEmpty) {
      parts.add('已整理 ${entries.length} 组资料摘要');
    }
    if (pendingEntries.isNotEmpty) {
      parts.add('${pendingEntries.length} 项待确认');
    }
    return parts.join('，');
  }

  String _usageSummary({
    required List<JsonMap> selectedSections,
    required List<JsonMap> omittedSections,
  }) {
    if (selectedSections.isEmpty && omittedSections.isEmpty) {
      return '本轮还没有可解释的资料使用记录。';
    }
    final selectedKinds = _kindLabels(selectedSections);
    final omittedKinds = _kindLabels(omittedSections);
    final parts = <String>[];
    if (selectedKinds.isNotEmpty) {
      parts.add('本轮已使用：${selectedKinds.join('、')}');
    }
    if (omittedKinds.isNotEmpty) {
      parts.add('本轮未使用：${omittedKinds.join('、')}');
    }
    return parts.join('；');
  }

  String _usageLabel(_UsageProjection? usage) {
    if (usage == null) {
      return '本轮没有读到明确使用记录';
    }
    if (usage.selectedCount > 0) {
      return '本轮已使用 ${usage.selectedCount} 次';
    }
    if (usage.omittedCount > 0) {
      return '本轮未使用';
    }
    return '本轮没有读到明确使用记录';
  }

  String _riskLabel(_UsageProjection? usage) {
    if (usage == null || usage.omittedCount == 0) {
      return '';
    }
    final reason = usage.omittedReasons
        .where((item) => item.trim().isNotEmpty)
        .join(' ');
    return reason.isEmpty ? '本轮没有进入上下文' : reason;
  }

  List<String> _kindLabels(List<JsonMap> sections) {
    final labels = <String>{};
    for (final section in sections) {
      final kind = _string(section['source_kind']);
      final label = switch (kind) {
        'project_knowledge_card' => '知识',
        'project_design_element' => '巧思',
        'project_research_note' => '研究',
        'project_reference_work' => '引用边界',
        _ => '',
      };
      if (label.isNotEmpty) {
        labels.add(label);
      }
    }
    return labels.toList(growable: false);
  }

  List<JsonMap> _activationSections(
    Map<String, String> fileMap, {
    required String bucket,
  }) {
    final reportPath = fileMap.keys
        .where((path) => path.contains('activation_report.json'))
        .toList(growable: false)
      ..sort();
    if (reportPath.isEmpty) {
      return const <JsonMap>[];
    }
    final report = _decodedMap(fileMap[reportPath.last]);
    return ValueReaders.mapList(_map(report['metadata'])[bucket]);
  }

  JsonMap _decodedMap(String? raw) {
    if ((raw ?? '').trim().isEmpty) {
      return const <String, Object?>{};
    }
    final decoded = jsonDecode(raw!);
    return _map(decoded);
  }

  JsonMap _map(Object? value) {
    if (value is Map<String, Object?>) {
      return ValueReaders.deepCopyMap(value);
    }
    if (value is Map) {
      final result = <String, Object?>{};
      value.forEach((key, entry) {
        result[key.toString()] = entry;
      });
      return result;
    }
    return const <String, Object?>{};
  }

  String _path(Object? value) {
    return _string(value).replaceAll('\\', '/');
  }

  String _string(Object? value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _UsageProjection {
  const _UsageProjection({
    this.selectedCount = 0,
    this.omittedCount = 0,
    this.selectedReasons = const <String>{},
    this.omittedReasons = const <String>{},
  });

  final int selectedCount;
  final int omittedCount;
  final Set<String> selectedReasons;
  final Set<String> omittedReasons;

  _UsageProjection copyWith({
    int? selectedCount,
    int? omittedCount,
    Set<String>? selectedReasons,
    Set<String>? omittedReasons,
  }) {
    return _UsageProjection(
      selectedCount: selectedCount ?? this.selectedCount,
      omittedCount: omittedCount ?? this.omittedCount,
      selectedReasons: selectedReasons ?? this.selectedReasons,
      omittedReasons: omittedReasons ?? this.omittedReasons,
    );
  }
}
