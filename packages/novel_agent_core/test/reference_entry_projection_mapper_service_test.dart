import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceEntryProjectionMapperService', () {
    test('attaches project visibility metadata for downstream alignment summaries', () {
      // 中文注释: 这里锁住项目资料层的元数据口径，确保 summary / projection / probe 能复用同一份状态标签。
      const mapper = ReferenceEntryProjectionMapperService();
      final bundle = mapper.buildDraftBundle(
        packageRecord: _packageRecord(),
        packageVersionRecord: _packageVersionRecord(),
        entries: <ReferenceEntryRecord>[
          _draftEntry(),
          _reviewEntry(),
          _researchEntry(),
          _formalEntry(),
        ],
      );

      final knowledgeCard = bundle.knowledgeCardDrafts.single;
      expect(
        knowledgeCard.metadata['project_surface_label'],
        '项目资料',
      );
      expect(
        knowledgeCard.metadata['project_mount_label'],
        '项目资料挂载',
      );
      expect(
        knowledgeCard.metadata['reference_library_label'],
        '参考资产库',
      );
      expect(
        knowledgeCard.metadata['project_visibility_state_label'],
        '项目私有草稿资产',
      );

      final designElement = bundle.designElementDrafts.single;
      expect(
        designElement.metadata['project_visibility_state_label'],
        '待审核资产',
      );

      final researchNote = bundle.researchNoteDrafts.single;
      expect(
        researchNote.metadata['project_visibility_state_label'],
        '可提升到参考资产库的正式资产',
      );

      final referenceWork = bundle.referenceWorkDrafts.single;
      expect(
        referenceWork.metadata['project_visibility_state_label'],
        '可提升到参考资产库的正式资产',
      );
    });
  });
}

ReferencePackageRecord _packageRecord() {
  return const ReferencePackageRecord(
    packageId: 'pkg_reference',
    packageKind: ReferencePackageKinds.referenceWorkPackage,
    displayName: '参考资产库包',
    packageNamespace: 'reference',
    description: '资料知识库对齐包',
    latestVersionId: 'v1',
    lifecycleStatus: 'active',
    createdAt: '2026-06-14T08:00:00Z',
    updatedAt: '2026-06-14T08:00:00Z',
  );
}

ReferencePackageVersionRecord _packageVersionRecord() {
  return const ReferencePackageVersionRecord(
    packageVersionId: 'v1',
    packageId: 'pkg_reference',
    versionLabel: '2026.06',
    createdAt: '2026-06-14T08:00:00Z',
    createdBy: 'tester',
  );
}

ReferenceEntryRecord _draftEntry() {
  return ReferenceEntryRecord(
    entryId: 'entry_draft',
    packageId: 'pkg_reference',
    packageVersionId: 'v1',
    entryNamespace: 'project',
    entryKind: ReferenceEntryKinds.knowledgeFact,
    title: '项目私有草稿条目',
    summary: '尚未进入审核流程。',
    payload: const <String, Object?>{'status': 'draft'},
    sourceRefs: <InformationSourceRef>[_sourceRef()],
    activationPolicy: const InformationActivationPolicy(
      activationPriority: InformationActivationPriorities.normal,
    ),
    usagePolicy: const InformationUsagePolicy(
      usageMode: InformationUsageModes.normal,
      citationRiskLevel: InformationCitationRiskLevels.low,
    ),
    confidence: 0.82,
    lifecycleStatus: 'draft',
  );
}

ReferenceEntryRecord _reviewEntry() {
  return ReferenceEntryRecord(
    entryId: 'entry_review',
    packageId: 'pkg_reference',
    packageVersionId: 'v1',
    entryNamespace: 'project',
    entryKind: ReferenceEntryKinds.designElement,
    title: '待审核设计元素',
    summary: '需要人工复核后再提升。',
    payload: const <String, Object?>{'status': 'review'},
    sourceRefs: <InformationSourceRef>[_sourceRef()],
    activationPolicy: const InformationActivationPolicy(
      activationPriority: InformationActivationPriorities.reference,
    ),
    usagePolicy: const InformationUsagePolicy(
      usageMode: InformationUsageModes.referenceOnly,
      citationRiskLevel: InformationCitationRiskLevels.normal,
    ),
    confidence: 0.86,
    lifecycleStatus: 'under_review',
  );
}

ReferenceEntryRecord _formalEntry() {
  return ReferenceEntryRecord(
    entryId: 'entry_formal',
    packageId: 'pkg_reference',
    packageVersionId: 'v1',
    entryNamespace: 'project',
    entryKind: ReferenceEntryKinds.referenceWorkBoundary,
    title: '可提升正式边界',
    summary: '已具备正式挂载或提升条件。',
    payload: const <String, Object?>{'status': 'formal'},
    sourceRefs: <InformationSourceRef>[_sourceRef()],
    activationPolicy: const InformationActivationPolicy(
      activationPriority: InformationActivationPriorities.required,
    ),
    usagePolicy: const InformationUsagePolicy(
      usageMode: InformationUsageModes.referenceOnly,
      citationRiskLevel: InformationCitationRiskLevels.normal,
    ),
    confidence: 0.94,
    lifecycleStatus: 'confirmed',
  );
}

ReferenceEntryRecord _researchEntry() {
  return ReferenceEntryRecord(
    entryId: 'entry_research',
    packageId: 'pkg_reference',
    packageVersionId: 'v1',
    entryNamespace: 'project',
    entryKind: ReferenceEntryKinds.researchNote,
    title: '研究笔记条目',
    summary: '可提升到正式资产的研究记录。',
    payload: const <String, Object?>{'status': 'research'},
    sourceRefs: <InformationSourceRef>[_sourceRef()],
    activationPolicy: const InformationActivationPolicy(
      activationPriority: InformationActivationPriorities.reference,
    ),
    usagePolicy: const InformationUsagePolicy(
      usageMode: InformationUsageModes.referenceOnly,
      citationRiskLevel: InformationCitationRiskLevels.normal,
    ),
    confidence: 0.9,
    lifecycleStatus: 'active',
  );
}

InformationSourceRef _sourceRef() {
  return const InformationSourceRef(
    sourceRef: NarrativeSourceRef(
      sourceType: 'imported_book',
      sourceId: 'reference_package_v1',
      label: '参考包来源',
    ),
    sourceAuthority: InformationSourceAuthorities.sourceDocument,
    roleAuthority: InformationRoleAuthorities.deconstructor,
    researchDepth: InformationResearchDepths.standard,
  );
}
