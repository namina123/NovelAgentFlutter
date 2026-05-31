import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_binding_action_service.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('uses structured selected agent ids before legacy text parsing', () {
    const service = ProjectExpressionConstraintBindingActionService();

    final bindings = service.upsertBinding(
      currentBindings: const <ProjectExpressionConstraintBinding>[],
      profile: const ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '压低模板化表达。',
      ),
      request: const ExpressionConstraintBindingEditorRequestViewData(
        profileId: 'de_ai',
        enabled: true,
        defaultForProject: false,
        selectedAgentIds: <String>['reviewer', 'writer'],
        selectedModeIds: <String>[],
        selectedStageIds: <String>[],
        targetAgentIdsText: 'legacy-id-should-not-win',
        targetModeIdsText: '',
        targetStageIdsText: '',
        weightText: '100',
      ),
    );

    expect(bindings.single.targetAgentIds, <String>['reviewer', 'writer']);
  });

  test('uses structured selected mode and stage ids before legacy text parsing', () {
    const service = ProjectExpressionConstraintBindingActionService();

    final bindings = service.upsertBinding(
      currentBindings: const <ProjectExpressionConstraintBinding>[],
      profile: const ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '压低模板化表达。',
      ),
      request: const ExpressionConstraintBindingEditorRequestViewData(
        profileId: 'de_ai',
        enabled: true,
        defaultForProject: false,
        selectedAgentIds: <String>[],
        selectedModeIds: <String>['full_outline_consensus'],
        selectedStageIds: <String>['book_premise'],
        targetAgentIdsText: '',
        targetModeIdsText: 'legacy-mode',
        targetStageIdsText: 'legacy-stage',
        weightText: '100',
      ),
    );

    expect(bindings.single.targetModeIds, <String>['full_outline_consensus']);
    expect(bindings.single.targetStageIds, <String>['book_premise']);
  });
}
