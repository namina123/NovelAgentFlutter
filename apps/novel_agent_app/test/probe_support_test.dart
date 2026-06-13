import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/probe_support.dart';
import '../../../tools/probe_config_support.dart';

void main() {
  group('probe support', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_probe_support_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'loadProbeApiConfig reads override file with explicit opt-in',
      () async {
        final overrideDirectory = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}custom',
        )..createSync(recursive: true);
        final overrideFile = File(
          '${overrideDirectory.path}${Platform.pathSeparator}probe_api.txt',
        );
        await overrideFile.writeAsString(
          ['https://example.invalid/v1', 'test-key', 'test-model'].join('\n'),
        );

        final config = await loadProbeApiConfig(
          probeName: 'probe_support_test',
          repoRootOverride: tempDirectory.path,
          allowLegacyTestApi: false,
          allowTempSettingsFallback: false,
          environment: <String, String>{
            'NOVEL_AGENT_ENABLE_REAL_PROBES': '1',
            'NOVEL_AGENT_PROBE_API_FILE': 'custom/probe_api.txt',
          },
        );

        expect(config.baseUrl, 'https://example.invalid/v1');
        expect(config.apiKey, 'test-key');
        expect(config.modelId, 'test-model');
        expect(config.sourceLabel, 'NOVEL_AGENT_PROBE_API_FILE');
      },
    );

    test(
      'loadProbeApiConfig no longer falls back to legacy test_api by default',
      () async {
        final legacyFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}test_api.txt',
        );
        await legacyFile.writeAsString(
          [
            'https://legacy.invalid/v1',
            'legacy-key',
            'legacy-model',
          ].join('\n'),
        );

        expect(
          () => loadProbeApiConfig(
            probeName: 'probe_support_default_boundary_test',
            repoRootOverride: tempDirectory.path,
            environment: const <String, String>{
              'NOVEL_AGENT_ENABLE_REAL_PROBES': '1',
            },
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('ensureLocalRealProbeOptInWithEnvironment rejects missing opt-in', () {
      expect(
        () => ensureLocalRealProbeOptInWithEnvironment(
          probeName: 'probe_support_test',
          environment: const <String, String>{},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'classifyDraftProbeReportCategory distinguishes waiting budget content information and technical failures',
      () {
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'report_category': ProbeReportCategories.policyDisabled,
            },
          ),
          ProbeReportCategories.policyDisabled,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'report_category': ProbeReportCategories.pathFailure,
            },
          ),
          ProbeReportCategories.pathFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'stop_diagnosis': <String, Object?>{
                'present': true,
                'code': 'waiting_user_checkpoint',
                'category': 'waiting_user',
                'label': '等待用户确认',
              },
            },
          ),
          ProbeReportCategories.waitingUser,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'run_center_contract': <String, Object?>{
                'stop_diagnosis': <String, Object?>{
                  'present': true,
                  'code': 'max_steps',
                  'category': 'budget_exhausted',
                  'label': '预算边界已到',
                },
              },
            },
          ),
          ProbeReportCategories.budgetFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'expression_constraint_report': <String, Object?>{
                'path_resolution': <String, Object?>{
                  'path_failure': true,
                  'delivery_state': 'path_mismatch_recoverable',
                },
              },
            },
          ),
          ProbeReportCategories.pathFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'expression_constraint_report': <String, Object?>{
                'status_projection': <String, Object?>{
                  'status': 'disabled',
                  'disabled': true,
                },
                'policy_mode': 'disabled',
              },
            },
          ),
          ProbeReportCategories.policyDisabled,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            errorSummary: 'maximum context length exceeded',
          ),
          ProbeReportCategories.budgetFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'stop_diagnosis': <String, Object?>{
                'present': true,
                'code': 'delivery_manual_attention',
                'category': 'manual_attention',
                'label': '需要人工处理',
              },
            },
          ),
          ProbeReportCategories.contentQualityFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            validation: const <String, Object?>{
              'information_probe': <String, Object?>{'ok': false},
            },
          ),
          ProbeReportCategories.informationQualityFailure,
        );
        expect(
          classifyDraftProbeReportCategory(
            ok: false,
            errorSummary: 'socket closed unexpectedly',
          ),
          ProbeReportCategories.technicalFailure,
        );
      },
    );

    test(
      'buildProbeWorkspaceDirectory keeps probe artifacts under repo root',
      () {
        final workspace = buildProbeWorkspaceDirectory(
          repoRoot: 'D:\\repo',
          probeName: 'real_long_task_probe',
          runId: '2026-06-05T12:34:56.789Z',
        );

        expect(
          workspace.path,
          'D:\\repo\\artifacts\\real_long_task_probe_workspace\\2026-06-05T12-34-56-789Z',
        );
      },
    );

    test(
      'buildInformationProbeAssessment supports dry activation and artifact checks',
      () {
        final assessment = buildInformationProbeAssessment(
          activationReport: const <String, Object?>{
            'metadata': <String, Object?>{
              'selected_context_sections': <Object?>[
                <String, Object?>{'source_kind': 'project_design_element'},
              ],
            },
          },
          changedPaths: const <Object?>[
            '.novel_agent/information/design_elements/design-1.json',
            'knowledge/设计元素摘要.md',
          ],
          toolNames: <Object?>[NarrativeDomainToolNames.proposeDesignElement],
          requireInformationActivation: true,
          requireInformationArtifacts: true,
        );

        expect(ValueReaders.boolValue(assessment['ok']), isTrue);
        expect(
          ValueReaders.stringList(assessment['activation_source_kinds']),
          contains('project_design_element'),
        );
        expect(
          ValueReaders.stringList(assessment['information_changed_paths']),
          contains('.novel_agent/information/design_elements/design-1.json'),
        );
      },
    );

    test(
      'buildInformationProbeAssessment returns information quality failure for missing required activation',
      () {
        final assessment = buildInformationProbeAssessment(
          activationReport: const <String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'source': 'project_knowledge_card',
                'omitted': true,
                'metadata': <String, Object?>{
                  'source_kind': 'project_knowledge_card',
                  'required': true,
                },
              },
            ],
          },
          requireInformationActivation: true,
          allowRequiredInformationOmission: false,
        );

        expect(ValueReaders.boolValue(assessment['ok']), isFalse);
        expect(
          ValueReaders.stringValue(assessment['report_category']),
          ProbeReportCategories.informationQualityFailure,
        );
        expect(
          ValueReaders.stringValue(assessment['summary']),
          contains('required information omitted'),
        );
      },
    );

    test(
      'buildExpressionConstraintProbeReport projects policy review path and stop reason from production contracts',
      () {
        final executionResult = _forceProbeWritingExecutionResult();
        final signal = const LongTaskWritingExecutionSignalService()
            .signalFromWritingExecutionResult(
              executionResult,
              stopReason: 'delivery_manual_attention',
            );
        final report = buildExpressionConstraintProbeReport(
          writingExecutionResult: executionResult.toJson(),
          chapterDelivery: const <String, Object?>{
            'chapter_path': 'chapters/第04章_第04章.md',
            'requested_chapter_path': 'chapters/第04章_第04章.md',
            'resolved_chapter_path': 'chapters/第04章.md',
            'title': '第04章',
            'delivery_state': 'path_mismatch_recoverable',
            'path_resolution': <String, Object?>{
              'requested_path': 'chapters/第04章_第04章.md',
              'resolved_path': 'chapters/第04章.md',
              'title': '第04章',
              'path_changed': true,
              'reason': 'duplicate_prefix_removed',
            },
          },
          writingExecutionSignal: signal,
        );

        expect(ValueReaders.boolValue(report['present']), isTrue);
        expect(
          ValueReaders.stringValue(report['policy_mode']),
          ExpressionConstraintExecutionPolicyModes.force,
        );
        expect(
          ValueReaders.stringValue(report['injection_strength']),
          ExpressionConstraintInjectionStrengths.full,
        );
        expect(
          ValueReaders.stringValue(report['review_requirement']),
          ExpressionConstraintReviewRequirements.alwaysForWriting,
        );
        expect(ValueReaders.boolValue(report['review_required']), isTrue);
        expect(ValueReaders.boolValue(report['review_provided']), isTrue);
        expect(
          ValueReaders.stringList(report['risk_signals']),
          contains('视角泄漏'),
        );
        expect(
          ValueReaders.stringValue(report['disposition']),
          ExpressionConstraintGateRecommendedDispositions.repair,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(report['path_resolution'])['resolved_path'],
          ),
          'chapters/第04章.md',
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(report['stop_reason'])['present'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.mapValue(
            report['stop_diagnosis'],
          ).containsKey('summary'),
          isTrue,
        );
      },
    );

    test(
      'buildExpressionConstraintProbeReport keeps disabled policy and explicit stop fallback explainable',
      () {
        final report = buildExpressionConstraintProbeReport(
          writingExecutionResult: _disabledProbeWritingExecutionResult()
              .toJson(),
          stopReason: 'waiting_user_checkpoint',
          stopSummary: '等待检查点确认。',
        );

        expect(ValueReaders.boolValue(report['present']), isTrue);
        expect(
          ValueReaders.stringValue(report['policy_mode']),
          ExpressionConstraintExecutionPolicyModes.disabled,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(report['status_projection'])['status'],
          ),
          'disabled',
        );
        expect(ValueReaders.boolValue(report['review_required']), isFalse);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(report['stop_reason'])['code'],
          ),
          'waiting_user_checkpoint',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(report['stop_reason'])['summary'],
          ),
          contains('等待检查点确认'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(report['stop_diagnosis'])['category'],
          ),
          LongTaskStopOutcomeCategories.waitingUser,
        );
      },
    );
  });
}

WritingExecutionResult _forceProbeWritingExecutionResult() {
  return WritingExecutionResultNormalizerService().normalize(
    executionId: 'probe_force_execution',
    workflowKind: 'ordinary_project',
    deliveryState: ChapterDeliveryStateResult(
      deliveryId: 'delivery_probe_force',
      state: ChapterDeliveryStateStatuses.delivered,
      recommendedAction: 'accept',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
      reason: 'delivery_complete',
      summary: '章节交付完成。',
      blocksProgress: false,
      chapterBodyDelivered: true,
      submissionAccepted: true,
      retryable: false,
      metadata: const <String, Object?>{
        'chapter_path': 'chapters/第04章_第04章.md',
        'resolved_chapter_path': 'chapters/第04章.md',
        'path_resolution': <String, Object?>{
          'requested_path': 'chapters/第04章_第04章.md',
          'resolved_path': 'chapters/第04章.md',
          'title': '第04章',
          'path_changed': true,
          'reason': 'duplicate_prefix_removed',
        },
      },
    ),
    constraintBridgeResult: const WritingExecutionConstraintBridgeResult(
      expressionConstraintProfiles: <ExpressionConstraintProfile>[
        ExpressionConstraintProfile(
          id: 'strict_pov_boundary',
          displayName: '严格 POV 边界',
          summary: '限制未知信息越界。',
          kind: ExpressionConstraintKind.narrativeBoundary,
          rules: <String>['只保留 POV 可知信息。'],
        ),
      ],
      projectExpressionConstraintBindings: <ProjectExpressionConstraintBinding>[
        ProjectExpressionConstraintBinding(
          id: 'binding_1',
          profileId: 'strict_pov_boundary',
          defaultForProject: true,
        ),
      ],
      expressionConstraintPolicyMode:
          ExpressionConstraintExecutionPolicyModes.force,
      expressionConstraintInjectionStrength:
          ExpressionConstraintInjectionStrengths.full,
      expressionConstraintReviewRequirement:
          ExpressionConstraintReviewRequirements.alwaysForWriting,
      expressionConstraintViolationDisposition:
          ExpressionConstraintViolationDispositions.repair,
      expressionConstraintApplied: true,
      expressionConstraintInjectionMode: 'brief_and_sections',
      expressionConstraintReviewRequired: true,
    ),
    chapterLengthEvaluation: _probeBalancedEvaluation(),
    expressionConstraintReview: const ExpressionConstraintReviewProjection(
      authenticityPassLevel:
          ExpressionConstraintReviewProjection.authenticityAggressive,
      continuityWatchItems: <String>['视角泄漏'],
      miniRecheckItems: <String>['检查是否越过当前角色可知边界'],
    ),
  );
}

WritingExecutionResult _disabledProbeWritingExecutionResult() {
  return WritingExecutionResultNormalizerService().normalize(
    executionId: 'probe_disabled_execution',
    workflowKind: 'ordinary_project',
    deliveryState: ChapterDeliveryStateResult(
      deliveryId: 'delivery_probe_disabled',
      state: ChapterDeliveryStateStatuses.delivered,
      recommendedAction: 'accept',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
      reason: 'delivery_complete',
      summary: '章节正文已交付。',
      blocksProgress: false,
      chapterBodyDelivered: true,
      submissionAccepted: true,
      retryable: false,
      metadata: const <String, Object?>{
        'chapter_path': 'chapters/第01章.md',
        'resolved_chapter_path': 'chapters/第01章.md',
      },
    ),
    constraintBridgeResult: const WritingExecutionConstraintBridgeResult(
      expressionConstraintProfiles: <ExpressionConstraintProfile>[
        ExpressionConstraintProfile(
          id: 'natural_voice',
          displayName: '自然口语',
          summary: '避免模板化解释腔。',
          kind: ExpressionConstraintKind.naturalExpression,
          rules: <String>['减少工整排比。'],
        ),
      ],
      projectExpressionConstraintBindings: <ProjectExpressionConstraintBinding>[
        ProjectExpressionConstraintBinding(
          id: 'binding_1',
          profileId: 'natural_voice',
          defaultForProject: true,
        ),
      ],
      expressionConstraintPolicyMode:
          ExpressionConstraintExecutionPolicyModes.disabled,
      expressionConstraintInjectionStrength:
          ExpressionConstraintInjectionStrengths.none,
      expressionConstraintReviewRequirement:
          ExpressionConstraintReviewRequirements.none,
      expressionConstraintViolationDisposition:
          ExpressionConstraintViolationDispositions.remind,
      expressionConstraintApplied: false,
      expressionConstraintSkippedReasons: <String>['policy_disabled'],
      expressionConstraintInjectionMode: 'disabled',
      expressionConstraintReviewRequired: false,
    ),
    chapterLengthEvaluation: _probeBalancedEvaluation(),
  );
}

ChapterLengthEvaluation _probeBalancedEvaluation() {
  return ChapterLengthEvaluation(
    profile: const ChapterLengthProfile(
      enabled: true,
      targetLength: 2200,
      preferredMin: 1800,
      preferredMax: 2600,
      stage: 'draft',
    ),
    policy: const ChapterLengthDistributionPolicy(),
    currentRecord: const ChapterLengthRecord(
      length: 2180,
      sortOrder: 1,
      taskId: 'chapter_001',
      relativePath: 'chapters/ch01.md',
    ),
    level: 'balanced',
    recommendedAction: 'pass',
    notes: const <String>['当前章长度分布基本稳定，可直接继续。'],
  );
}
