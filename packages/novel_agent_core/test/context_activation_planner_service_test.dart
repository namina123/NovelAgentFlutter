import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContextActivationPlannerService', () {
    test(
      'prioritizes required and pinned items before ordinary candidates',
      () {
        const service = ContextActivationPlannerService();
        final plan = ContextActivationPlan.fromJson(<String, Object?>{
          'plan_id': 'plan-priority',
          'source': 'project_context_selection',
          'task_type': 'chapter_draft',
          'budget_chars': 1200,
          'reserved_output_chars': 200,
          'items': <Object?>[
            _itemJson(
              itemId: 'ordinary-heavy',
              requestedChars: 700,
              reasons: <String>[ContextActivationReasonCodes.keyword],
              reasonDetails: <String, Object?>{'weight': 10},
            ),
            _itemJson(
              itemId: 'required-core',
              requestedChars: 400,
              reasons: <String>[ContextActivationReasonCodes.profilePolicy],
              reasonDetails: <String, Object?>{'required': true},
            ),
            _itemJson(
              itemId: 'pinned-note',
              requestedChars: 500,
              reasons: <String>[ContextActivationReasonCodes.manualPin],
            ),
          ],
        });

        final report = service.buildReport(plan: plan);

        expect(report.budgetChars, 1000);
        expect(report.selectedItemIds, <String>[
          'required-core',
          'pinned-note',
          'ordinary-heavy',
        ]);
        final truncated = report.items.singleWhere(
          (item) => item.itemId == 'ordinary-heavy',
        );
        expect(truncated.selected, isTrue);
        expect(truncated.truncated, isTrue);
        expect(truncated.includedChars, 100);
        expect(truncated.truncationReason, 'budget_clip');
      },
    );

    test('omits lower-priority items after budget is exhausted', () {
      const service = ContextActivationPlannerService();
      final plan = ContextActivationPlan.fromJson(<String, Object?>{
        'plan_id': 'plan-budget',
        'source': 'project_context_selection',
        'task_type': 'review',
        'budget_chars': 1000,
        'reserved_output_chars': 100,
        'items': <Object?>[
          _itemJson(
            itemId: 'core-rule',
            requestedChars: 500,
            reasons: <String>[ContextActivationReasonCodes.profilePolicy],
          ),
          _itemJson(
            itemId: 'claim-context',
            requestedChars: 400,
            reasons: <String>[ContextActivationReasonCodes.claim],
          ),
          _itemJson(
            itemId: 'retrieved-extra',
            requestedChars: 300,
            reasons: <String>[ContextActivationReasonCodes.semanticRetrieval],
          ),
        ],
      });

      final report = service.buildReport(plan: plan);

      expect(report.budgetChars, 900);
      expect(report.usedChars, 900);
      expect(report.selectedItemIds, <String>['core-rule', 'claim-context']);
      expect(report.omittedItemIds, <String>['retrieved-extra']);
      expect(report.omittedChars, 300);
      expect(
        report.items
            .singleWhere((item) => item.itemId == 'retrieved-extra')
            .omissionReason,
        'budget_exhausted',
      );
    });

    test(
      'required item remains selected with explicit truncated reason when no budget remains',
      () {
        const service = ContextActivationPlannerService();
        final plan = ContextActivationPlan.fromJson(<String, Object?>{
          'plan_id': 'plan-required',
          'source': 'project_context_selection',
          'task_type': 'chapter_draft',
          'budget_chars': 300,
          'reserved_output_chars': 300,
          'items': <Object?>[
            _itemJson(
              itemId: 'required-world-rule',
              requestedChars: 250,
              reasons: <String>[ContextActivationReasonCodes.profilePolicy],
              metadata: <String, Object?>{'required': true},
            ),
            _itemJson(
              itemId: 'optional-summary',
              requestedChars: 200,
              reasons: <String>[ContextActivationReasonCodes.keyword],
            ),
          ],
        });

        final report = service.buildReport(plan: plan);

        final requiredItem = report.items.singleWhere(
          (item) => item.itemId == 'required-world-rule',
        );
        final optionalItem = report.items.singleWhere(
          (item) => item.itemId == 'optional-summary',
        );

        expect(report.budgetChars, 0);
        expect(requiredItem.selected, isTrue);
        expect(requiredItem.truncated, isTrue);
        expect(requiredItem.includedChars, 0);
        expect(requiredItem.truncationReason, 'required_budget_exhausted');
        expect(optionalItem.omitted, isTrue);
        expect(optionalItem.omissionReason, 'budget_exhausted');
      },
    );
  });
}

Map<String, Object?> _itemJson({
  required String itemId,
  required int requestedChars,
  required List<String> reasons,
  Map<String, Object?> reasonDetails = const <String, Object?>{},
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  return <String, Object?>{
    'item_id': itemId,
    'source': 'project_file',
    'title': itemId,
    'activation_reasons': reasons,
    'reason_details': reasonDetails,
    'requested_chars': requestedChars,
    'metadata': metadata,
  };
}
