import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintInjectionPolicyService', () {
    const service = ExpressionConstraintInjectionPolicyService();

    test('uses brief and sections for draft generation', () {
      final mode = service.resolveMode(intent: 'draft');

      expect(mode, ExpressionConstraintInjectionMode.briefAndSections);
      expect(service.modeId(mode), 'brief_and_sections');
    });

    test('uses brief only for review and postprocess turns', () {
      final reviewMode = service.resolveMode(intent: 'review');
      final postprocessMode = service.resolveMode(
        intent: 'review',
        phase: 'chapter_postprocess',
      );

      expect(reviewMode, ExpressionConstraintInjectionMode.briefOnly);
      expect(postprocessMode, ExpressionConstraintInjectionMode.briefOnly);
    });

    test(
      'disables expression constraints for non-creative turns by default',
      () {
        final mode = service.resolveMode(intent: 'chat');

        expect(mode, ExpressionConstraintInjectionMode.disabled);
      },
    );
  });
}
