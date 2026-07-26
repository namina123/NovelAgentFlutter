import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectReferenceAlignmentSummaryService {
  const ProjectReferenceAlignmentSummaryService();

  static const String summaryRelativePath = 'knowledge/项目资料总览.md';

  String buildMarkdown({
    required ProjectDescriptor project,
    required ProjectReferenceAttachment attachment,
    required ReferencePackageRecord packageRecord,
    required ReferencePackageVersionRecord packageVersionRecord,
    required InformationProjectionDraftBundle bundle,
  }) {
    // 中文注释: 对齐摘要只讲“项目资料有哪些层、这些层如何和参考资产库对应”，不把底层提取运行时重新摊开。
    final summaryItems = <_ReferenceAlignmentSummaryItem>[
      ...bundle.knowledgeCardDrafts.map(
        (card) => _ReferenceAlignmentSummaryItem.fromKnowledgeCard(card),
      ),
      ...bundle.designElementDrafts.map(
        (card) => _ReferenceAlignmentSummaryItem.fromDesignElement(card),
      ),
      ...bundle.researchNoteDrafts.map(
        (note) => _ReferenceAlignmentSummaryItem.fromResearchNote(note),
      ),
      ...bundle.referenceWorkDrafts.map(
        (record) => _ReferenceAlignmentSummaryItem.fromReferenceWork(record),
      ),
    ]..sort(_compareSummaryItems);
    final groupedByState = <String, List<_ReferenceAlignmentSummaryItem>>{};
    for (final item in summaryItems) {
      groupedByState
          .putIfAbsent(item.stateId, () => <_ReferenceAlignmentSummaryItem>[])
          .add(item);
    }
    final stateOrder = <String>[
      _ReferenceAlignmentStateProfiles.projectPrivateDraft.id,
      _ReferenceAlignmentStateProfiles.pendingReview.id,
      _ReferenceAlignmentStateProfiles.promotableFormal.id,
    ];
    final stateProfiles = <String, _ReferenceAlignmentStateProfiles>{
      for (final profile in _ReferenceAlignmentStateProfiles.valuesList)
        profile.id: profile,
    };
    final yamlWriter = const FrontmatterYamlWriterService();
    final lines = <String>[
      '---',
      yamlWriter.write(<String, Object?>{
        'projection_id': 'project_reference_alignment_summary',
        'title': '项目资料总览',
        'projection_only': true,
        'source_of_truth_paths': <String>[
          InformationProjectionDocument.knowledgeSummaryRelativePath,
          InformationProjectionDocument.designSummaryRelativePath,
          InformationProjectionDocument.researchSummaryRelativePath,
          InformationProjectionDocument.referenceBoundaryRelativePath,
        ],
      }).trimRight(),
      '---',
      '# 项目资料总览',
      '',
      '> 这是一份 SQLite 项目资料对齐摘要，只讲项目资料如何和参考资产库、项目资料挂载对齐，不是数据库浏览器。',
      '> 术语口径固定为：项目资料、项目资料挂载、参考资产库。',
      '',
      '## 对齐概览',
      '',
      '- 项目：${project.name}',
      '- 项目类型：${project.projectType}',
      '- 主存储策略：${project.storageStrategy.id}',
      '- 参考资产库：${packageRecord.displayName}',
      '- 参考包版本：${packageVersionRecord.versionLabel.isEmpty ? packageVersionRecord.packageVersionId : packageVersionRecord.versionLabel}',
      '- 项目资料挂载：${_attachmentLabel(attachment, packageRecord)}',
      '- 条目总数：${summaryItems.length}',
      '- 私有草稿数：${_countForState(summaryItems, _ReferenceAlignmentStateProfiles.projectPrivateDraft.id)}',
      '- 待审核数：${_countForState(summaryItems, _ReferenceAlignmentStateProfiles.pendingReview.id)}',
      '- 可提升正式资产数：${_countForState(summaryItems, _ReferenceAlignmentStateProfiles.promotableFormal.id)}',
      '',
      '## 术语口径',
      '',
      '- `项目资料`：项目内当前可见、可分层整理的资料事实。',
      '- `项目资料挂载`：项目内对参考资产库的挂载视图与访问边界。',
      '- `参考资产库`：应用级正式参考资产事实源。',
      '',
    ];
    for (final stateId in stateOrder) {
      final profile = stateProfiles[stateId]!;
      final items =
          groupedByState[stateId] ?? const <_ReferenceAlignmentSummaryItem>[];
      lines.addAll(<String>[
        '## ${profile.label}',
        '',
        '- 状态说明：${profile.detail}',
        '- 条目数：${items.length}',
        '',
      ]);
      if (items.isEmpty) {
        lines.add('- 暂无此层条目。');
        lines.add('');
        continue;
      }
      for (final item in items) {
        lines.addAll(<String>[
          '### ${item.title}',
          '',
          '- 类型：${item.kindLabel}',
          '- 生命周期：`${item.lifecycleStatus}`',
          '- 对齐层：${item.stateLabel}',
          '- 对齐层说明：${item.stateDetail}',
          '- 项目资料：${item.projectSurfaceLabel}',
          '- 项目资料挂载：${item.projectMountLabel}',
          '- 参考资产库：${item.referenceLibraryLabel}',
          '- 来源：${item.sourceDetails}',
          '- 摘要：${item.summary.isEmpty ? '无' : item.summary}',
          '',
        ]);
      }
    }
    return lines.join('\n').trimRight() + '\n';
  }

  String _attachmentLabel(
    ProjectReferenceAttachment attachment,
    ReferencePackageRecord packageRecord,
  ) {
    // 中文注释: 挂载标签只展示最小可理解组合，避免把 attachmentId 之类内部键直接暴露成主文案。
    final label = attachment.displayLabel.trim().isEmpty
        ? packageRecord.displayName
        : attachment.displayLabel.trim();
    final access = attachment.accessLevel.trim().isEmpty
        ? 'access:none'
        : attachment.accessLevel.trim();
    return '$label / $access';
  }

  int _countForState(
    List<_ReferenceAlignmentSummaryItem> items,
    String stateId,
  ) {
    return items.where((item) => item.stateId == stateId).length;
  }

  int _compareSummaryItems(
    _ReferenceAlignmentSummaryItem left,
    _ReferenceAlignmentSummaryItem right,
  ) {
    final stateOrder = _ReferenceAlignmentStateProfiles.valuesList
        .map((profile) => profile.id)
        .toList(growable: false);
    final leftStateIndex = stateOrder.indexOf(left.stateId);
    final rightStateIndex = stateOrder.indexOf(right.stateId);
    final stateCompare = leftStateIndex.compareTo(rightStateIndex);
    if (stateCompare != 0) {
      return stateCompare;
    }
    final kindCompare = left.kindLabel.compareTo(right.kindLabel);
    if (kindCompare != 0) {
      return kindCompare;
    }
    return left.title.compareTo(right.title);
  }
}

class _ReferenceAlignmentSummaryItem {
  const _ReferenceAlignmentSummaryItem({
    required this.title,
    required this.kindLabel,
    required this.summary,
    required this.lifecycleStatus,
    required this.stateId,
    required this.stateLabel,
    required this.stateDetail,
    required this.projectSurfaceLabel,
    required this.projectMountLabel,
    required this.referenceLibraryLabel,
    required this.sourceDetails,
  });

  factory _ReferenceAlignmentSummaryItem.fromKnowledgeCard(
    ProjectKnowledgeCard card,
  ) {
    final state = _ReferenceAlignmentStateProfiles.fromLifecycleStatus(
      card.lifecycleStatus,
      card.metadata,
    );
    return _ReferenceAlignmentSummaryItem(
      title: card.title.trim().isEmpty ? card.cardId : card.title.trim(),
      kindLabel: '知识卡',
      summary: card.summary.trim(),
      lifecycleStatus: card.lifecycleStatus,
      stateId: state.id,
      stateLabel: state.label,
      stateDetail: state.detail,
      projectSurfaceLabel: ValueReaders.stringValue(
        card.metadata['project_surface_label'],
      ).trim(),
      projectMountLabel: ValueReaders.stringValue(
        card.metadata['project_mount_label'],
      ).trim(),
      referenceLibraryLabel: ValueReaders.stringValue(
        card.metadata['reference_library_label'],
      ).trim(),
      sourceDetails: _sourceDetailsFromInformationRefs(card.sourceRefs),
    );
  }

  factory _ReferenceAlignmentSummaryItem.fromDesignElement(
    DesignElementCard card,
  ) {
    final state = _ReferenceAlignmentStateProfiles.fromLifecycleStatus(
      card.lifecycleStatus,
      card.metadata,
    );
    return _ReferenceAlignmentSummaryItem(
      title: card.designLabel.trim().isEmpty
          ? card.designId
          : card.designLabel.trim(),
      kindLabel: '设计元素',
      summary: card.uncertainty.trim(),
      lifecycleStatus: card.lifecycleStatus,
      stateId: state.id,
      stateLabel: state.label,
      stateDetail: state.detail,
      projectSurfaceLabel: ValueReaders.stringValue(
        card.metadata['project_surface_label'],
      ).trim(),
      projectMountLabel: ValueReaders.stringValue(
        card.metadata['project_mount_label'],
      ).trim(),
      referenceLibraryLabel: ValueReaders.stringValue(
        card.metadata['reference_library_label'],
      ).trim(),
      sourceDetails: _sourceDetailsFromInformationRefs(card.sourceRefs),
    );
  }

  factory _ReferenceAlignmentSummaryItem.fromResearchNote(ResearchNote note) {
    final state = _ReferenceAlignmentStateProfiles.fromLifecycleStatus(
      note.metadata['lifecycle_status']?.toString() ?? '',
      note.metadata,
    );
    return _ReferenceAlignmentSummaryItem(
      title: note.query.trim().isEmpty ? note.researchId : note.query.trim(),
      kindLabel: '研究笔记',
      summary: note.summary.trim(),
      lifecycleStatus: state.lifecycleStatus,
      stateId: state.id,
      stateLabel: state.label,
      stateDetail: state.detail,
      projectSurfaceLabel: ValueReaders.stringValue(
        note.metadata['project_surface_label'],
      ).trim(),
      projectMountLabel: ValueReaders.stringValue(
        note.metadata['project_mount_label'],
      ).trim(),
      referenceLibraryLabel: ValueReaders.stringValue(
        note.metadata['reference_library_label'],
      ).trim(),
      sourceDetails:
          '${note.sourceKind} / ${note.sourceUrlOrRef.trim().isEmpty ? '无来源定位' : note.sourceUrlOrRef.trim()}',
    );
  }

  factory _ReferenceAlignmentSummaryItem.fromReferenceWork(
    ReferenceWorkRecord record,
  ) {
    final state = _ReferenceAlignmentStateProfiles.fromLifecycleStatus(
      record.metadata['lifecycle_status']?.toString() ?? '',
      record.metadata,
    );
    return _ReferenceAlignmentSummaryItem(
      title: record.title.trim().isEmpty
          ? record.referenceWorkId
          : record.title.trim(),
      kindLabel: '引用作品',
      summary: record.declaredUsageIntent.trim(),
      lifecycleStatus: state.lifecycleStatus,
      stateId: state.id,
      stateLabel: state.label,
      stateDetail: state.detail,
      projectSurfaceLabel: ValueReaders.stringValue(
        record.metadata['project_surface_label'],
      ).trim(),
      projectMountLabel: ValueReaders.stringValue(
        record.metadata['project_mount_label'],
      ).trim(),
      referenceLibraryLabel: ValueReaders.stringValue(
        record.metadata['reference_library_label'],
      ).trim(),
      sourceDetails: _sourceDetailsFromInformationRefs(record.sourceRefs),
    );
  }

  final String title;
  final String kindLabel;
  final String summary;
  final String lifecycleStatus;
  final String stateId;
  final String stateLabel;
  final String stateDetail;
  final String projectSurfaceLabel;
  final String projectMountLabel;
  final String referenceLibraryLabel;
  final String sourceDetails;
}

enum _ReferenceAlignmentStateProfiles {
  projectPrivateDraft(
    id: 'project_private_draft',
    label: '项目私有草稿资产',
    detail: '当前只在项目内使用，尚未进入审核或提升流程。',
  ),
  pendingReview(
    id: 'pending_review',
    label: '待审核资产',
    detail: '已进入审核路径，但还不宜直接作为正式资产对外提升。',
  ),
  promotableFormal(
    id: 'promotable_formal',
    label: '可提升到参考资产库的正式资产',
    detail: '已具备对外提升或正式挂载的成熟状态。',
  );

  const _ReferenceAlignmentStateProfiles({
    required this.id,
    required this.label,
    required this.detail,
  });

  final String id;
  final String label;
  final String detail;

  String get lifecycleStatus => id;

  static const List<_ReferenceAlignmentStateProfiles> valuesList =
      <_ReferenceAlignmentStateProfiles>[
        projectPrivateDraft,
        pendingReview,
        promotableFormal,
      ];

  static _ReferenceAlignmentStateProfiles fromLifecycleStatus(
    String lifecycleStatus,
    Map<String, Object?> metadata,
  ) {
    final normalized = lifecycleStatus.trim().toLowerCase();
    final metadataState = ValueReaders.stringValue(
      metadata['project_visibility_state'],
    ).trim();
    final candidate = metadataState.isNotEmpty ? metadataState : normalized;
    for (final profile in valuesList) {
      if (profile.id == candidate) {
        return profile;
      }
    }
    if (candidate.isEmpty ||
        candidate == 'draft' ||
        candidate == 'staged' ||
        candidate == 'working') {
      return projectPrivateDraft;
    }
    if (candidate == 'proposed' ||
        candidate == 'pending_review' ||
        candidate == 'under_review' ||
        candidate == 'review' ||
        candidate == 'reviewing') {
      return pendingReview;
    }
    if (candidate == 'accepted' ||
        candidate == 'active' ||
        candidate == 'confirmed' ||
        candidate == 'published' ||
        candidate == 'finalized' ||
        candidate == 'promoted') {
      return promotableFormal;
    }
    return projectPrivateDraft;
  }
}

String _sourceDetailsFromInformationRefs(
  List<InformationSourceRef> sourceRefs,
) {
  // 中文注释: 来源详情只保留最小可理解标签，方便 summary 快速回跳，不把整条 source ref 结构摊开。
  if (sourceRefs.isEmpty) {
    return '无来源引用';
  }
  return sourceRefs
      .map((ref) {
        final identity = ref.sourceIdentity;
        final label = identity.displayName.trim().isNotEmpty
            ? identity.displayName.trim()
            : identity.sourceAssetId.trim();
        final kind = identity.sourceKind.trim();
        if (kind.isEmpty) {
          return label;
        }
        return '$label / kind:$kind';
      })
      .where((item) => item.trim().isNotEmpty)
      .join('；');
}
