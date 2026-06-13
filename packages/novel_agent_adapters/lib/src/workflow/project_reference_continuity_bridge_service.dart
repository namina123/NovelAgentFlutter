import 'package:novel_agent_core/novel_agent_core.dart';

import '../reference_extraction/project_reference_extraction_path_service.dart';
import '../storage/sqlite_project_reference_attachment_layer.dart';
import '../storage/sqlite_reference_evidence_substrate.dart';

typedef CreateProjectReferenceEvidenceSubstrate =
    ReferenceEvidenceSubstrate Function(ProjectDescriptor project);

class ProjectReferenceContinuityBridgeService {
  ProjectReferenceContinuityBridgeService({
    ProjectReferenceAttachmentLayer? attachmentLayer,
    ProjectReferenceAccessPolicyService? accessPolicyService,
    ProjectReferenceExtractionPathService? pathService,
    CreateProjectReferenceEvidenceSubstrate? substrateFactory,
  }) : _attachmentLayer =
           attachmentLayer ?? SqliteProjectReferenceAttachmentLayer(),
       _accessPolicyService =
           accessPolicyService ?? const ProjectReferenceAccessPolicyService(),
       _pathService = pathService ?? ProjectReferenceExtractionPathService(),
       _substrateFactory =
           substrateFactory ??
           _defaultSubstrateFactory(
             pathService ?? ProjectReferenceExtractionPathService(),
           );

  final ProjectReferenceAttachmentLayer _attachmentLayer;
  final ProjectReferenceAccessPolicyService _accessPolicyService;
  final ProjectReferenceExtractionPathService _pathService;
  final CreateProjectReferenceEvidenceSubstrate _substrateFactory;

  Future<ReferenceEvidenceContinuityLedger> ensureLedger({
    required ReferenceEvidenceSubstrate substrate,
    required String packageId,
    required String packageVersionId,
    String updatedAt = '',
    JsonMap metadata = const <String, Object?>{},
  }) async {
    final existing = await substrate.readContinuityLedger(
      packageId: packageId,
      packageVersionId: packageVersionId,
    );
    if (existing != null) {
      return existing;
    }
    final ledger = ReferenceEvidenceContinuityLedger(
      packageId: packageId,
      packageVersionId: packageVersionId,
      updatedAt: updatedAt,
      metadata: metadata,
    );
    await substrate.upsertContinuityLedger(ledger);
    return ledger;
  }

  Future<JsonMap> buildReport({
    required ProjectDescriptor project,
    bool explicitConfirmationGranted = false,
  }) async {
    final attachments = await _attachmentLayer.listAttachments(project);
    if (attachments.isEmpty) {
      return <String, Object?>{
        'summary': '项目当前没有已挂载的参考 continuity 资产。',
        'packages': const <JsonMap>[],
        'metadata': <String, Object?>{
          'project_id': project.id,
          'project_name': project.name,
          'substrate_locator':
              'reference-substrate://${project.id}/continuity',
          'attachment_count': 0,
          'readable_package_count': 0,
          'blocked_package_count': 0,
          'conflict_cluster_count': 0,
          'canon_decision_count': 0,
          'review_alert_count': 0,
          'packages_requiring_manual_review_count': 0,
          'packages_with_unresolved_conflicts_count': 0,
        },
      };
    }

    final substrate = _substrateFactory(project);
    final packageReports = <JsonMap>[];
    for (final attachment in attachments) {
      final accessDecision = _accessPolicyService.decide(
        request: ProjectReferenceAccessRequest(
          projectId: project.id,
          packageId: attachment.packageId,
          packageVersionId: attachment.packageVersionId,
          operation: ReferenceAccessOperations.readPackageSummary,
          explicitConfirmationGranted: explicitConfirmationGranted,
        ),
        attachment: attachment,
      );
      ReferencePackageRecord? packageRecord;
      ReferenceEvidenceContinuityLedger? ledger;
      if (accessDecision.allowed) {
        packageRecord = await substrate.readPackage(attachment.packageId);
        ledger = await substrate.readContinuityLedger(
          packageId: attachment.packageId,
          packageVersionId: attachment.packageVersionId,
        );
      }
      packageReports.add(
        _packageReport(
          attachment: attachment,
          accessDecision: accessDecision,
          packageRecord: packageRecord,
          ledger: ledger,
        ),
      );
    }

    packageReports.sort((left, right) {
      final leftManual = ValueReaders.intValue(
        ValueReaders.mapValue(
          left['continuity_summary'],
        )['manual_review_count'],
      );
      final rightManual = ValueReaders.intValue(
        ValueReaders.mapValue(
          right['continuity_summary'],
        )['manual_review_count'],
      );
      if (leftManual != rightManual) {
        return rightManual.compareTo(leftManual);
      }
      final leftAlerts = ValueReaders.intValue(
        ValueReaders.mapValue(left['continuity_summary'])['review_alert_count'],
      );
      final rightAlerts = ValueReaders.intValue(
        ValueReaders.mapValue(
          right['continuity_summary'],
        )['review_alert_count'],
      );
      if (leftAlerts != rightAlerts) {
        return rightAlerts.compareTo(leftAlerts);
      }
      return ValueReaders.stringValue(
        left['display_label'],
      ).compareTo(ValueReaders.stringValue(right['display_label']));
    });

    final readablePackageCount = packageReports
        .where(
          (item) => ValueReaders.boolValue(
            ValueReaders.mapValue(item['access'])['allowed'],
          ),
        )
        .length;
    final blockedPackageCount = packageReports.length - readablePackageCount;
    final conflictClusterCount = _sumCount(
      packageReports,
      summaryKey: 'conflict_cluster_count',
    );
    final canonDecisionCount = _sumCount(
      packageReports,
      summaryKey: 'canon_decision_count',
    );
    final reviewAlertCount = _sumCount(
      packageReports,
      summaryKey: 'review_alert_count',
    );
    final manualReviewPackageCount = packageReports
        .where(
          (item) =>
              ValueReaders.intValue(
                ValueReaders.mapValue(
                  item['continuity_summary'],
                )['manual_review_count'],
              ) >
              0,
        )
        .length;
    final unresolvedPackageCount = packageReports
        .where(
          (item) => ValueReaders.boolValue(
            ValueReaders.mapValue(
              item['continuity_summary'],
            )['has_unresolved_conflicts'],
          ),
        )
        .length;

    return <String, Object?>{
      'summary': _buildSummary(
        attachmentCount: packageReports.length,
        readablePackageCount: readablePackageCount,
        blockedPackageCount: blockedPackageCount,
        conflictClusterCount: conflictClusterCount,
        canonDecisionCount: canonDecisionCount,
        reviewAlertCount: reviewAlertCount,
        manualReviewPackageCount: manualReviewPackageCount,
        unresolvedPackageCount: unresolvedPackageCount,
      ),
      'packages': packageReports,
      'metadata': <String, Object?>{
        'project_id': project.id,
        'project_name': project.name,
        'substrate_locator': 'reference-substrate://${project.id}/continuity',
        'attachment_count': packageReports.length,
        'readable_package_count': readablePackageCount,
        'blocked_package_count': blockedPackageCount,
        'conflict_cluster_count': conflictClusterCount,
        'canon_decision_count': canonDecisionCount,
        'review_alert_count': reviewAlertCount,
        'packages_requiring_manual_review_count': manualReviewPackageCount,
        'packages_with_unresolved_conflicts_count': unresolvedPackageCount,
      },
    };
  }

  String buildContextMarkdown(
    JsonMap report, {
    int maxPackages = 4,
    int maxAlertsPerPackage = 2,
  }) {
    final lines = <String>[
      '## Mounted Reference Continuity',
      '- summary: ${ValueReaders.stringValue(report['summary'])}',
    ];
    final packages = ValueReaders.mapList(report['packages']);
    final interestingPackages = packages
        .where((item) {
          final access = ValueReaders.mapValue(item['access']);
          if (!ValueReaders.boolValue(access['allowed'])) {
            return true;
          }
          final continuitySummary = ValueReaders.mapValue(
            item['continuity_summary'],
          );
          return ValueReaders.intValue(
                    continuitySummary['review_alert_count'],
                  ) >
                  0 ||
              ValueReaders.intValue(
                    continuitySummary['conflict_cluster_count'],
                  ) >
                  0;
        })
        .take(maxPackages);
    for (final item in interestingPackages) {
      final displayLabel = ValueReaders.stringValue(
        item['display_label'],
        ValueReaders.stringValue(item['package_id']),
      );
      final locator = ValueReaders.stringValue(item['source_of_truth_locator']);
      final access = ValueReaders.mapValue(item['access']);
      if (!ValueReaders.boolValue(access['allowed'])) {
        lines.add(
          '- $displayLabel${locator.trim().isEmpty ? '' : ' <$locator>'}: access=${ValueReaders.stringValue(access['disposition'])}${ValueReaders.stringValue(access['reason_code']).trim().isEmpty ? '' : ' (${ValueReaders.stringValue(access['reason_code'])})'}',
        );
        continue;
      }
      final continuitySummary = ValueReaders.mapValue(
        item['continuity_summary'],
      );
      lines.add(
        '- $displayLabel${locator.trim().isEmpty ? '' : ' <$locator>'}: conflicts=${ValueReaders.intValue(continuitySummary['conflict_cluster_count'])}, decisions=${ValueReaders.intValue(continuitySummary['canon_decision_count'])}, alerts=${ValueReaders.intValue(continuitySummary['review_alert_count'])}',
      );
      final reviewAlerts = ValueReaders.mapList(
        ValueReaders.mapValue(item['continuity_ledger'])['review_alerts'],
      ).take(maxAlertsPerPackage);
      for (final alert in reviewAlerts) {
        final alertKind = ValueReaders.stringValue(alert['alert_kind']);
        final severity = ValueReaders.stringValue(alert['severity']);
        final summary = ValueReaders.stringValue(alert['summary']);
        lines.add(
          '  - [$severity/$alertKind] ${summary.isEmpty ? '待补充 continuity alert 摘要' : summary}',
        );
      }
    }
    if (lines.length == 2) {
      lines.add(
        '- no continuity conflicts detected in mounted reference packages.',
      );
    }
    return lines.join('\n');
  }

  JsonMap _packageReport({
    required ProjectReferenceAttachment attachment,
    required ProjectReferenceAccessDecision accessDecision,
    required ReferencePackageRecord? packageRecord,
    required ReferenceEvidenceContinuityLedger? ledger,
  }) {
    final continuitySummary = _continuitySummary(ledger);
    return <String, Object?>{
      'package_id': attachment.packageId,
      'package_version_id': attachment.packageVersionId,
      'display_label': attachment.displayLabel.trim().isEmpty
          ? (packageRecord?.displayName.trim().isEmpty ?? true)
                ? attachment.packageId
                : packageRecord!.displayName.trim()
          : attachment.displayLabel.trim(),
      'source_of_truth_locator':
          'reference-package://${attachment.packageId}/${attachment.packageVersionId}',
      'attachment': attachment.toJson(),
      'access': <String, Object?>{
        'allowed': accessDecision.allowed,
        'disposition': accessDecision.disposition,
        'reason_code': accessDecision.reasonCode,
        'attachment_id': accessDecision.attachmentId,
        'visibility_mode': accessDecision.visibilityMode,
        'access_level': accessDecision.accessLevel,
      },
      'package_summary': packageRecord == null
          ? <String, Object?>{}
          : <String, Object?>{
              'package_id': packageRecord.packageId,
              'package_kind': packageRecord.packageKind,
              'display_name': packageRecord.displayName,
              'latest_version_id': packageRecord.latestVersionId,
              'source_language': packageRecord.sourceLanguage,
              'target_language': packageRecord.targetLanguage,
              'lifecycle_status': packageRecord.lifecycleStatus,
              'updated_at': packageRecord.updatedAt,
            },
      'continuity_summary': continuitySummary,
      'continuity_ledger': ledger?.toJson() ?? <String, Object?>{},
    };
  }

  JsonMap _continuitySummary(ReferenceEvidenceContinuityLedger? ledger) {
    if (ledger == null) {
      return const <String, Object?>{
        'conflict_cluster_count': 0,
        'canon_decision_count': 0,
        'review_alert_count': 0,
        'manual_review_count': 0,
        'needs_decision_cluster_count': 0,
        'has_unresolved_conflicts': false,
      };
    }
    final manualReviewCount = ledger.reviewAlerts
        .where((alert) => alert.requiresManualReview)
        .length;
    final needsDecisionClusterCount = ledger.conflictClusters
        .where(
          (cluster) =>
              cluster.clusterStatus ==
              NarrativeConflictClusterStatuses.needsDecision,
        )
        .length;
    return <String, Object?>{
      'conflict_cluster_count': ledger.conflictClusters.length,
      'canon_decision_count': ledger.canonDecisions.length,
      'review_alert_count': ledger.reviewAlerts.length,
      'manual_review_count': manualReviewCount,
      'needs_decision_cluster_count': needsDecisionClusterCount,
      'has_unresolved_conflicts':
          manualReviewCount > 0 || needsDecisionClusterCount > 0,
      'updated_at': ledger.updatedAt,
    };
  }

  int _sumCount(List<JsonMap> items, {required String summaryKey}) {
    return items.fold<int>(
      0,
      (sum, item) =>
          sum +
          ValueReaders.intValue(
            ValueReaders.mapValue(item['continuity_summary'])[summaryKey],
          ),
    );
  }

  String _buildSummary({
    required int attachmentCount,
    required int readablePackageCount,
    required int blockedPackageCount,
    required int conflictClusterCount,
    required int canonDecisionCount,
    required int reviewAlertCount,
    required int manualReviewPackageCount,
    required int unresolvedPackageCount,
  }) {
    if (conflictClusterCount == 0 && reviewAlertCount == 0) {
      return '已检查 $attachmentCount 个挂载参考包，可读 $readablePackageCount 个${blockedPackageCount > 0 ? '、阻塞 $blockedPackageCount 个' : ''}；当前没有 continuity 冲突或 review alert。';
    }
    return '已检查 $attachmentCount 个挂载参考包，可读 $readablePackageCount 个${blockedPackageCount > 0 ? '、阻塞 $blockedPackageCount 个' : ''}；共发现 $conflictClusterCount 个 conflict cluster、$canonDecisionCount 个 canon decision、$reviewAlertCount 个 review alert，其中 $manualReviewPackageCount 个包需要人工复核，$unresolvedPackageCount 个包仍有未决冲突。';
  }

  static CreateProjectReferenceEvidenceSubstrate _defaultSubstrateFactory(
    ProjectReferenceExtractionPathService pathService,
  ) {
    return (project) => SqliteReferenceEvidenceSubstrate(
      substrateRootPath: pathService.substrateRootPath(project),
    );
  }
}
