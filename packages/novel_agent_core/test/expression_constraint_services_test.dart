import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectExpressionConstraintBindingResolverService', () {
    test('resolves enabled bindings by scope and weight', () {
      const resolver = ProjectExpressionConstraintBindingResolverService();

      final profileIds = resolver.resolveProfileIds(
        const <ProjectExpressionConstraintBinding>[
          ProjectExpressionConstraintBinding(
            id: 'draft-natural',
            profileId: 'de_ai',
            defaultForProject: true,
            targetModeIds: <String>['draft'],
            weight: 120,
          ),
          ProjectExpressionConstraintBinding(
            id: 'writer-jargon',
            profileId: 'low_jargon_narration',
            targetAgentIds: <String>['writer'],
            weight: 100,
          ),
          ProjectExpressionConstraintBinding(
            id: 'disabled',
            profileId: 'strict_pov_boundary',
            enabled: false,
          ),
        ],
        availableProfiles: const <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'de_ai',
            displayName: '去 AI 风',
            summary: '降低模板化表达和解释腔。',
          ),
          ExpressionConstraintProfile(
            id: 'low_jargon_narration',
            displayName: '降低术语分析腔',
            summary: '压低职业化和空心分析词。',
          ),
          ExpressionConstraintProfile(
            id: 'strict_pov_boundary',
            displayName: '严格 POV 边界',
            summary: '限制未知信息越界。',
          ),
        ],
        agentId: 'writer',
        modeId: 'draft',
      );

      expect(profileIds, <String>['de_ai', 'low_jargon_narration']);
    });
  });

  group('Expression constraint renderers', () {
    const constraints = <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '降低模板化表达和解释腔。',
        kind: ExpressionConstraintKind.naturalExpression,
        rules: <String>['少用工整排比与空心总结。'],
        riskSignals: <String>['不是……而是……'],
      ),
    ];

    test('brief renderer produces compact summary lines', () {
      const renderer = ExpressionConstraintBriefRenderer();
      final lines = renderer.renderLines(constraints);

      expect(lines.first, '表达限制：去 AI 风');
      expect(lines.last, contains('自然表达'));
      expect(lines.last, contains('降低模板化表达和解释腔。'));
    });

    test('context section service renders structured sections', () {
      const service = ExpressionConstraintContextSectionService();
      final sections = service.buildSections(constraints);

      expect(sections, hasLength(1));
      expect(sections.single['creative_layer'], 'expression_constraint');
      expect(sections.single['content'], contains('执行规则：'));
      expect(sections.single['content'], contains('风险信号（交付前自查'));
    });

    test(
      'context section exposes every risk signal so the scanner and prompt agree',
      () {
        // 中文注释: 内置 de_ai 有 11 条 risk_signals，但渲染曾截断到 8，导致模型看不到
        // 第 9-11 条，却被扫描器按全部 11 条判定违反。这里用 >8 条信号验证全部进入提示词。
        const service = ExpressionConstraintContextSectionService();
        final signals = List<String>.generate(11, (i) => '信号${i + 1}');
        final sections = service.buildSections(const <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'many_signals',
            displayName: '多信号限制',
            summary: '验证信号不被截断。',
            riskSignals: <String>[
              '信号1',
              '信号2',
              '信号3',
              '信号4',
              '信号5',
              '信号6',
              '信号7',
              '信号8',
              '信号9',
              '信号10',
              '信号11',
            ],
          ),
        ]);
        final content = ValueReaders.stringValue(sections.single['content']);
        for (final signal in signals) {
          expect(content, contains(signal));
        }
      },
    );
  });

  group('ExpressionConstraintSurfaceRiskScanService', () {
    const service = ExpressionConstraintSurfaceRiskScanService();

    test('builds review evidence from profile risk signal hits', () {
      final review = service.scan(
        profiles: const <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'de_ai',
            displayName: '去 AI 风',
            summary: '降低模板化表达和解释腔。',
            kind: ExpressionConstraintKind.naturalExpression,
            riskSignals: <String>['——', '不是……而是……'],
          ),
        ],
        texts: const <String>['他停了一下——不是因为害怕，而是终于看懂了账本里的问题——这太明显了。'],
      );

      expect(review.isEmpty, isFalse);
      expect(
        review.authenticityPassLevel,
        ExpressionConstraintReviewProjection.authenticityAggressive,
      );
      expect(
        review.miniRecheckItems.join('\n'),
        contains('正文表面风险命中：去 AI 风：—— x2'),
      );
      expect(review.miniRecheckItems.join('\n'), contains('不是……而是…… x1'));
    });

    test(
      'detects abrupt quote-leading "行，" pattern as natural-expression risk',
      () {
        final review = service.scan(
          profiles: const <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              riskSignals: <String>['“行，'],
            ),
          ],
          texts: const <String>['“行，至少不无聊。”他低声说。'],
        );

        expect(review.isEmpty, isFalse);
        expect(review.miniRecheckItems.join('\n'), contains('“行， x1'));
      },
    );

    test('keeps merged review evidence without dropping base notes', () {
      final merged = service.merge(
        const ExpressionConstraintReviewProjection(
          reviewFocuses: <String>['保留人物声音'],
          voiceProtectionNotes: <String>['不要洗平口吻。'],
        ),
        const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['正文表面风险命中：去 AI 风：—— x4'],
        ),
      );

      expect(
        merged.authenticityPassLevel,
        ExpressionConstraintReviewProjection.authenticityAggressive,
      );
      expect(merged.reviewFocuses, contains('保留人物声音'));
      expect(merged.miniRecheckItems, contains('正文表面风险命中：去 AI 风：—— x4'));
      expect(merged.voiceProtectionNotes, contains('不要洗平口吻。'));
    });

    test('scans only enabled bound profiles when bindings are provided', () {
      final review = service.scan(
        profiles: const <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'de_ai',
            displayName: '去 AI 风',
            summary: '降低模板化表达和解释腔。',
            kind: ExpressionConstraintKind.naturalExpression,
            riskSignals: <String>['——'],
          ),
          ExpressionConstraintProfile(
            id: 'strict_pov_boundary',
            displayName: '严格 POV 边界',
            summary: '限制未知信息越界。',
            kind: ExpressionConstraintKind.narrativeBoundary,
            riskSignals: <String>['他并不知道'],
          ),
        ],
        bindings: const <ProjectExpressionConstraintBinding>[
          ProjectExpressionConstraintBinding(
            id: 'binding_de_ai',
            profileId: 'de_ai',
          ),
        ],
        texts: const <String>['他并不知道这件事——但他还是继续往前走。'],
      );

      expect(review.miniRecheckItems.join('\n'), contains('—— x1'));
      expect(review.continuityWatchItems.join('\n'), isNot(contains('他并不知道')));
    });
  });

  group('Expression constraint gate signal service', () {
    const service = ExpressionConstraintGateSignalService();

    test('keeps light review as informational natural usage signal', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              rules: <String>['少用工整排比与空心总结。'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
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
          expressionConstraintInjectionMode: 'brief_and_sections',
          expressionConstraintReviewRequired: true,
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityLight,
          reviewFocuses: <String>['保留人物口语纹理'],
          voiceProtectionNotes: <String>['不要把人物说话习惯洗平。'],
        ),
      );

      expect(signal.present, isTrue);
      expect(signal.severity, ExpressionConstraintGateSeverities.info);
      expect(
        signal.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.none,
      );
      expect(signal.naturalUsage, isTrue);
      expect(signal.repairRequired, isFalse);
    });

    test('uses force repair for aggressive surface risk evidence', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              riskSignals: <String>['——'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
                  defaultForProject: true,
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.full,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.none,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['正文表面风险命中：去 AI 风：—— x6'],
        ),
      );

      expect(signal.present, isTrue);
      expect(signal.repairRequired, isTrue);
      expect(
        signal.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.repair,
      );
      expect(signal.riskSignals, contains('正文表面风险命中：去 AI 风：—— x6'));
    });

    test('keeps low residual surface risks as reminder after cleanup', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              riskSignals: <String>['——', '不是因为'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
                  defaultForProject: true,
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.full,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.none,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityMedium,
          miniRecheckItems: <String>[
            '正文表面风险命中：去 AI 风：—— x1',
            '正文表面风险命中：去 AI 风：不是因为 x1',
          ],
        ),
      );

      expect(signal.present, isTrue);
      expect(
        signal.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.remind,
      );
      expect(signal.repairRequired, isFalse);
    });

    test('reports only active bound profile risk signals', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              riskSignals: <String>['——'],
            ),
            ExpressionConstraintProfile(
              id: 'strict_pov_boundary',
              displayName: '严格 POV 边界',
              summary: '限制未知信息越界。',
              kind: ExpressionConstraintKind.narrativeBoundary,
              riskSignals: <String>['他并不知道'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_de_ai',
                  profileId: 'de_ai',
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.full,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.none,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['正文表面风险命中：去 AI 风：—— x6'],
        ),
      );

      expect(signal.riskSignals, contains('正文表面风险命中：去 AI 风：—— x6'));
      expect(signal.riskSignals, isNot(contains('他并不知道')));
    });

    test('uses repair when adaptive policy was runtime-escalated', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              rules: <String>['少用工整排比与空心总结。'],
              riskSignals: <String>['总而言之', '不是……而是……'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
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
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintRuntimeEscalated: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
          expressionConstraintReviewRequired: true,
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          reviewFocuses: <String>['继续压低总结腔'],
          miniRecheckItems: <String>['检查结尾是否又回到概述句', '检查中段是否重复解释'],
        ),
      );

      expect(signal.present, isTrue);
      expect(signal.repeatedPattern, isTrue);
      expect(signal.severity, ExpressionConstraintGateSeverities.blocking);
      expect(
        signal.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.repair,
      );
      expect(signal.adjustNextChapter, isFalse);
      expect(signal.repairRequired, isTrue);
      expect(signal.riskSignals, contains('检查结尾是否又回到概述句'));
    });

    test('keeps non-escalated adaptive repeated risks as adjust next', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              rules: <String>['少用工整排比与空心总结。'],
              riskSignals: <String>['总而言之', '不是……而是……'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
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
          expressionConstraintInjectionMode: 'brief_and_sections',
          expressionConstraintReviewRequired: true,
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          reviewFocuses: <String>['继续压低总结腔'],
          miniRecheckItems: <String>['检查结尾是否又回到概述句', '检查中段是否重复解释'],
        ),
      );

      expect(signal.present, isTrue);
      expect(signal.repeatedPattern, isTrue);
      expect(signal.severity, ExpressionConstraintGateSeverities.warning);
      expect(
        signal.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.adjustNext,
      );
      expect(signal.adjustNextChapter, isTrue);
      expect(signal.repairRequired, isFalse);
    });

    test('uses force repair for structural risk', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'strict_pov_boundary',
              displayName: '严格 POV 边界',
              summary: '限制未知信息越界。',
              kind: ExpressionConstraintKind.narrativeBoundary,
              rules: <String>['只保留 POV 可知信息。'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
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
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          continuityWatchItems: <String>['视角泄漏'],
          miniRecheckItems: <String>['检查是否越过当前角色可知边界'],
        ),
      );

      expect(signal.present, isTrue);
      expect(signal.severity, ExpressionConstraintGateSeverities.blocking);
      expect(
        signal.recommendedDisposition,
        ExpressionConstraintGateRecommendedDispositions.repair,
      );
      expect(signal.repairRequired, isTrue);
    });

    test('keeps disabled policy out of gate flow', () {
      final signal = service.build(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
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
          expressionConstraintInjectionMode: 'disabled',
          expressionConstraintReviewRequired: false,
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['这里其实不会被 gate 消费'],
        ),
      );

      expect(signal.present, isFalse);
      expect(signal.validateBasics(), isEmpty);
    });
  });

  group('ExpressionConstraintSupervisorSignalService', () {
    test('uses the shared force gate disposition for surface risks', () {
      const service = ExpressionConstraintSupervisorSignalService();

      final signal = service.signalFromBridgeResult(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
              riskSignals: <String>['——'],
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_de_ai',
                  profileId: 'de_ai',
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.full,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.none,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['正文表面风险命中：去 AI 风：—— x5'],
        ),
      );

      expect(ValueReaders.stringValue(signal['category']), 'light_repair');
      expect(
        ValueReaders.stringValue(signal['gate_disposition']),
        ExpressionConstraintGateRecommendedDispositions.repair,
      );
      expect(ValueReaders.boolValue(signal['repair_required']), isTrue);
      expect(
        ValueReaders.stringValue(signal['gate_reason']),
        'expression_constraint_force_repair_repeated_pattern',
      );
    });

    test('keeps reminder-only expression signals in suggest_strengthen', () {
      const service = ExpressionConstraintSupervisorSignalService();

      final signal = service.signalFromBridgeResult(
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_de_ai',
                  profileId: 'de_ai',
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
          expressionConstraintReviewRequired: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityMedium,
          miniRecheckItems: <String>['确认真实性清理后主角与关键说话者仍然保留各自声音。'],
        ),
      );

      expect(
        ValueReaders.stringValue(signal['category']),
        'suggest_strengthen',
      );
      expect(ValueReaders.boolValue(signal['repair_required']), isFalse);
      expect(
        ValueReaders.stringValue(signal['gate_disposition']),
        ExpressionConstraintGateRecommendedDispositions.remind,
      );
    });
  });
}
