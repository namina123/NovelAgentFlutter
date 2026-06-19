import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/workbench_information_view_data.dart';

class WorkspaceInformationProjectionService {
  const WorkspaceInformationProjectionService({
    ContextActivationCodecService? contextActivationCodecService,
  }) : _contextActivationCodecService =
           contextActivationCodecService ??
           const ContextActivationCodecService();

  final ContextActivationCodecService _contextActivationCodecService;

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

    final activationReport = _latestActivationReport(fileMap);
    final selectedSections = _selectedActivationItems(activationReport);
    final omittedSections = _omittedActivationItems(activationReport);

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
          relativePath:
              InformationProjectionDocument.knowledgeSummaryRelativePath,
          fileMap: fileMap,
          usage:
              usageByPath[InformationProjectionDocument
                  .knowledgeSummaryRelativePath],
        ),
      if (normalizedPaths.contains(
        InformationProjectionDocument.designSummaryRelativePath,
      ))
        _projectionEntry(
          id: 'design_projection',
          title: '巧思与设计',
          subtitle: '角色设计、结构巧思与创作方案',
          summary: '查看 design element 的用户可读摘要。',
          statusLabel: '巧思',
          relativePath: InformationProjectionDocument.designSummaryRelativePath,
          fileMap: fileMap,
          usage:
              usageByPath[InformationProjectionDocument
                  .designSummaryRelativePath],
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
          relativePath:
              InformationProjectionDocument.researchSummaryRelativePath,
          fileMap: fileMap,
          usage:
              usageByPath[InformationProjectionDocument
                  .researchSummaryRelativePath],
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
          relativePath:
              InformationProjectionDocument.referenceBoundaryRelativePath,
          fileMap: fileMap,
          usage:
              usageByPath[InformationProjectionDocument
                  .referenceBoundaryRelativePath],
        ),
    ];

    final usageSummary = _usageSummary(
      selectedSections: selectedSections,
      omittedSections: omittedSections,
    );
    final summary = _summary(entries: entries);
    return WorkbenchInformationViewData(
      summary: summary,
      usageSummary: usageSummary,
      entries: entries,
    );
  }

  WorkbenchInformationEntryViewData _projectionEntry({
    required String id,
    required String title,
    required String subtitle,
    required String summary,
    required String statusLabel,
    required String relativePath,
    required Map<String, String> fileMap,
    required _UsageProjection? usage,
  }) {
    final projectionMetadata = _projectionMetadata(fileMap[relativePath]);
    return WorkbenchInformationEntryViewData(
      id: id,
      title: title,
      subtitle: subtitle,
      summary: summary,
      statusLabel: statusLabel,
      usageLabel: _usageLabel(usage),
      riskLabel: _riskLabel(usage),
      mountStatusLabel: projectionMetadata.mountStatusLabel,
      sourceOfTruthSummary: projectionMetadata.sourceOfTruthSummary,
      sourceIdentitySummary: projectionMetadata.sourceIdentitySummary,
      actionLabel: '打开摘要',
      relativePath: relativePath,
    );
  }

  String _summary({required List<WorkbenchInformationEntryViewData> entries}) {
    if (entries.isEmpty) {
      return '当前项目还没有形成可回看的资料与巧思摘要。';
    }
    return '已整理 ${entries.length} 组资料摘要';
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
        .map(_humanizedOmissionReason)
        .join(' ');
    return reason.isEmpty ? '本轮没有进入上下文' : reason;
  }

  String _humanizedOmissionReason(String reason) {
    switch (reason.trim()) {
      case 'budget_exhausted':
        return '上下文预算不足';
      case 'out_of_budget':
        return '上下文预算不足';
      case '资料太旧':
        return '资料太旧';
      case '还没确认边界':
        return '引用边界尚未确认';
      default:
        final trimmed = reason.trim();
        return _looksLikeInternalCode(trimmed) ? '未纳入本轮摘要' : trimmed;
    }
  }

  bool _looksLikeInternalCode(String text) {
    return text.isNotEmpty &&
        RegExp(r'^[a-z0-9_:-]+$').hasMatch(text) &&
        text.contains(RegExp(r'[_:-]'));
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

  _ProjectionMetadata _projectionMetadata(String? markdown) {
    final normalizedMarkdown = (markdown ?? '').replaceAll('\r\n', '\n');
    if (normalizedMarkdown.trim().isEmpty) {
      return const _ProjectionMetadata();
    }
    final sourceOfTruthPaths = _sourceOfTruthPaths(normalizedMarkdown);
    final sourceIdentityItems = _sourceIdentityItems(normalizedMarkdown);
    return _ProjectionMetadata(
      mountStatusLabel: sourceOfTruthPaths.isEmpty ? '' : '已挂载',
      sourceOfTruthSummary: sourceOfTruthPaths.isEmpty
          ? ''
          : '来源：${_joinedSummary(sourceOfTruthPaths)}',
      sourceIdentitySummary: sourceIdentityItems.isEmpty
          ? ''
          : '来源类型：${_joinedSummary(sourceIdentityItems)}',
    );
  }

  List<String> _sourceOfTruthPaths(String markdown) {
    final frontmatter = _frontmatter(markdown);
    if (frontmatter.isEmpty) {
      return const <String>[];
    }
    final paths = <String>[];
    var inSourceOfTruthBlock = false;
    for (final rawLine in frontmatter.split('\n')) {
      final trimmedLine = rawLine.trim();
      if (!inSourceOfTruthBlock) {
        if (trimmedLine == 'source_of_truth_paths:') {
          inSourceOfTruthBlock = true;
        }
        continue;
      }
      if (trimmedLine.isEmpty) {
        continue;
      }
      if (!trimmedLine.startsWith('- ')) {
        break;
      }
      final path = _trimYamlScalar(trimmedLine.substring(2));
      if (path.isNotEmpty) {
        paths.add(path);
      }
    }
    return _deduplicatedOrdered(paths);
  }

  List<String> _sourceIdentityItems(String markdown) {
    final items = <String>[];
    for (final rawLine in markdown.split('\n')) {
      final trimmedLine = rawLine.trim();
      final prefix = trimmedLine.startsWith('- 来源类型：')
          ? '- 来源类型：'
          : trimmedLine.startsWith('- 来源身份：')
          ? '- 来源身份：'
          : '';
      if (prefix.isEmpty) {
        continue;
      }
      final item = _string(trimmedLine.substring(prefix.length));
      if (item.isNotEmpty) {
        items.add(item);
      }
    }
    return _deduplicatedOrdered(items);
  }

  String _frontmatter(String markdown) {
    if (!markdown.startsWith('---\n')) {
      return '';
    }
    final closingIndex = markdown.indexOf('\n---\n', 4);
    if (closingIndex < 0) {
      return '';
    }
    return markdown.substring(4, closingIndex);
  }

  String _joinedSummary(List<String> items) {
    if (items.isEmpty) {
      return '';
    }
    if (items.length == 1) {
      return items.first;
    }
    if (items.length == 2) {
      return '${items.first}；${items.last}';
    }
    return '${items[0]}；${items[1]}；另 ${items.length - 2} 条';
  }

  List<String> _deduplicatedOrdered(Iterable<String> items) {
    final result = <String>[];
    final seen = <String>{};
    for (final item in items) {
      if (seen.add(item)) {
        result.add(item);
      }
    }
    return result;
  }

  String _trimYamlScalar(String value) {
    final text = value.trim();
    if (text.length >= 2 &&
        ((text.startsWith("'") && text.endsWith("'")) ||
            (text.startsWith('"') && text.endsWith('"')))) {
      return text.substring(1, text.length - 1).trim();
    }
    return text;
  }

  ContextActivationReport? _latestActivationReport(
    Map<String, String> fileMap,
  ) {
    final reportPath =
        fileMap.keys
            .where((path) => path.contains('activation_report.json'))
            .toList(growable: false)
          ..sort();
    if (reportPath.isEmpty) {
      return null;
    }
    final report = _decodedMap(fileMap[reportPath.last]);
    if (report.isEmpty) {
      return null;
    }
    return _contextActivationCodecService.reportFromJson(report);
  }

  List<JsonMap> _selectedActivationItems(ContextActivationReport? report) {
    if (report == null) {
      return const <JsonMap>[];
    }
    return report.items
        .where((item) => item.selected)
        .map(_activationItemJson)
        .toList(growable: false);
  }

  List<JsonMap> _omittedActivationItems(ContextActivationReport? report) {
    if (report == null) {
      return const <JsonMap>[];
    }
    return report.items
        .where((item) => item.omitted)
        .map(_activationItemJson)
        .toList(growable: false);
  }

  JsonMap _activationItemJson(ContextActivationItem item) {
    return <String, Object?>{
      'item_id': item.itemId,
      'source': item.source,
      'title': item.title,
      'target_path': item.targetPath,
      'requested_chars': item.requestedChars,
      'included_chars': item.includedChars,
      'selected': item.selected,
      'omitted': item.omitted,
      'truncated': item.truncated,
      'omission_reason': item.omissionReason,
      'truncation_reason': item.truncationReason,
      'source_kind': ValueReaders.stringValue(item.metadata['source_kind']),
      'source_of_truth_locator': ValueReaders.stringValue(
        item.metadata['source_of_truth_locator'],
      ),
      'source_display': ValueReaders.stringValue(
        item.metadata['source_display'],
      ),
      'explanation': ValueReaders.stringValue(item.metadata['explanation']),
    };
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

class _ProjectionMetadata {
  const _ProjectionMetadata({
    this.mountStatusLabel = '',
    this.sourceOfTruthSummary = '',
    this.sourceIdentitySummary = '',
  });

  final String mountStatusLabel;
  final String sourceOfTruthSummary;
  final String sourceIdentitySummary;
}
