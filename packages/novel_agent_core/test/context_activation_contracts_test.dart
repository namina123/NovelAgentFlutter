import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContextActivation contracts', () {
    test('plan preserves reasons refs and budget intent', () {
      const codec = ContextActivationCodecService();
      final plan = codec.planFromJson(<String, Object?>{
        'plan_id': 'activation-plan-001',
        'source': 'project_context_selection',
        'task_type': 'chapter_draft',
        'budget_chars': 3200,
        'reserved_output_chars': 1800,
        'items': <Object?>[
          <String, Object?>{
            'item_id': 'item-001',
            'source': 'continuity_projection',
            'title': '上一章结尾状态',
            'target_path': 'continuity/最近状态变化.md',
            'refs': <Object?>[
              <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapter-009',
              },
            ],
            'activation_reasons': <Object?>[
              ContextActivationReasonCodes.ref,
              ContextActivationReasonCodes.claim,
            ],
            'reason_details': <String, Object?>{
              'claim_ids': <Object?>['claim-009-end'],
            },
            'requested_chars': 900,
          },
        ],
        'summary': '优先纳入章节连续性和当前任务所需规则。',
        'schema_version': 'ons-10',
      });

      final encoded = codec.planToJson(plan);
      final item =
          (encoded['items'] as List<Object?>).single as Map<String, Object?>;

      expect(plan.validateBasics(), isEmpty);
      expect(plan.budgetChars, 3200);
      expect(
        item['activation_reasons'] as List<Object?>,
        containsAll(<Object?>[
          ContextActivationReasonCodes.ref,
          ContextActivationReasonCodes.claim,
        ]),
      );
      expect(
        ((item['refs'] as List<Object?>).single
            as Map<String, Object?>)['ref_id'],
        'chapter-009',
      );
    });

    test('report explains selected omitted and truncated items', () {
      const codec = ContextActivationCodecService();
      final report = codec.reportFromJson(<String, Object?>{
        'report_id': 'activation-report-001',
        'plan_id': 'activation-plan-001',
        'source': 'context_budget_service',
        'budget_chars': 3200,
        'used_chars': 3100,
        'omitted_chars': 1400,
        'items': <Object?>[
          <String, Object?>{
            'item_id': 'item-selected',
            'source': 'project_file',
            'title': '世界观规则',
            'activation_reasons': <Object?>[
              ContextActivationReasonCodes.profilePolicy,
              ContextActivationReasonCodes.taskType,
            ],
            'requested_chars': 1800,
            'included_chars': 1600,
            'selected': true,
            'truncated': true,
            'truncation_reason': 'budget_clip',
          },
          <String, Object?>{
            'item_id': 'item-omitted',
            'source': 'semantic_memory',
            'title': '扩展分析摘要',
            'activation_reasons': <Object?>[
              ContextActivationReasonCodes.semanticRetrieval,
            ],
            'requested_chars': 1400,
            'included_chars': 0,
            'omitted': true,
            'omission_reason': 'budget_exhausted',
          },
        ],
        'selected_item_ids': <Object?>['item-selected'],
        'omitted_item_ids': <Object?>['item-omitted'],
        'truncated_item_ids': <Object?>['item-selected'],
        'summary': '纳入 1 条，省略 1 条，截断 1 条。',
      });

      final encoded = codec.reportToJson(report);

      expect(report.validateBasics(), isEmpty);
      expect(report.selectedItemIds, contains('item-selected'));
      expect(report.omittedItemIds, contains('item-omitted'));
      expect(report.truncatedItemIds, contains('item-selected'));
      expect(
        (((encoded['items'] as List<Object?>).first
            as Map<String, Object?>)['truncated']),
        isTrue,
      );
    });

    test('manual pin and keyword reasons remain open strings', () {
      final item = ContextActivationItem.fromJson(<String, Object?>{
        'item_id': 'item-open-001',
        'source': 'manual_selection',
        'activation_reasons': <Object?>[
          ContextActivationReasonCodes.manualPin,
          ContextActivationReasonCodes.keyword,
          'future.reason.code',
        ],
        'requested_chars': 300,
        'included_chars': 300,
        'selected': true,
      });

      expect(item.validateBasics(), isEmpty);
      expect(item.activationReasons, contains('future.reason.code'));
    });

    test(
      'validation catches missing ids negative budgets and impossible item state',
      () {
        final report = ContextActivationReport.fromJson(<String, Object?>{
          'report_id': '',
          'plan_id': '',
          'source': '',
          'budget_chars': -1,
          'used_chars': -2,
          'items': <Object?>[
            <String, Object?>{
              'item_id': '',
              'source': '',
              'activation_reasons': <Object?>[],
              'requested_chars': -1,
              'included_chars': -1,
              'selected': true,
              'omitted': true,
              'truncated': true,
            },
          ],
        });

        expect(
          report.validateBasics(),
          containsAll(<String>[
            ContextActivationValidationCodes.missingReportId,
            ContextActivationValidationCodes.missingPlanId,
            ContextActivationValidationCodes.missingSource,
            ContextActivationValidationCodes.invalidBudgetChars,
            ContextActivationValidationCodes.invalidUsedChars,
            ContextActivationValidationCodes.missingItemId,
            ContextActivationValidationCodes.missingActivationReason,
            ContextActivationValidationCodes.invalidRequestedChars,
            ContextActivationValidationCodes.invalidIncludedChars,
            ContextActivationValidationCodes.conflictingSelectionState,
          ]),
        );
      },
    );
  });
}
