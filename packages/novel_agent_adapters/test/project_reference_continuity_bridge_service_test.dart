import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceContinuityBridgeService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectReferenceContinuityBridgeService service;
    late SqliteReferenceEvidenceSubstrate substrate;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-reference-continuity-',
      );
      project = ProjectDescriptor(
        id: 'reference_continuity_project',
        name: '参考连续性项目',
        rootPath: tempDirectory.path,
      );
      service = ProjectReferenceContinuityBridgeService();
      substrate = SqliteReferenceEvidenceSubstrate(
        substrateRootPath:
            '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}reference_extraction${Platform.pathSeparator}substrate',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'buildReport surfaces continuity ledger for mounted reference package',
      () async {
        await substrate.upsertPackageSnapshot(_snapshot());
        await SqliteProjectReferenceAttachmentLayer().upsertAttachment(
          project,
          const ProjectReferenceAttachment(
            attachmentId: 'attach_pkg_reference_v1',
            projectId: 'reference_continuity_project',
            packageId: 'pkg_reference',
            packageVersionId: 'v1',
            visibilityMode: ReferenceVisibilityModes.discoverable,
            accessLevel: ReferenceAccessLevels.manager,
            displayLabel: '示例参考包',
            allowsDiscoveryExpansion: true,
            allowsProjection: true,
            allowsPromotion: true,
            attachedAt: '2026-06-08T12:00:00Z',
          ),
        );
        await substrate.upsertContinuityLedger(_ledger());

        final report = await service.buildReport(project: project);
        final packages = ValueReaders.mapList(report['packages']);
        final package = ValueReaders.mapValue(packages.single);
        final continuitySummary = ValueReaders.mapValue(
          package['continuity_summary'],
        );
        final continuityLedger = ValueReaders.mapValue(
          package['continuity_ledger'],
        );

        expect(
          ValueReaders.stringValue(report['summary']),
          contains('1 个 conflict cluster'),
        );
        expect(packages, hasLength(1));
        expect(
          ValueReaders.stringValue(package['source_of_truth_locator']),
          'reference-package://pkg_reference/v1',
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(package['access'])['allowed'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.intValue(continuitySummary['conflict_cluster_count']),
          1,
        );
        expect(
          ValueReaders.intValue(continuitySummary['review_alert_count']),
          1,
        );
        expect(
          ValueReaders.boolValue(continuitySummary['has_unresolved_conflicts']),
          isTrue,
        );
        expect(
          ValueReaders.mapList(continuityLedger['conflict_clusters']),
          hasLength(1),
        );
        expect(service.buildContextMarkdown(report), contains('哈利的魔杖归属仍需人工确认'));
      },
    );

    test(
      'buildReport keeps confirmation-required attachments blocked',
      () async {
        await substrate.upsertPackageSnapshot(_snapshot());
        await substrate.upsertContinuityLedger(_ledger());
        await SqliteProjectReferenceAttachmentLayer().upsertAttachment(
          project,
          const ProjectReferenceAttachment(
            attachmentId: 'attach_pkg_reference_confirm',
            projectId: 'reference_continuity_project',
            packageId: 'pkg_reference',
            packageVersionId: 'v1',
            visibilityMode: ReferenceVisibilityModes.discoverable,
            accessLevel: ReferenceAccessLevels.manager,
            displayLabel: '待确认参考包',
            allowsDiscoveryExpansion: true,
            allowsProjection: true,
            allowsPromotion: true,
            requiresConfirmation: true,
            attachedAt: '2026-06-08T12:00:00Z',
          ),
        );

        final report = await service.buildReport(project: project);
        final package = ValueReaders.mapValue(
          ValueReaders.mapList(report['packages']).single,
        );

        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(package['access'])['allowed'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(package['access'])['disposition'],
          ),
          ReferenceAccessDispositions.confirmationRequired,
        );
        expect(ValueReaders.mapValue(package['continuity_ledger']), isEmpty);
        expect(
          service.buildContextMarkdown(report),
          contains('explicit_confirmation_required'),
        );
      },
    );

    test(
      'buildReport initializes shortened attachment sqlite path for deep project roots',
      () async {
        final nestedProjectRoot = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}'
          'artifacts${Platform.pathSeparator}'
          'high_fidelity_viewmodel_validation${Platform.pathSeparator}'
          '2026-06-13T17-35-00-lane-g-pendingevidence2${Platform.pathSeparator}'
          'lane_g_general_long_task_stability${Platform.pathSeparator}'
          'workspace${Platform.pathSeparator}'
          'projects${Platform.pathSeparator}'
          'HFVV-07_Lane_G_一般长任务稳定性',
        )..createSync(recursive: true);
        final deepProject = ProjectDescriptor(
          id: 'reference_continuity_deep_project',
          name: '深层参考连续性项目',
          rootPath: nestedProjectRoot.path,
        );
        final pathService = const ProjectReferenceAttachmentSqlitePathService();

        final report = await service.buildReport(project: deepProject);
        final reopenedReport = await service.buildReport(project: deepProject);

        expect(
          ValueReaders.stringValue(report['summary']),
          contains('没有已挂载的参考 continuity 资产'),
        );
        expect(
          ValueReaders.stringValue(reopenedReport['summary']),
          contains('没有已挂载的参考 continuity 资产'),
        );
        expect(
          File(pathService.databasePath(deepProject.rootPath)).existsSync(),
          isTrue,
        );
        expect(
          pathService.databasePath(deepProject.rootPath).length,
          lessThan(pathService.legacyDatabasePath(deepProject.rootPath).length),
        );
      },
    );
  });
}

ReferencePackageSnapshot _snapshot() {
  return const ReferenceSourceDocumentExtractionService()
      .extract(
        const ReferenceSourceDocumentIngestionRequest(
          sourceText: 'CHAPTER ONE\nHarry uses the holly wand.',
          sourceTitle: 'Harry Potter Sample',
          packageId: 'pkg_reference',
          packageKind: 'reference_work_package',
          displayName: '示例参考包',
          packageVersionId: 'v1',
          versionLabel: 'v1',
          createdAt: '2026-06-08T12:00:00Z',
          targetLanguage: 'zh-CN',
        ),
      )
      .snapshot;
}

ReferenceEvidenceContinuityLedger _ledger() {
  return ReferenceEvidenceContinuityLedger(
    packageId: 'pkg_reference',
    packageVersionId: 'v1',
    conflictClusters: <NarrativeConflictCluster>[
      NarrativeConflictCluster.fromJson(<String, Object?>{
        'cluster_id': 'cluster-1',
        'subject_ref': <String, Object?>{
          'ref_type': NarrativeRefTypes.asset,
          'ref_id': 'harry',
        },
        'attribute_key': 'wand_owner',
        'classification': NarrativeConflictClassifications.unexplainedConflict,
        'cluster_status': NarrativeConflictClusterStatuses.needsDecision,
        'summary': '魔杖归属说法不一致。',
        'fact_evidences': <Object?>[
          <String, Object?>{
            'fact_evidence_id': 'fact-1',
            'subject_ref': <String, Object?>{
              'ref_type': NarrativeRefTypes.asset,
              'ref_id': 'harry',
            },
            'attribute_key': 'wand_owner',
            'value_payload': <String, Object?>{'value': 'Harry'},
            'value_summary': 'Harry 持有冬青木魔杖',
            'claim_snapshot': <String, Object?>{
              'claim_id': 'claim-1',
              'subject_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'harry',
              },
              'claim_namespace': 'continuity.character',
              'claim_key': 'wand_owner',
              'claim_value': <String, Object?>{'value': 'Harry'},
            },
            'source': <String, Object?>{
              'source_type': 'reference_package',
              'source_id': 'pkg_reference',
            },
          },
        ],
      }),
    ],
    canonDecisions: <ProjectCanonDecision>[
      ProjectCanonDecision.fromJson(<String, Object?>{
        'decision_id': 'decision-1',
        'cluster_id': 'cluster-1',
        'decision_kind': ProjectCanonDecisionKinds.deferUnresolved,
        'decided_at': '2026-06-08T12:10:00Z',
        'review_required': true,
      }),
    ],
    reviewAlerts: <ContinuityReviewAlert>[
      ContinuityReviewAlert.fromJson(<String, Object?>{
        'alert_id': 'alert-1',
        'cluster_id': 'cluster-1',
        'alert_kind': ContinuityReviewAlertKinds.unresolvedConflict,
        'severity': ContinuityReviewAlertSeverities.high,
        'summary': '哈利的魔杖归属仍需人工确认。',
        'requires_manual_review': true,
        'source': <String, Object?>{
          'source_type': 'reference_package',
          'source_id': 'pkg_reference',
        },
      }),
    ],
    updatedAt: '2026-06-08T12:15:00Z',
  );
}
