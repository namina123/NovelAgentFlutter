import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_assets_snapshot.dart';
import '../models/project_assets_tab_id.dart';
import 'project_assets_expression_constraint_view_data_service.dart';
import 'project_assets_graph_view_data_service.dart';
import 'project_assets_timeline_view_data_service.dart';
import 'project_rag_extraction_view_data_service.dart';
import 'project_reference_extraction_strategy_picker_view_data_service.dart';

class ProjectAssetsViewDataService {
  const ProjectAssetsViewDataService({
    ProjectAssetsExpressionConstraintViewDataService?
    expressionConstraintViewDataService,
    ProjectAssetsGraphViewDataService? graphViewDataService,
    ProjectAssetsTimelineViewDataService? timelineViewDataService,
    ProjectReferenceExtractionStrategyPickerViewDataService?
    referenceExtractionStrategyPickerViewDataService,
    ProjectRagExtractionViewDataService? ragExtractionViewDataService,
  }) : _expressionConstraintViewDataService =
           expressionConstraintViewDataService ??
           const ProjectAssetsExpressionConstraintViewDataService(),
       _graphViewDataService =
           graphViewDataService ?? const ProjectAssetsGraphViewDataService(),
       _timelineViewDataService =
           timelineViewDataService ??
           const ProjectAssetsTimelineViewDataService(),
       _referenceExtractionStrategyPickerViewDataService =
           referenceExtractionStrategyPickerViewDataService ??
           const ProjectReferenceExtractionStrategyPickerViewDataService(),
       _ragExtractionViewDataService =
           ragExtractionViewDataService ??
           const ProjectRagExtractionViewDataService();

  final ProjectAssetsExpressionConstraintViewDataService
  _expressionConstraintViewDataService;
  final ProjectAssetsGraphViewDataService _graphViewDataService;
  final ProjectAssetsTimelineViewDataService _timelineViewDataService;
  final ProjectReferenceExtractionStrategyPickerViewDataService
  _referenceExtractionStrategyPickerViewDataService;
  final ProjectRagExtractionViewDataService _ragExtractionViewDataService;

  ProjectAssetsViewData build({
    required ProjectAssetsSnapshot snapshot,
    required String status,
    ProjectDescriptor? project,
  }) {
    // 中文注释: 资产中心的投影统一在这里收口，控制器只保留原始资产与选择状态。
    final isKnowledgeBaseProject =
        project?.projectType.trim() == 'knowledge_base';
    final isKnowledgeBaseRagWorkspace =
        isKnowledgeBaseProject &&
        const KnowledgeBaseBranchCatalogService().isRagBranch(
          project?.projectBranchId ?? '',
        );
    final isKnowledgeBaseStructuredWorkspace =
        isKnowledgeBaseProject && !isKnowledgeBaseRagWorkspace;
    final activeTabId = snapshot.activeTabId.trim().isEmpty
        ? (isKnowledgeBaseRagWorkspace
              ? ProjectAssetsTabId.ragExtraction
              : ProjectAssetsTabId.referenceExtraction)
        : snapshot.activeTabId;
    final entries = _entriesForTab(snapshot, activeTabId);
    return ProjectAssetsViewData(
      title: isKnowledgeBaseRagWorkspace
          ? '语料库'
          : (isKnowledgeBaseStructuredWorkspace
                ? '资料库'
                : ProjectAssetsViewData.initial().title),
      description: isKnowledgeBaseRagWorkspace
          ? '导入源文、构建语料、挂载到项目。这里不是普通创作工作台，而是知识库语料专用面板。'
          : isKnowledgeBaseStructuredWorkspace
          ? '这里是结构化资料库的正式工作区。它不作为普通创作台使用，知识提取、资料整理与结构化沉淀都在这里完成。'
          : _descriptionFor(snapshot, activeTabId),
      status: status,
      useDedicatedRagWorkspace: isKnowledgeBaseRagWorkspace,
      activeTabId: activeTabId,
      entryAgentContextId: snapshot.entryAgentContextId,
      tabs: isKnowledgeBaseRagWorkspace
          ? const <ProjectAssetsTabViewData>[
              ProjectAssetsTabViewData(
                id: ProjectAssetsTabId.ragExtraction,
                label: '语料提取',
              ),
            ]
          : ProjectAssetsViewData.initial().tabs,
      entries: entries,
      inspector: _inspector(snapshot, activeTabId),
      timeline: _timelineViewDataService.build(snapshot),
      graph: _graphViewDataService.build(snapshot),
      styleEditor: _styleEditor(snapshot),
      expressionConstraintEditor: _expressionConstraintViewDataService
          .buildEditor(snapshot),
      foreshadowEditor: _foreshadowEditor(snapshot),
      referenceExtractionStrategyPicker:
          _referenceExtractionStrategyPickerViewDataService.build(
            selectedProfileId: snapshot.selectedReferenceExtractionStrategyId,
            useDeconstructionProjection:
                project?.projectType.trim() ==
                BookDeconstructionConstants.projectTypeId,
          ),
      ragExtraction: _ragExtractionViewDataService.build(
        snapshot: snapshot.ragExtraction,
      ),
      isLoading: snapshot.isLoading,
    );
  }

  List<ExpressionConstraintSelectableOptionViewData>
  buildExpressionConstraintAgentOptions(List<JsonMap> agents) {
    return _expressionConstraintViewDataService.buildAgentOptions(agents);
  }

  List<ExpressionConstraintSelectableOptionViewData>
  buildExpressionConstraintModeOptions() {
    return _expressionConstraintViewDataService.buildModeOptions();
  }

  List<ExpressionConstraintSelectableOptionViewData>
  buildExpressionConstraintStageOptions() {
    return _expressionConstraintViewDataService.buildStageOptions();
  }

  String _descriptionFor(ProjectAssetsSnapshot snapshot, String activeTabId) {
    if (activeTabId == ProjectAssetsTabId.referenceExtraction) {
      return '知识提取是手动触发的正式流程，会把资料沉淀成结构化知识与参考结果；它不是拆书的一部分，也不是一次性聊天摘要。';
    }
    if (activeTabId == ProjectAssetsTabId.expressionConstraints) {
      final agentId = snapshot.entryAgentContextId.trim();
      if (agentId.isNotEmpty) {
        return '表达限制是项目级写作约束系统；当前正从智能体 $agentId 进入，可继续为它定向绑定内置或自定义规则方案。';
      }
      return '表达限制是项目级写作约束系统，可统一管理内置与项目自定义规则方案，并决定它们如何参与当前项目。';
    }
    return ProjectAssetsViewData.initial().description;
  }

  List<ProjectAssetEntryViewData> _entriesForTab(
    ProjectAssetsSnapshot snapshot,
    String activeTabId,
  ) {
    switch (activeTabId) {
      case ProjectAssetsTabId.referenceExtraction:
        return const <ProjectAssetEntryViewData>[];
      case ProjectAssetsTabId.expressionConstraints:
        return _expressionConstraintViewDataService.buildEntries(snapshot);
      case ProjectAssetsTabId.foreshadows:
        return _foreshadowEntries(snapshot);
      case ProjectAssetsTabId.timelines:
        return _timelineEntries(snapshot);
      case ProjectAssetsTabId.relationships:
        return _relationshipEntries(snapshot);
      case ProjectAssetsTabId.graph:
        return _graphEntries(snapshot);
      case ProjectAssetsTabId.styles:
      default:
        return _styleEntries(snapshot);
    }
  }

  List<ProjectAssetEntryViewData> _styleEntries(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedStyleId(snapshot);
    return snapshot.catalog.styles
        .map(
          (item) => ProjectAssetEntryViewData(
            id: ValueReaders.stringValue(item['id']),
            title: ValueReaders.stringValue(
              item['display_name'],
              ValueReaders.stringValue(item['id']),
            ),
            subtitle: ValueReaders.stringValue(item['genre']),
            badge: ValueReaders.boolValue(item['default_for_project'])
                ? '默认'
                : ValueReaders.stringValue(item['tone']),
            relativePath: ValueReaders.stringValue(item['relative_path']),
            meta: ValueReaders.stringValue(item['audience']),
            isSelected: ValueReaders.stringValue(item['id']) == selectedId,
          ),
        )
        .toList(growable: false);
  }

  List<ProjectAssetEntryViewData> _foreshadowEntries(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedForeshadowId(snapshot);
    return snapshot.catalog.foreshadows
        .map(
          (item) => ProjectAssetEntryViewData(
            id: item.id,
            title: item.title,
            subtitle: item.summary,
            badge: item.status,
            relativePath: item.sourcePath,
            meta: item.targetPayoffPath,
            isSelected: item.id == selectedId,
          ),
        )
        .toList(growable: false);
  }

  List<ProjectAssetEntryViewData> _timelineEntries(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedTimelineId(snapshot);
    return snapshot.catalog.timelines
        .map(
          (item) => ProjectAssetEntryViewData(
            id: item.id,
            title: item.displayName,
            subtitle: item.summary,
            badge: item.status,
            relativePath: item.sourcePath,
            meta: item.phaseLabel,
            isSelected: item.id == selectedId,
          ),
        )
        .toList(growable: false);
  }

  List<ProjectAssetEntryViewData> _relationshipEntries(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedRelationshipId(snapshot);
    return snapshot.catalog.relationships
        .map(
          (item) => ProjectAssetEntryViewData(
            id: item.id,
            title: item.displayName,
            subtitle: item.summary,
            badge: item.relationshipType,
            relativePath: item.sourcePath,
            meta: '${item.leftEntityId} -> ${item.rightEntityId}',
            isSelected: item.id == selectedId,
          ),
        )
        .toList(growable: false);
  }

  List<ProjectAssetEntryViewData> _graphEntries(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedKey = _selectedGraphReferenceKey(snapshot);
    return snapshot.catalog.referenceIndex.references
        .map(
          (item) => ProjectAssetEntryViewData(
            id: item.referenceKey,
            title: item.displayName,
            subtitle: item.summary,
            badge: _kindLabel(item.assetKind),
            relativePath: item.sourcePath,
            meta: '关联 ${item.relatedReferenceKeys.length}',
            isSelected: item.referenceKey == selectedKey,
          ),
        )
        .toList(growable: false);
  }

  StyleProfileEditorViewData _styleEditor(ProjectAssetsSnapshot snapshot) {
    final selectedId = _selectedStyleId(snapshot);
    final selected = snapshot.catalog.styles.firstWhere(
      (item) => ValueReaders.stringValue(item['id']) == selectedId,
      orElse: () => const <String, Object?>{},
    );
    if (selected.isEmpty) {
      return StyleProfileEditorViewData.empty();
    }
    return StyleProfileEditorViewData(
      id: ValueReaders.stringValue(selected['id']),
      displayName: ValueReaders.stringValue(selected['display_name']),
      summary: ValueReaders.stringValue(selected['summary']),
      genre: ValueReaders.stringValue(selected['genre']),
      tone: ValueReaders.stringValue(selected['tone']),
      audience: ValueReaders.stringValue(selected['audience']),
      tagsText: ValueReaders.stringList(selected['tags']).join(', '),
      guardrailsText: ValueReaders.stringList(
        selected['guardrails'],
      ).join(', '),
      examplePathsText: ValueReaders.stringList(
        selected['example_paths'],
      ).join(', '),
      inheritedIdsText: ValueReaders.stringList(
        selected['inherited_from_ids'],
      ).join(', '),
      defaultForProject: ValueReaders.boolValue(
        selected['default_for_project'],
      ),
      relativePath: ValueReaders.stringValue(selected['relative_path']),
    );
  }

  ForeshadowRecordEditorViewData _foreshadowEditor(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedForeshadowId(snapshot);
    final selected = snapshot.catalog.foreshadows.where(
      (item) => item.id == selectedId,
    );
    if (selected.isEmpty) {
      return ForeshadowRecordEditorViewData.empty();
    }
    final record = selected.first;
    return ForeshadowRecordEditorViewData(
      id: record.id,
      title: record.title,
      status: record.status,
      summary: record.summary,
      plantedChapterPath: record.plantedChapterPath,
      targetPayoffPath: record.targetPayoffPath,
      relatedEntityIdsText: record.relatedEntityIds.join(', '),
      relatedPathsText: record.relatedPaths.join(', '),
      triggerConditionsText: record.triggerConditions.join(', '),
      payoffExpectationsText: record.payoffExpectations.join(', '),
      tagsText: record.tags.join(', '),
      notes: record.notes,
      relativePath: record.sourcePath,
    );
  }

  ProjectAssetsInspectorViewData _inspector(
    ProjectAssetsSnapshot snapshot,
    String activeTabId,
  ) {
    switch (activeTabId) {
      case ProjectAssetsTabId.referenceExtraction:
        return ProjectAssetsInspectorViewData(
          title: '知识提取',
          subtitle: '手动执行知识提取，把资料沉淀为结构化知识、设计、研究与引用边界结果。',
          badge: '正式入口',
          sourcePath: '',
          sections: <ProjectAssetsInspectorSectionViewData>[
            ProjectAssetsInspectorSectionViewData(
              title: '当前作用',
              lines: const <String>[
                '这是独立的知识提取流程，不会随着拆书自动发生。',
                '普通项目会从你手动选择的资料开始提取；拆书项目则会直接使用已确认的拆书产物。',
                '提取结果会沉淀到资料与设定层，而不是停留在一次性预览里。',
              ],
            ),
            ProjectAssetsInspectorSectionViewData(
              title: '建议顺序',
              lines: const <String>[
                '1. 先准备资料源，或在拆书项目里先完成拆书预览并确认。',
                '2. 再手动进入这里执行知识提取。',
                '3. 最后根据提取结果进入续写、同人或普通创作。',
              ],
            ),
          ],
          relatedAssets: const <ProjectAssetsRelatedAssetViewData>[],
          emptyMessage: '',
        );
      case ProjectAssetsTabId.expressionConstraints:
        return ProjectAssetsInspectorViewData.empty();
      case ProjectAssetsTabId.timelines:
        return _timelineInspector(snapshot);
      case ProjectAssetsTabId.relationships:
        return _relationshipInspector(snapshot);
      case ProjectAssetsTabId.graph:
        return _graphInspector(snapshot);
      case ProjectAssetsTabId.foreshadows:
        return _foreshadowInspector(snapshot);
      case ProjectAssetsTabId.styles:
      default:
        return _styleInspector(snapshot);
    }
  }

  ProjectAssetsInspectorViewData _styleInspector(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedStyleId(snapshot);
    final selected = snapshot.catalog.styles.firstWhere(
      (item) => ValueReaders.stringValue(item['id']) == selectedId,
      orElse: () => const <String, Object?>{},
    );
    if (selected.isEmpty) {
      return ProjectAssetsInspectorViewData.empty();
    }
    return ProjectAssetsInspectorViewData(
      title: ValueReaders.stringValue(selected['display_name'], selectedId),
      subtitle: ValueReaders.stringValue(selected['summary']),
      badge: ValueReaders.boolValue(selected['default_for_project'])
          ? '默认风格'
          : '风格',
      sourcePath: ValueReaders.stringValue(selected['relative_path']),
      sections: <ProjectAssetsInspectorSectionViewData>[
        ProjectAssetsInspectorSectionViewData(
          title: '定位',
          lines: <String>[
            '题材：${ValueReaders.stringValue(selected['genre'], '未填写')}',
            '语气：${ValueReaders.stringValue(selected['tone'], '未填写')}',
            '受众：${ValueReaders.stringValue(selected['audience'], '未填写')}',
          ],
        ),
        ProjectAssetsInspectorSectionViewData(
          title: '约束',
          lines: ValueReaders.stringList(selected['guardrails']).isEmpty
              ? const <String>['当前没有额外风格约束。']
              : ValueReaders.stringList(selected['guardrails']),
        ),
      ],
      relatedAssets: const <ProjectAssetsRelatedAssetViewData>[],
      emptyMessage: '',
    );
  }

  ProjectAssetsInspectorViewData _foreshadowInspector(
    ProjectAssetsSnapshot snapshot,
  ) {
    final record = snapshot.catalog.foreshadows.firstWhere(
      (item) => item.id == _selectedForeshadowId(snapshot),
      orElse: () => const ForeshadowRecord(id: '', title: '', status: ''),
    );
    if (record.id.isEmpty) {
      return ProjectAssetsInspectorViewData.empty();
    }
    return ProjectAssetsInspectorViewData(
      title: record.title,
      subtitle: record.summary,
      badge: record.status,
      sourcePath: record.sourcePath,
      sections: <ProjectAssetsInspectorSectionViewData>[
        ProjectAssetsInspectorSectionViewData(
          title: '埋设与回收',
          lines: <String>[
            '埋设位置：${record.plantedChapterPath.isEmpty ? '未标记' : record.plantedChapterPath}',
            '目标回收：${record.targetPayoffPath.isEmpty ? '未标记' : record.targetPayoffPath}',
          ],
        ),
        ProjectAssetsInspectorSectionViewData(
          title: '触发条件',
          lines: record.triggerConditions.isEmpty
              ? const <String>['当前没有触发条件。']
              : record.triggerConditions,
        ),
      ],
      relatedAssets: _relatedAssets(snapshot, 'foreshadow', record.id),
      emptyMessage: '',
    );
  }

  ProjectAssetsInspectorViewData _timelineInspector(
    ProjectAssetsSnapshot snapshot,
  ) {
    final record = snapshot.catalog.timelines.firstWhere(
      (item) => item.id == _selectedTimelineId(snapshot),
      orElse: () => const TimelineRecord(id: '', displayName: ''),
    );
    if (record.id.isEmpty) {
      return ProjectAssetsInspectorViewData.empty();
    }
    return ProjectAssetsInspectorViewData(
      title: record.displayName,
      subtitle: record.summary,
      badge: record.status,
      sourcePath: record.sourcePath,
      sections: <ProjectAssetsInspectorSectionViewData>[
        ProjectAssetsInspectorSectionViewData(
          title: '阶段信息',
          lines: <String>[
            '阶段：${record.phaseLabel.isEmpty ? '未填写' : record.phaseLabel}',
            '事件类型：${record.eventType.isEmpty ? '未填写' : record.eventType}',
            '排序：${record.sequence}',
          ],
        ),
      ],
      relatedAssets: _relatedAssets(snapshot, 'timeline', record.id),
      emptyMessage: '',
    );
  }

  ProjectAssetsInspectorViewData _relationshipInspector(
    ProjectAssetsSnapshot snapshot,
  ) {
    final record = snapshot.catalog.relationships.firstWhere(
      (item) => item.id == _selectedRelationshipId(snapshot),
      orElse: () => const RelationshipRecord(
        id: '',
        displayName: '',
        leftEntityId: '',
        rightEntityId: '',
      ),
    );
    if (record.id.isEmpty) {
      return ProjectAssetsInspectorViewData.empty();
    }
    return ProjectAssetsInspectorViewData(
      title: record.displayName,
      subtitle: record.summary,
      badge: record.relationshipType.isEmpty
          ? record.status
          : record.relationshipType,
      sourcePath: record.sourcePath,
      sections: <ProjectAssetsInspectorSectionViewData>[
        ProjectAssetsInspectorSectionViewData(
          title: '关联实体',
          lines: <String>[
            '左侧：${record.leftEntityId}',
            '右侧：${record.rightEntityId}',
            '状态：${record.status}',
          ],
        ),
      ],
      relatedAssets: _relatedAssets(snapshot, 'relationship', record.id),
      emptyMessage: '',
    );
  }

  ProjectAssetsInspectorViewData _graphInspector(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedKey = _selectedGraphReferenceKey(snapshot);
    final reference = snapshot.catalog.referenceIndex.references.firstWhere(
      (item) => item.referenceKey == selectedKey,
      orElse: () => const SharedNarrativeAssetReference(
        referenceKey: '',
        assetId: '',
        assetKind: '',
        displayName: '',
      ),
    );
    if (reference.referenceKey.isEmpty) {
      return ProjectAssetsInspectorViewData(
        title: '共享资产图谱',
        subtitle: '选择左侧节点查看关联。',
        badge: '',
        sourcePath: '',
        sections: const <ProjectAssetsInspectorSectionViewData>[],
        relatedAssets: const <ProjectAssetsRelatedAssetViewData>[],
        emptyMessage: '',
      );
    }
    return ProjectAssetsInspectorViewData(
      title: reference.displayName,
      subtitle: reference.summary,
      badge: _kindLabel(reference.assetKind),
      sourcePath: reference.sourcePath,
      sections: <ProjectAssetsInspectorSectionViewData>[
        ProjectAssetsInspectorSectionViewData(
          title: '结构摘要',
          lines: <String>[
            '实体数：${reference.entityIds.length}',
            '已知关联：${reference.relatedReferenceKeys.length}',
            '缺失关联：${reference.missingReferenceKeys.length}',
          ],
        ),
      ],
      relatedAssets: _relatedAssetsByReference(snapshot, reference),
      emptyMessage: '',
    );
  }

  List<ProjectAssetsRelatedAssetViewData> _relatedAssets(
    ProjectAssetsSnapshot snapshot,
    String assetKind,
    String assetId,
  ) {
    final reference = snapshot.catalog.referenceIndex.referenceOf(
      assetKind,
      assetId,
    );
    if (reference == null) {
      return const <ProjectAssetsRelatedAssetViewData>[];
    }
    return _relatedAssetsByReference(snapshot, reference);
  }

  List<ProjectAssetsRelatedAssetViewData> _relatedAssetsByReference(
    ProjectAssetsSnapshot snapshot,
    SharedNarrativeAssetReference reference,
  ) {
    final neighbors = snapshot.catalog.referenceIndex.neighborsOf(
      reference.assetKind,
      reference.assetId,
    );
    return neighbors
        .map(
          (item) => ProjectAssetsRelatedAssetViewData(
            referenceKey: item.referenceKey,
            title: item.displayName,
            badge: _kindLabel(item.assetKind),
            subtitle: item.summary,
            isSelected: item.referenceKey == reference.referenceKey,
          ),
        )
        .toList(growable: false);
  }

  String _selectedStyleId(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedStyleId.trim().isNotEmpty) {
      return snapshot.selectedStyleId.trim();
    }
    if (snapshot.catalog.styles.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(snapshot.catalog.styles.first['id']);
  }

  String _selectedForeshadowId(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedForeshadowId.trim().isNotEmpty) {
      return snapshot.selectedForeshadowId.trim();
    }
    if (snapshot.catalog.foreshadows.isEmpty) {
      return '';
    }
    return snapshot.catalog.foreshadows.first.id;
  }

  String _selectedTimelineId(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedTimelineId.trim().isNotEmpty) {
      return snapshot.selectedTimelineId.trim();
    }
    if (snapshot.catalog.timelines.isEmpty) {
      return '';
    }
    return snapshot.catalog.timelines.first.id;
  }

  String _selectedRelationshipId(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedRelationshipId.trim().isNotEmpty) {
      return snapshot.selectedRelationshipId.trim();
    }
    if (snapshot.catalog.relationships.isEmpty) {
      return '';
    }
    return snapshot.catalog.relationships.first.id;
  }

  String _selectedGraphReferenceKey(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedGraphReferenceKey.trim().isNotEmpty) {
      return snapshot.selectedGraphReferenceKey.trim();
    }
    if (snapshot.catalog.referenceIndex.references.isEmpty) {
      return '';
    }
    return snapshot.catalog.referenceIndex.references.first.referenceKey;
  }

  String _kindLabel(String assetKind) {
    switch (assetKind) {
      case 'foreshadow':
        return '伏笔';
      case 'timeline':
        return '时间线';
      case 'relationship':
        return '关系';
      default:
        return assetKind;
    }
  }
}
