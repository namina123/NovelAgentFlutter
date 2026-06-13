import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Reference substrate contracts', () {
    test('access policy blocks projection for summary only attachment', () {
      const service = ProjectReferenceAccessPolicyService();
      const attachment = ProjectReferenceAttachment(
        attachmentId: 'attach-1',
        projectId: 'project-1',
        packageId: 'pkg-hp',
        packageVersionId: 'v1',
        visibilityMode: ReferenceVisibilityModes.discoverable,
        accessLevel: ReferenceAccessLevels.summaryOnly,
        allowsProjection: false,
      );

      final decision = service.decide(
        request: const ProjectReferenceAccessRequest(
          projectId: 'project-1',
          packageId: 'pkg-hp',
          packageVersionId: 'v1',
          operation: ReferenceAccessOperations.projectEntry,
        ),
        attachment: attachment,
      );

      expect(decision.allowed, isFalse);
      expect(decision.disposition, ReferenceAccessDispositions.denied);
      expect(decision.reasonCode, 'projection_denied');
    });

    test('projection mapper splits knowledge and design targets', () {
      const mapper = ReferenceEntryProjectionMapperService();
      final packageRecord = ReferencePackageRecord(
        packageId: 'pkg-hp',
        packageKind: ReferencePackageKinds.referenceWorkPackage,
        displayName: '哈利波特原作包',
        latestVersionId: 'v1',
      );
      final versionRecord = ReferencePackageVersionRecord(
        packageVersionId: 'v1',
        packageId: 'pkg-hp',
        versionLabel: '2026.06',
      );
      final sourceRef = InformationSourceRef(
        sourceRef: const NarrativeSourceRef(
          sourceType: 'imported_book',
          sourceId: 'hp-001',
          label: '原作片段',
        ),
        sourceAuthority: InformationSourceAuthorities.sourceDocument,
        roleAuthority: InformationRoleAuthorities.deconstructor,
        researchDepth: InformationResearchDepths.deep,
      );
      final entries = <ReferenceEntryRecord>[
        ReferenceEntryRecord(
          entryId: 'entry-fact',
          packageId: 'pkg-hp',
          packageVersionId: 'v1',
          entryNamespace: 'wizarding_world',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '魔杖选择巫师',
          summary: '奥利凡德强调魔杖选择巫师。',
          payload: const <String, Object?>{'fact': 'wand chooses wizard'},
          sourceRefs: <InformationSourceRef>[sourceRef],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.required,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.normal,
          ),
          lifecycleStatus: 'active',
          confidence: 0.95,
        ),
        ReferenceEntryRecord(
          entryId: 'entry-style',
          packageId: 'pkg-hp',
          packageVersionId: 'v1',
          entryNamespace: 'narrative_style',
          entryKind: ReferenceEntryKinds.styleTechnique,
          title: '儿童视角的奇观递进',
          summary: '先惊奇后扩展世界边界。',
          payload: const <String, Object?>{'technique': 'wonder escalation'},
          sourceRefs: <InformationSourceRef>[sourceRef],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.reference,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.referenceOnly,
            citationRiskLevel: InformationCitationRiskLevels.normal,
          ),
          lifecycleStatus: 'active',
          confidence: 0.82,
        ),
      ];

      final bundle = mapper.buildDraftBundle(
        packageRecord: packageRecord,
        packageVersionRecord: versionRecord,
        entries: entries,
      );

      expect(bundle.knowledgeCardDrafts, hasLength(1));
      expect(bundle.designElementDrafts, hasLength(1));
      expect(bundle.knowledgeCardDrafts.first.cardId, 'ref_entry-fact');
      expect(bundle.designElementDrafts.first.designId, 'ref_entry-style');
      expect(
        bundle
            .knowledgeCardDrafts
            .first
            .sourceRefs
            .first
            .sourceIdentity
            .resolverUri,
        'reference-entry://pkg-hp/v1/entry-fact',
      );
    });

    test('promotion mapper preserves explicit promotion audit', () {
      const mapper = ProjectInformationPromotionMapperService();
      final snapshot = mapper.buildSnapshotForKnowledgeCard(
        const ReferencePromotionRequest(
          packageId: 'pkg-tech',
          packageKind: ReferencePackageKinds.domainEvidencePackage,
          displayName: '工业化依据包',
          packageVersionId: 'v1',
          versionLabel: '1.0.0',
          sourceProjectId: 'project-tech',
          sourceArtifactKind: ProjectInformationArtifactKinds.knowledgeCard,
          sourceArtifactId: 'card-steam',
          promotedAt: '2026-06-07T12:00:00Z',
          promotedBy: 'tester',
        ),
        ProjectKnowledgeCard(
          cardId: 'card-steam',
          cardNamespace: 'industry',
          cardType: 'technology_fact',
          title: '蒸汽机推广依赖煤炭供应',
          summary: '煤矿与运输体系决定扩散速度。',
          contentPayload: const <String, Object?>{
            'fact': 'coal supply matters',
          },
          sourceRefs: <InformationSourceRef>[
            InformationSourceRef(
              sourceRef: const NarrativeSourceRef(
                sourceType: 'research_note',
                sourceId: 'rn-001',
              ),
              sourceAuthority: InformationSourceAuthorities.externalResearched,
              roleAuthority: InformationRoleAuthorities.researcher,
              researchDepth: InformationResearchDepths.deep,
            ),
          ],
          activationPolicy: const InformationActivationPolicy(
            activationPriority: InformationActivationPriorities.normal,
          ),
          usagePolicy: const InformationUsagePolicy(
            usageMode: InformationUsageModes.normal,
            citationRiskLevel: InformationCitationRiskLevels.low,
          ),
          confidence: 0.9,
          lifecycleStatus: 'confirmed',
        ),
      );

      expect(snapshot.entries, hasLength(1));
      expect(snapshot.promotionRecords, hasLength(1));
      expect(snapshot.entries.first.packageId, 'pkg-tech');
      expect(snapshot.promotionRecords.first.sourceArtifactId, 'card-steam');
    });
  });
}
