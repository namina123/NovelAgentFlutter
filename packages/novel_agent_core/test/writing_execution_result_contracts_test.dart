import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WritingExecutionResult contracts', () {
    final normalizer = WritingExecutionResultNormalizerService();
    const codec = WritingExecutionResultCodecService();

    test(
      'normalizes ordinary and long task execution into the same shared result type and round-trips through codec',
      () {
        // 中文注释: 这里验证普通写作和长任务都能落到同一个共享结果合同，而不是继续分叉成宿主私有形状。
        final ordinaryResult = normalizer.normalize(
          executionId: 'draft_run_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节正文与 submission 已通过当前交付状态机检查。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
            metadata: const <String, Object?>{
              'chapter_path': 'chapters/ch01.md',
            },
          ),
          constraintBridgeResult: _constraintBridge(),
          chapterLengthEvaluation: _balancedEvaluation(),
          expressionConstraintReview:
              const ExpressionConstraintReviewProjection(
                authenticityPassLevel:
                    ExpressionConstraintReviewProjection.authenticityLight,
                reviewFocuses: <String>['保留口语张力'],
                voiceProtectionNotes: <String>['避免解释腔。'],
              ),
          activationReport: _activationReport(),
          informationSignal: const <String, Object?>{
            'category': 'accept',
            'summary': '当前已有 information 改动，建议在后续 checkpoint 中复核。',
            'changed_paths': <Object?>['knowledge/人物关系摘要.md'],
          },
          collaborationResults: const <Object?>[
            <String, Object?>{
              'ok': true,
              'strategy': 'main_with_children',
              'agent_id': 'style_reviewer',
              'agent_name': '文风审稿',
              'task': '检查第一章语气是否自然。',
              'summary': '已给出轻量语气建议。',
              'tool_calls': <Object?>[
                <String, Object?>{'name': 'read_project_file'},
              ],
            },
          ],
        );
        final longTaskResult = normalizer.normalize(
          executionId: 'long_task_run_001',
          workflowKind: 'long_task',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '长任务章节交付正常。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
            metadata: const <String, Object?>{
              'chapter_path': 'chapters/ch10.md',
            },
          ),
        );
        final decoded = codec.fromJson(codec.toJson(ordinaryResult));

        expect(ordinaryResult, isA<WritingExecutionResult>());
        expect(longTaskResult, isA<WritingExecutionResult>());
        expect(ordinaryResult.runtimeType, longTaskResult.runtimeType);
        expect(
          ordinaryResult.overallStatus,
          WritingExecutionOutcomeStatuses.success,
        );
        expect(decoded.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(decoded.information.selectedItemCount, 1);
        expect(decoded.collaboration.totalCollaboratorCount, 1);
        expect(
          decoded.constraints.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.adaptive,
        );
        expect(decoded.constraints.expressionConstraintApplied, isTrue);
        expect(decoded.constraints.expressionConstraintSkipped, isFalse);
        expect(
          decoded.constraints.expressionConstraintGate.severity,
          ExpressionConstraintGateSeverities.info,
        );
        expect(
          decoded.constraints.expressionConstraintReviewContract,
          isNotNull,
        );
        expect(
          decoded
              .constraints
              .expressionConstraintReviewContract
              ?.recommendedDisposition,
          ReviewRecommendedDispositions.accept,
        );
        expect(
          decoded.constraints.expressionConstraintReviewSummary,
          isNotNull,
        );
        expect(
          decoded.constraints.expressionConstraintReviewSummary?.reviewType,
          ReviewTypeConstants.style,
        );
        expect(
          decoded.information.informationEvidenceReviewContract,
          isNull,
        );
        expect(
          decoded.information.informationEvidenceReviewSummary,
          isNull,
        );
        expect(decoded.delivery.deliveryFailure, isNull);
        expect(decoded.validateBasics(), isEmpty);
      },
    );

    test(
      'normalizes recoverable delivery failure into recoverable_failure',
      () {
        // 中文注释: 这里验证缺正文或路径漂移一类可修复交付问题会进入共享 recoverable_failure，而不是模糊失败。
        final result = normalizer.normalize(
          executionId: 'long_task_repair_001',
          workflowKind: 'long_task',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.missingOutputRecoverable,
            recommendedAction: 'request_chapter_repair',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
            reason: 'chapter_content_missing',
            summary: '章节正文缺失或为空。',
            retryable: true,
            blocksProgress: true,
            metadata: const <String, Object?>{
              'chapter_path': 'chapters/ch11.md',
            },
          ),
          recoveryPlan: const <String, Object?>{
            'action': 'pause_for_repair',
            'reason': 'delivery_recovery_required',
            'note': '最近一步的章节交付状态要求先进入 repair/recovery。',
            'safe_after_crash': true,
            'task': <String, Object?>{
              'id': 'chapter_011',
              'title': '第十一章',
              'relative_path': 'chapters/ch11.md',
            },
          },
        );

        expect(
          result.overallStatus,
          WritingExecutionOutcomeStatuses.recoverableFailure,
        );
        expect(result.retryable, isTrue);
        expect(result.nextAction, 'pause_for_repair');
        expect(result.recovery.requiresRepair, isTrue);
        expect(
          result.delivery.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.emptyBody,
        );
        expect(result.validateBasics(), isEmpty);
      },
    );

    test(
      'round-trips stable delivery failure contract through shared result codec',
      () {
        final failure = ChapterDeliveryFailure(
          category: ChapterDeliveryFailureCategories.sidecarMissing,
          reason: 'submission_missing',
          summary: '章节正文已交付，但缺少结构化 submission。',
          deliveryState: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
          chapterPath: 'chapters/ch12.md',
          resolvedChapterPath: 'chapters/ch12.md',
          retryable: true,
          chapterBodyDelivered: true,
          submissionAccepted: false,
        );
        final result = normalizer.normalize(
          executionId: 'delivery_failure_roundtrip_001',
          workflowKind: 'long_task',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
            recommendedAction: 'request_sidecar_repair',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            reason: 'submission_missing',
            summary: '章节正文已交付，但缺少结构化 submission。',
            blocksProgress: true,
            chapterBodyDelivered: true,
            submissionAccepted: false,
            retryable: true,
            deliveryFailure: failure,
            metadata: const <String, Object?>{
              'chapter_path': 'chapters/ch12.md',
              'resolved_chapter_path': 'chapters/ch12.md',
            },
          ),
        );
        final decoded = codec.fromJson(codec.toJson(result));

        expect(
          decoded.delivery.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.sidecarMissing,
        );
        expect(decoded.delivery.deliveryFailure?.reason, 'submission_missing');
        expect(decoded.validateBasics(), isEmpty);
      },
    );

    test(
      'backfills delivery failure from legacy reason when old delivery state lacks typed contract',
      () {
        final result = normalizer.normalize(
          executionId: 'delivery_failure_legacy_001',
          workflowKind: 'long_task',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.pathMismatchRecoverable,
            recommendedAction: 'request_chapter_repair',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.executionFailed,
            reason: 'chapter_path_mismatch',
            summary: '章节写入路径与预期路径不一致。',
            blocksProgress: true,
            retryable: true,
            metadata: const <String, Object?>{
              'chapter_path': 'chapters/ch13.md',
              'resolved_chapter_path': 'drafts/ch13.md',
            },
          ),
        );

        expect(
          result.delivery.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.pathMismatch,
        );
        expect(
          result.delivery.deliveryFailure?.resolvedChapterPath,
          'drafts/ch13.md',
        );
      },
    );

    test('normalizes waiting user signal into user_action_required', () {
      // 中文注释: 这里验证 information/recovery 等待用户信号能落到统一的 user_action_required 分类。
      final result = normalizer.normalize(
        executionId: 'checkpoint_wait_001',
        workflowKind: 'deconstruction_followup',
        activationReport: _activationReport(includeRequiredOmitted: true),
        informationSignal: const <String, Object?>{
          'category': 'checkpoint_user',
          'reason': 'information_waiting_user',
          'summary': '待研究 1 项，建议先确认是否补研究。',
          'waiting_user': true,
          'changed_paths': <Object?>[
            '.novel_agent/information/research_requests/request_1.json',
          ],
        },
        recoveryPlan: const <String, Object?>{
          'action': 'resume_when_user_confirms',
          'reason': 'information_waiting_user',
          'note': '最近一步的信息层信号建议先停在用户确认点。',
          'safe_after_crash': true,
        },
      );

      expect(
        result.overallStatus,
        WritingExecutionOutcomeStatuses.userActionRequired,
      );
      expect(result.requiresUserAction, isTrue);
      expect(result.information.requiredOmittedItemCount, 1);
      expect(result.recovery.waitingUser, isTrue);
      expect(result.validateBasics(), isEmpty);
    });

    test(
      'keeps pending research as evidence warning without forcing waiting user',
      () {
        final result = normalizer.normalize(
          executionId: 'information_pending_001',
          workflowKind: 'ordinary_project',
          informationSignal: const <String, Object?>{
            'pending_research_count': 1,
            'changed_paths': <Object?>[
              '.novel_agent/information/research_requests/request_2.json',
            ],
          },
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.requiresUserAction, isFalse);
        expect(result.information.waitingUser, isFalse);
        expect(
          result.information.evidenceGate.severity,
          InformationEvidenceGateSeverities.warning,
        );
        expect(
          result.information.evidenceGate.recommendedDisposition,
          InformationEvidenceRecommendedDispositions.accept,
        );
        expect(result.information.summary, contains('待研究 1 项'));
        expect(result.summary, contains('Information：待研究 1 项'));
      },
    );

    test(
      'keeps rigorous source insufficiency as evidence warning instead of repair',
      () {
        final result = normalizer.normalize(
          executionId: 'information_rigorous_001',
          workflowKind: 'ordinary_project',
          informationSignal: const <String, Object?>{
            'rigorous_source_insufficient_count': 1,
            'requires_repair': true,
            'reason': 'information_rigorous_source_insufficient',
            'changed_paths': <Object?>['research/资料研究摘要.md'],
          },
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.blocksProgress, isFalse);
        expect(result.information.requiresRepair, isFalse);
        expect(
          result.information.evidenceGate.severity,
          InformationEvidenceGateSeverities.warning,
        );
        expect(
          result.information.evidenceGate.recommendedDisposition,
          InformationEvidenceRecommendedDispositions.accept,
        );
        expect(result.information.summary, contains('严谨来源不足 1 项'));
        expect(result.summary, contains('Information：严谨来源不足 1 项'));
      },
    );

    test(
      'normalizes gateway failure into recoverable failure instead of user wait',
      () {
        final result = normalizer.normalize(
          executionId: 'information_gateway_failed_001',
          workflowKind: 'ordinary_project',
          informationSignal: const <String, Object?>{
            'gateway_failure_count': 1,
            'requires_repair': true,
            'reason': 'information_gateway_failed',
            'changed_paths': <Object?>[
              '.novel_agent/information/research_requests/request_3.json',
            ],
          },
        );

        expect(
          result.overallStatus,
          WritingExecutionOutcomeStatuses.recoverableFailure,
        );
        expect(result.requiresUserAction, isFalse);
        expect(result.information.waitingUser, isFalse);
        expect(result.information.requiresRepair, isTrue);
        expect(result.information.summary, contains('研究网关失败 1 项'));
      },
    );

    test(
      'carries activation selected omitted truncated ids and source refs into shared information metadata',
      () {
        final result = normalizer.normalize(
          executionId: 'information_activation_001',
          workflowKind: 'ordinary_project',
          activationReport: _activationReport(
            includeRequiredOmitted: true,
            includeTruncatedResearch: true,
          ),
          informationSignal: const <String, Object?>{
            'category': 'accept',
            'summary': '当前 information 激活报告已生成。',
            'changed_paths': <Object?>[
              'knowledge/项目知识摘要.md',
              'research/资料研究摘要.md',
            ],
          },
        );

        final metadata = result.information.metadata;
        expect(
          ValueReaders.stringList(metadata['selected_item_ids']),
          containsAll(<String>['item_character_rule', 'item_research_trace']),
        );
        expect(
          ValueReaders.stringList(metadata['omitted_item_ids']),
          contains('item_world_rule'),
        );
        expect(
          ValueReaders.stringList(metadata['truncated_item_ids']),
          contains('item_research_trace'),
        );
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              metadata['selected_source_kind_counts'],
            )['project_knowledge_card'],
          ),
          1,
        );
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              metadata['truncated_source_kind_counts'],
            )['project_research_note'],
          ),
          1,
        );
        final selectedSourceRefs = ValueReaders.mapList(
          metadata['selected_source_refs'],
        );
        final omittedSourceRefs = ValueReaders.mapList(
          metadata['omitted_source_refs'],
        );
        final truncatedSourceRefs = ValueReaders.mapList(
          metadata['truncated_source_refs'],
        );
        expect(
          selectedSourceRefs.any(
            (entry) =>
                ValueReaders.stringValue(
                      ValueReaders.mapValue(entry)['item_id'],
                    ) ==
                    'item_character_rule' &&
                ValueReaders.mapList(
                  ValueReaders.mapValue(entry)['source_refs'],
                ).isNotEmpty,
          ),
          isTrue,
        );
        expect(
          omittedSourceRefs.any(
            (entry) =>
                ValueReaders.stringValue(
                  ValueReaders.mapValue(entry)['item_id'],
                ) ==
                'item_world_rule',
          ),
          isTrue,
        );
        expect(
          truncatedSourceRefs.any(
            (entry) =>
                ValueReaders.stringValue(
                  ValueReaders.mapValue(entry)['item_id'],
                ) ==
                'item_research_trace',
          ),
          isTrue,
        );
      },
    );

    test('normalizes severe quality risk into content_quality_issue', () {
      // 中文注释: 这里验证标题-only 或严重字数偏离一类内容质量问题会被共享合同明确分类。
      final result = normalizer.normalize(
        executionId: 'draft_quality_001',
        workflowKind: 'ordinary_project',
        deliveryState: _deliveryState(
          state: ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
          recommendedAction: 'request_chapter_repair',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
          reason: 'title_only_output',
          summary: '章节输出只包含标题或缺少有效正文。',
          blocksProgress: true,
        ),
        constraintBridgeResult: _constraintBridge(),
        chapterLengthEvaluation: _severeEvaluation(),
        expressionConstraintReview: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          reviewFocuses: <String>['修掉模板化口号'],
          miniRecheckItems: <String>['检查结尾是否只剩概述'],
        ),
      );

      expect(
        result.overallStatus,
        WritingExecutionOutcomeStatuses.contentQualityIssue,
      );
      expect(result.constraints.contentQualityRisk, isTrue);
      expect(result.constraints.hardConstraintTriggered, isTrue);
      expect(result.constraints.chapterLengthDiscipline.present, isTrue);
      expect(result.constraints.chapterLengthDiscipline.level, 'severely_off');
      expect(
        result.constraints.chapterLengthDiscipline.hardGateTriggered,
        isTrue,
      );
      expect(result.constraints.chapterLengthDiscipline.repairRequired, isTrue);
      expect(
        result.constraints.chapterLengthDiscipline.severeDeviationRatioThreshold,
        0.35,
      );
      expect(result.summary, contains('章节输出只包含标题'));
      expect(result.validateBasics(), isEmpty);
    });

    test(
      'auto-resolves low-risk collaboration conflict without escalating status',
      () {
        final result = normalizer.normalize(
          executionId: 'collaboration_conflict_low_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节交付完成。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
          ),
          collaborationResults: const <Object?>[
            <String, Object?>{
              'ok': true,
              'strategy': 'main_with_children',
              'agent_id': 'reviewer',
              'agent_name': '审稿智能体',
              'task': '检查开篇节奏。',
              'summary': '建议删掉一段解释。',
              'tool_calls': <Object?>[],
              'collaboration_result_package': <String, Object?>{
                'package_id': 'collab_pkg_001',
                'execution_package_id': 'exec_001',
                'child_run_package_id': 'child_001',
                'agent_id': 'reviewer',
                'agent_name': '审稿智能体',
                'task': '检查开篇节奏。',
                'status': 'success',
                'retryable': false,
                'cancelled': false,
                'used_tool_count': 0,
                'result_summary': '建议删掉一段解释。',
                'result_markdown': '建议删掉一段解释。',
                'merge_contract': <String, Object?>{
                  'merge_mode': 'main_agent_merges',
                  'parent_review_required': true,
                  'allows_direct_delivery': false,
                  'accepted_result_types': <Object?>['suggestion'],
                  'relation_to_writing_execution_result':
                      'consumed_by_writing_execution_collaboration_summary',
                },
                'conflicts': <Object?>[
                  <String, Object?>{
                    'conflict_id': 'conflict_low_001',
                    'group_key': 'opening_pace',
                    'subject': '开篇节奏取舍',
                    'risk': 'low',
                    'suggestion': '删掉一段解释性背景。',
                    'adoption_hint': 'merge_if_clean',
                    'confidence': 0.74,
                    'evidence': <Object?>[
                      <String, Object?>{
                        'kind': 'review_note',
                        'summary': '该解释段没有影响长期规则，只影响节奏。',
                      },
                    ],
                  },
                ],
              },
            },
          ],
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.requiresUserAction, isFalse);
        expect(result.blocksProgress, isFalse);
        expect(result.nextAction, 'accept');
        expect(result.collaboration.totalConflictCount, 1);
        expect(result.collaboration.autoResolvedConflictCount, 1);
        expect(result.collaboration.repairRequiredConflictCount, 0);
        expect(result.collaboration.userConfirmationConflictCount, 0);
        expect(result.collaboration.conflictSummary, contains('低风险自动归并'));
      },
    );

    test(
      'escalates high-risk collaboration conflict into user_action_required',
      () {
        final result = normalizer.normalize(
          executionId: 'collaboration_conflict_high_001',
          workflowKind: 'ordinary_project',
          collaborationResults: const <Object?>[
            <String, Object?>{
              'ok': true,
              'strategy': 'main_with_children',
              'agent_id': 'continuity_guard',
              'agent_name': '连续性守卫',
              'task': '检查设定冲突。',
              'summary': '当前建议可能覆盖长期规则。',
              'tool_calls': <Object?>[],
              'collaboration_result_package': <String, Object?>{
                'package_id': 'collab_pkg_002',
                'execution_package_id': 'exec_002',
                'child_run_package_id': 'child_002',
                'agent_id': 'continuity_guard',
                'agent_name': '连续性守卫',
                'task': '检查设定冲突。',
                'status': 'success',
                'retryable': false,
                'cancelled': false,
                'used_tool_count': 0,
                'result_summary': '当前建议可能覆盖长期规则。',
                'result_markdown': '当前建议可能覆盖长期规则。',
                'merge_contract': <String, Object?>{
                  'merge_mode': 'main_agent_merges',
                  'parent_review_required': true,
                  'allows_direct_delivery': false,
                  'accepted_result_types': <Object?>['risk'],
                  'relation_to_writing_execution_result':
                      'consumed_by_writing_execution_collaboration_summary',
                },
                'conflicts': <Object?>[
                  <String, Object?>{
                    'conflict_id': 'conflict_high_001',
                    'group_key': 'world_rule_reveal',
                    'subject': '是否提前公开世界规则',
                    'target': 'continuity_state',
                    'risk': 'high',
                    'suggestion': '保留现有连续性规则，不在第一章公开机制。',
                    'adoption_hint': 'user_confirmation_required',
                    'confidence': 0.93,
                    'evidence': <Object?>[
                      <String, Object?>{
                        'kind': 'continuity_rule',
                        'summary': '连续性约束明确禁止第一章公开机制真相。',
                      },
                    ],
                    'metadata': <String, Object?>{
                      'requires_user_confirmation': true,
                    },
                  },
                ],
              },
            },
          ],
        );

        expect(
          result.overallStatus,
          WritingExecutionOutcomeStatuses.userActionRequired,
        );
        expect(result.requiresUserAction, isTrue);
        expect(result.blocksProgress, isTrue);
        expect(result.nextAction, 'confirm_collaboration_conflict');
        expect(result.collaboration.totalConflictCount, 1);
        expect(result.collaboration.userConfirmationConflictCount, 1);
        expect(result.collaboration.highestConflictRisk, 'high');
        expect(result.summary, contains('协作冲突'));
      },
    );

    test(
      'downgrades retry-child collaboration failure after formal review delivery',
      () {
        final result = normalizer.normalize(
          executionId: 'formal_review_retry_child_001',
          workflowKind: 'workflow_task',
          collaborationResults: const <Object?>[
            <String, Object?>{
              'ok': false,
              'retryable': true,
              'failure_disposition': 'retry_child',
              'strategy': 'main_with_children',
              'agent_id': 'continuity_keeper',
              'agent_name': '设定专家',
              'task': '对当前审稿结论补一轮连续性复核。',
              'summary': '子智能体空返回，建议局部重试：Sub-agent returned empty content.',
              'tool_calls': <Object?>[],
              'collaboration_result_package': <String, Object?>{
                'package_id': 'collab_pkg_retry_child_001',
                'execution_package_id': 'exec_retry_child_001',
                'child_run_package_id': 'child_retry_child_001',
                'agent_id': 'continuity_keeper',
                'agent_name': '设定专家',
                'task': '对当前审稿结论补一轮连续性复核。',
                'status': 'failed',
                'retryable': true,
                'cancelled': false,
                'used_tool_count': 0,
                'result_summary':
                    '子智能体空返回，建议局部重试：Sub-agent returned empty content.',
                'result_markdown': '',
                'merge_contract': <String, Object?>{
                  'merge_mode': 'main_agent_merges',
                  'parent_review_required': true,
                  'allows_direct_delivery': false,
                  'accepted_result_types': <Object?>['risk'],
                  'relation_to_writing_execution_result':
                      'consumed_by_writing_execution_collaboration_summary',
                },
                'conflicts': const <Object?>[],
                'metadata': <String, Object?>{
                  'failure_disposition': 'retry_child',
                  'collaboration_failure_summary':
                      '子智能体空返回，建议局部重试：Sub-agent returned empty content.',
                },
              },
            },
          ],
          metadata: const <String, Object?>{
            'task_id': 'review_task_001',
            'task_type': 'review',
            'formal_review_completed': true,
          },
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.blocksProgress, isFalse);
        expect(result.collaboration.failedCollaboratorCount, 1);
        expect(result.collaboration.blockingFailureCount, 0);
        expect(result.collaboration.degraded, isTrue);
        expect(
          ValueReaders.boolValue(
            result.collaboration.metadata['formal_review_retry_child_downgraded'],
          ),
          isTrue,
        );
      },
    );

    test(
      'keeps mild chapter drift in reminder-only gate instead of repair',
      () {
        // 中文注释: 这里验证轻微或可回调的字数偏差只会留下提醒，不会被误升格成返修阻断。
        final result = normalizer.normalize(
          executionId: 'draft_reminder_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节交付完成。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
          ),
          constraintBridgeResult: _constraintBridge(),
          chapterLengthEvaluation: _needsRebalanceEvaluation(),
          expressionConstraintReview:
              const ExpressionConstraintReviewProjection(
                authenticityPassLevel:
                    ExpressionConstraintReviewProjection.authenticityAggressive,
                reviewFocuses: <String>['重点清理 AI 味，但不要抹平人物声音。'],
              ),
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.constraints.hardConstraintTriggered, isFalse);
        expect(result.constraints.repairRequired, isFalse);
        expect(result.constraints.reminderOnly, isTrue);
        expect(result.constraints.chapterLengthDiscipline.present, isTrue);
        expect(
          result.constraints.chapterLengthDiscipline.level,
          'needs_rebalance',
        );
        expect(
          result.constraints.chapterLengthDiscipline.reviewSuggested,
          isTrue,
        );
        expect(
          result.constraints.chapterLengthDiscipline.hardGateTriggered,
          isFalse,
        );
        expect(
          result.constraints.chapterLengthDiscipline.recommendedAction,
          'adjust_next_chapter',
        );
        expect(
          result.constraints.expressionConstraintGate.recommendedDisposition,
          ExpressionConstraintGateRecommendedDispositions.remind,
        );
        expect(
          result.constraints.softGateReasons,
          contains('chapter_length_needs_rebalance'),
        );
        expect(
          result.constraints.softGateReasons,
          contains('expression_constraint_remind'),
        );
        expect(result.validateBasics(), isEmpty);
      },
    );

    test(
      'marks missing expression review evidence as hard gate for writing paths',
      () {
        // 中文注释: 这里验证表达限制一旦进入写作执行 gate，就必须留下复核证据，不能只算“有 profile 就行”。
        final result = normalizer.normalize(
          executionId: 'draft_constraint_missing_review_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
            recommendedAction: 'request_chapter_repair',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节正文已交付，但缺少表达限制复核证据。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
            blocksProgress: true,
          ),
          constraintBridgeResult: _constraintBridge(),
          chapterLengthEvaluation: _balancedEvaluation(),
        );

        expect(
          result.overallStatus,
          WritingExecutionOutcomeStatuses.contentQualityIssue,
        );
        expect(result.constraints.expressionConstraintReviewRequired, isTrue);
        expect(result.constraints.expressionConstraintReviewProvided, isFalse);
        expect(result.constraints.expressionConstraintEvidenceMissing, isTrue);
        expect(result.constraints.hardConstraintTriggered, isTrue);
        expect(
          result.constraints.expressionConstraintGate.recommendedDisposition,
          ExpressionConstraintGateRecommendedDispositions.repair,
        );
        expect(
          result.constraints.expressionConstraintGate.repairRequired,
          isTrue,
        );
        expect(
          result.constraints.hardGateReasons,
          contains('expression_constraint_review_missing'),
        );
        expect(result.validateBasics(), isEmpty);
      },
    );

    test(
      'does not treat disabled expression policy as missing review evidence',
      () {
        final result = normalizer.normalize(
          executionId: 'draft_constraint_disabled_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节正文已交付。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
          ),
          constraintBridgeResult: _disabledConstraintBridge(),
          chapterLengthEvaluation: _balancedEvaluation(),
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.constraints.expressionConstraintActive, isTrue);
        expect(result.constraints.expressionConstraintDisabled, isTrue);
        expect(result.constraints.expressionConstraintApplied, isFalse);
        expect(result.constraints.expressionConstraintSkipped, isFalse);
        expect(result.constraints.expressionConstraintReviewRequired, isFalse);
        expect(result.constraints.expressionConstraintEvidenceMissing, isFalse);
        expect(result.constraints.expressionConstraintGate.present, isFalse);
        expect(
          result.constraints.hardGateReasons,
          isNot(contains('expression_constraint_review_missing')),
        );
        expect(result.constraints.summary, contains('当前策略已关闭'));
      },
    );

    test(
      'surfaces skipped expression policy without forcing missing review',
      () {
        final result = normalizer.normalize(
          executionId: 'draft_constraint_skipped_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节正文已交付。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
          ),
          constraintBridgeResult: _skippedConstraintBridge(),
          chapterLengthEvaluation: _balancedEvaluation(),
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.constraints.expressionConstraintActive, isTrue);
        expect(result.constraints.expressionConstraintDisabled, isFalse);
        expect(result.constraints.expressionConstraintApplied, isFalse);
        expect(result.constraints.expressionConstraintSkipped, isTrue);
        expect(result.constraints.expressionConstraintReviewRequired, isFalse);
        expect(result.constraints.expressionConstraintEvidenceMissing, isFalse);
        expect(result.constraints.expressionConstraintGate.present, isFalse);
        expect(
          result.constraints.softGateReasons,
          contains('expression_constraint_skipped'),
        );
        expect(result.constraints.summary, contains('当前轮次未应用'));
      },
    );

    test(
      'does not hard gate force policy when workflow orchestration is skipped',
      () {
        final result = normalizer.normalize(
          executionId: 'draft_constraint_force_orchestration_skip_001',
          workflowKind: 'long_task',
          constraintBridgeResult: _forceOrchestrationSkippedConstraintBridge(),
          chapterLengthEvaluation: _balancedEvaluation(),
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.constraints.expressionConstraintActive, isTrue);
        expect(
          result.constraints.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.force,
        );
        expect(result.constraints.expressionConstraintApplied, isFalse);
        expect(result.constraints.expressionConstraintSkipped, isTrue);
        expect(result.constraints.expressionConstraintReviewRequired, isFalse);
        expect(result.constraints.expressionConstraintEvidenceMissing, isFalse);
        expect(result.constraints.expressionConstraintGate.present, isFalse);
        expect(
          result.constraints.hardGateReasons,
          isNot(contains('expression_constraint_review_missing')),
        );
        expect(
          result.constraints.softGateReasons,
          contains('expression_constraint_skipped'),
        );
        expect(result.validateBasics(), isEmpty);
      },
    );

    test('uses adjust-next gate signal for repeated adaptive review risks', () {
      final result = normalizer.normalize(
        executionId: 'draft_constraint_adjust_next_001',
        workflowKind: 'ordinary_project',
        deliveryState: _deliveryState(
          state: ChapterDeliveryStateStatuses.delivered,
          recommendedAction: 'accept',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
          summary: '章节正文已交付。',
          chapterBodyDelivered: true,
          submissionAccepted: true,
        ),
        constraintBridgeResult: _runtimeEscalatedConstraintBridge(),
        chapterLengthEvaluation: _balancedEvaluation(),
        expressionConstraintReview: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['检查结尾是否又回到概述句', '检查中段是否重复解释'],
        ),
      );

      expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
      expect(
        result.constraints.expressionConstraintGate.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.adjustNext,
      );
      expect(
        result.constraints.expressionConstraintGate.adjustNextChapter,
        isTrue,
      );
      expect(
        result.constraints.expressionConstraintGate.repairRequired,
        isFalse,
      );
      expect(result.nextAction, 'accept');
      expect(
        result.constraints.softGateReasons,
        contains('expression_constraint_adjust_next_chapter'),
      );
    });

    test('uses force repair gate signal for structural expression risk', () {
      final result = normalizer.normalize(
        executionId: 'draft_constraint_force_repair_001',
        workflowKind: 'ordinary_project',
        constraintBridgeResult: _forceConstraintBridge(),
        chapterLengthEvaluation: _balancedEvaluation(),
        expressionConstraintReview: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          continuityWatchItems: <String>['视角泄漏'],
          miniRecheckItems: <String>['检查是否越过当前角色可知边界'],
        ),
      );

      expect(
        result.overallStatus,
        WritingExecutionOutcomeStatuses.contentQualityIssue,
      );
      expect(
        result.constraints.expressionConstraintGate.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.repair,
      );
      expect(
        result.constraints.expressionConstraintGate.repairRequired,
        isTrue,
      );
      expect(
        result.constraints.hardGateReasons,
        contains('expression_constraint_force_repair_continuity_risk'),
      );
    });

    test(
      'keeps profile-only expression constraints inactive until project binding exists',
      () {
        final result = normalizer.normalize(
          executionId: 'draft_constraint_profile_only_001',
          workflowKind: 'ordinary_project',
          deliveryState: _deliveryState(
            state: ChapterDeliveryStateStatuses.delivered,
            recommendedAction: 'accept',
            suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
            summary: '章节正文已交付。',
            chapterBodyDelivered: true,
            submissionAccepted: true,
          ),
          constraintBridgeResult: _profileOnlyConstraintBridge(),
          chapterLengthEvaluation: _balancedEvaluation(),
        );

        expect(result.overallStatus, WritingExecutionOutcomeStatuses.success);
        expect(result.constraints.expressionConstraintProfileCount, 1);
        expect(result.constraints.expressionConstraintBindingCount, 0);
        expect(result.constraints.expressionConstraintActive, isFalse);
        expect(result.constraints.expressionConstraintReviewRequired, isFalse);
        expect(result.constraints.expressionConstraintEvidenceMissing, isFalse);
        expect(
          result.constraints.hardGateReasons,
          isNot(contains('expression_constraint_review_missing')),
        );
        expect(result.constraints.hardConstraintTriggered, isFalse);
        expect(result.constraints.summary, contains('当前项目没有启用 binding'));
        expect(result.validateBasics(), isEmpty);
      },
    );

    test('keeps external fact unverified as evidence repair signal', () {
      final result = normalizer.normalize(
        executionId: 'information_unverified_001',
        workflowKind: 'ordinary_project',
        informationSignal: const <String, Object?>{
          'external_fact_unverified_count': 2,
          'requires_repair': true,
          'reason': 'information_external_fact_unverified',
        },
      );

      expect(result.information.evidenceGate.externalFactUnverifiedCount, 2);
      expect(result.information.summary, contains('外部事实未核验 2 项'));
      expect(result.information.requiresRepair, isTrue);
    });
  });
}

WritingExecutionConstraintBridgeResult _constraintBridge() {
  // 中文注释: 这个夹具专门提供最小的字数与表达限制桥接结果，避免 focused tests 依赖 runtime 侧组装。
  return const WritingExecutionConstraintBridgeResult(
    chapterLengthMetadata: <String, Object?>{
      'chapter_word_target': 2200,
      'chapter_length_profile': <String, Object?>{
        'enabled': true,
        'target_length': 2200,
        'preferred_min': 1800,
        'preferred_max': 2600,
        'stage': 'draft',
        'metric_unit': 'visible_characters',
      },
    },
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
        ExpressionConstraintExecutionPolicyModes.adaptive,
    expressionConstraintInjectionStrength:
        ExpressionConstraintInjectionStrengths.sections,
    expressionConstraintReviewRequirement:
        ExpressionConstraintReviewRequirements.whenApplied,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.adjustNext,
    expressionConstraintApplied: true,
    expressionConstraintAppliedReasons: <String>['primary_writing_turn'],
    expressionConstraintInjectionMode: 'brief_and_sections',
    expressionConstraintReviewRequired: true,
    runtimeReport: <String, Object?>{
      'chapter_length': <String, Object?>{'applied': true, 'source': 'legacy'},
      'expression_constraints': <String, Object?>{
        'policy_mode': 'adaptive',
        'policy_applied': true,
      },
    },
  );
}

WritingExecutionConstraintBridgeResult _profileOnlyConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
    chapterLengthMetadata: <String, Object?>{
      'chapter_word_target': 2200,
      'chapter_length_profile': <String, Object?>{
        'enabled': true,
        'target_length': 2200,
        'preferred_min': 1800,
        'preferred_max': 2600,
        'stage': 'draft',
        'metric_unit': 'visible_characters',
      },
    },
    expressionConstraintProfiles: <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'natural_voice',
        displayName: '自然口语',
        summary: '避免模板化解释腔。',
        kind: ExpressionConstraintKind.naturalExpression,
        rules: <String>['减少工整排比。'],
      ),
    ],
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.adaptive,
    expressionConstraintInjectionStrength:
        ExpressionConstraintInjectionStrengths.sections,
    expressionConstraintReviewRequirement:
        ExpressionConstraintReviewRequirements.whenApplied,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.adjustNext,
    expressionConstraintInjectionMode: 'disabled',
    expressionConstraintReviewRequired: false,
    expressionConstraintApplied: false,
    expressionConstraintSkippedReasons: <String>[
      'no_expression_constraint_bindings',
    ],
    runtimeReport: <String, Object?>{
      'chapter_length': <String, Object?>{'applied': true, 'source': 'legacy'},
    },
  );
}

WritingExecutionConstraintBridgeResult _disabledConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
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
  );
}

WritingExecutionConstraintBridgeResult _skippedConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
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
        ExpressionConstraintExecutionPolicyModes.adaptive,
    expressionConstraintInjectionStrength:
        ExpressionConstraintInjectionStrengths.sections,
    expressionConstraintReviewRequirement:
        ExpressionConstraintReviewRequirements.whenApplied,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.adjustNext,
    expressionConstraintApplied: false,
    expressionConstraintTechnicalTurnExcluded: true,
    expressionConstraintSkippedReasons: <String>['tool_protocol_turn'],
    expressionConstraintInjectionMode: 'disabled',
    expressionConstraintReviewRequired: false,
  );
}

WritingExecutionConstraintBridgeResult
_forceOrchestrationSkippedConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
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
        ExpressionConstraintExecutionPolicyModes.force,
    expressionConstraintInjectionStrength:
        ExpressionConstraintInjectionStrengths.full,
    expressionConstraintReviewRequirement:
        ExpressionConstraintReviewRequirements.alwaysForWriting,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.repair,
    expressionConstraintApplied: false,
    expressionConstraintTechnicalTurnExcluded: true,
    expressionConstraintSkippedReasons: <String>['workflow_orchestration_turn'],
    expressionConstraintInjectionMode: 'disabled',
    expressionConstraintReviewRequired: false,
  );
}

WritingExecutionConstraintBridgeResult _runtimeEscalatedConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
    expressionConstraintProfiles: <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '避免模板化解释腔。',
        kind: ExpressionConstraintKind.naturalExpression,
        rules: <String>['减少工整排比。'],
        riskSignals: <String>['总而言之', '不是……而是……'],
      ),
    ],
    projectExpressionConstraintBindings: <ProjectExpressionConstraintBinding>[
      ProjectExpressionConstraintBinding(
        id: 'binding_1',
        profileId: 'de_ai',
        defaultForProject: true,
      ),
    ],
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.adaptive,
    expressionConstraintInjectionStrength:
        ExpressionConstraintInjectionStrengths.full,
    expressionConstraintReviewRequirement:
        ExpressionConstraintReviewRequirements.alwaysForWriting,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.remind,
    expressionConstraintApplied: true,
    expressionConstraintRuntimeEscalated: true,
    expressionConstraintInjectionMode: 'brief_and_sections',
    expressionConstraintReviewRequired: true,
  );
}

WritingExecutionConstraintBridgeResult _forceConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
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
  );
}

ChapterLengthEvaluation _balancedEvaluation() {
  // 中文注释: 平衡字数样本用来证明共享合同可以携带“通过但仍有约束存在”的轻量结果。
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

ChapterLengthEvaluation _severeEvaluation() {
  // 中文注释: 严重偏离样本用来证明新合同可以明确表达 content quality issue，而不是只留在 runtime 细节里。
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
      length: 800,
      sortOrder: 2,
      taskId: 'chapter_002',
      relativePath: 'chapters/ch02.md',
    ),
    level: 'severely_off',
    recommendedAction: 'review_or_repair',
    notes: const <String>['偏离已经明显，建议把它当成审稿/返修提示。'],
    targetDeviation: 1400,
    targetDeviationRatio: 0.63,
  );
}

ChapterLengthEvaluation _needsRebalanceEvaluation() {
  // 中文注释: 柔性偏离样本用来证明 gate 会提醒后续回调，但不会强行升级成返修。
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
      length: 2680,
      sortOrder: 2,
      taskId: 'chapter_003',
      relativePath: 'chapters/ch03.md',
    ),
    level: 'needs_rebalance',
    recommendedAction: 'adjust_next_chapter',
    notes: const <String>['偏离尚可消化，建议在下一章优先回调分布。'],
    targetDeviation: 480,
    targetDeviationRatio: 0.22,
  );
}

ContextActivationReport _activationReport({
  bool includeRequiredOmitted = false,
  bool includeTruncatedResearch = false,
}) {
  // 中文注释: activation 夹具既覆盖正常命中，也能覆盖 required 信息被省略的等待用户场景。
  return ContextActivationReport(
    reportId: 'activation_report_001',
    planId: 'activation_plan_001',
    source: 'project_information_activation',
    budgetChars: 2400,
    usedChars: 1600,
    items: <ContextActivationItem>[
      const ContextActivationItem(
        itemId: 'item_character_rule',
        source: 'project_knowledge_card',
        title: '主角说话习惯',
        targetPath: 'knowledge/人物关系摘要.md',
        refs: <NarrativeRef>[
          NarrativeRef(
            refType: NarrativeRefTypes.chapter,
            refId: 'chapter-01',
            relativePath: 'chapters/ch01.md',
            displayName: '第01章',
          ),
        ],
        activationReasons: <String>['required_context'],
        requestedChars: 400,
        includedChars: 320,
        selected: true,
        metadata: <String, Object?>{
          'required': true,
          'source_kind': 'project_knowledge_card',
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.user,
                'source_id': 'source-user-1',
              },
              'source_authority': InformationSourceAuthorities.userDeclared,
              'role_authority': InformationRoleAuthorities.user,
              'research_depth': InformationResearchDepths.none,
            },
          ],
        },
      ),
      if (includeRequiredOmitted)
        const ContextActivationItem(
          itemId: 'item_world_rule',
          source: 'project_knowledge_card',
          title: '轮回规则',
          targetPath: 'knowledge/世界规则摘要.md',
          refs: <NarrativeRef>[
            NarrativeRef(
              refType: NarrativeRefTypes.asset,
              refId: 'knowledge-world-rule',
              relativePath:
                  '.novel_agent/information/knowledge_cards/world-rule.json',
              displayName: '轮回规则事实源',
            ),
          ],
          activationReasons: <String>['required_context'],
          requestedChars: 600,
          includedChars: 0,
          omitted: true,
          omissionReason: 'budget_limit',
          metadata: <String, Object?>{
            'required': true,
            'source_kind': 'project_knowledge_card',
            'source_refs': <Object?>[
              <String, Object?>{
                'source_ref': <String, Object?>{
                  'source_type': NarrativeSourceTypes.explainer,
                  'source_id': 'analysis-1',
                },
                'source_authority':
                    InformationSourceAuthorities.analysisInterpreted,
                'role_authority': InformationRoleAuthorities.explainer,
                'research_depth': InformationResearchDepths.quick,
              },
            ],
          },
        ),
      if (includeTruncatedResearch)
        const ContextActivationItem(
          itemId: 'item_research_trace',
          source: 'project_research_note',
          title: '镜潮资料',
          targetPath: 'research/资料研究摘要.md',
          activationReasons: <String>['reference_context'],
          requestedChars: 520,
          includedChars: 180,
          selected: true,
          truncated: true,
          truncationReason: 'budget_clip',
          metadata: <String, Object?>{
            'source_kind': 'project_research_note',
            'research_source_kind': 'web_article',
            'source_url_or_ref': 'https://example.com/mirror-tide',
            'citation': 'Mirror Tide',
          },
        ),
    ],
    selectedItemIds: includeTruncatedResearch
        ? const <String>['item_character_rule', 'item_research_trace']
        : const <String>['item_character_rule'],
    omittedItemIds: includeRequiredOmitted
        ? const <String>['item_world_rule']
        : const <String>[],
    truncatedItemIds: includeTruncatedResearch
        ? const <String>['item_research_trace']
        : const <String>[],
    summary: '已注入角色说话习惯和关键设定。',
  );
}

ChapterDeliveryStateResult _deliveryState({
  required String state,
  required String recommendedAction,
  required String suggestedOutcomeStatus,
  String reason = 'delivery_complete',
  String summary = '',
  bool blocksProgress = false,
  bool chapterBodyDelivered = false,
  bool submissionAccepted = false,
  bool retryable = false,
  ChapterDeliveryFailure? deliveryFailure,
  JsonMap metadata = const <String, Object?>{},
}) {
  // 中文注释: 章节交付夹具直接复用现有状态机结果合同，验证新共享合同不会重新造平行 delivery 类型。
  return ChapterDeliveryStateResult(
    deliveryId: 'delivery_001',
    state: state,
    recommendedAction: recommendedAction,
    suggestedOutcomeStatus: suggestedOutcomeStatus,
    reason: reason,
    summary: summary,
    blocksProgress: blocksProgress,
    chapterBodyDelivered: chapterBodyDelivered,
    submissionAccepted: submissionAccepted,
    retryable: retryable,
    deliveryFailure: deliveryFailure,
    metadata: metadata,
  );
}
