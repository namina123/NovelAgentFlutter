import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/settings/application/services/project_creation_expression_constraint_defaults_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'builtin fallback summary includes all builtin expression constraints',
    () {
      final service =
          ProjectCreationExpressionConstraintDefaultsViewDataService();

      final viewData = service.build(
        const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
        ),
      );

      expect(viewData.fallbackSummary, '去 AI 风、严格 POV 边界、降低术语分析腔');
      expect(
        viewData.options.where((option) => option.isSelected).map((e) => e.id),
        containsAll(<String>[
          'de_ai',
          'strict_pov_boundary',
          'low_jargon_narration',
        ]),
      );
    },
  );
}
