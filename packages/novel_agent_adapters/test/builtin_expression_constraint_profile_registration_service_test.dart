import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('BuiltinExpressionConstraintProfileRegistrationService', () {
    test('registers the first builtin expression constraint presets', () {
      final service = BuiltinExpressionConstraintProfileRegistrationService();

      final profiles = service.registeredProfiles();

      expect(profiles.map((profile) => profile.id), contains('de_ai'));
      expect(
        profiles.map((profile) => profile.id),
        containsAll(<String>['strict_pov_boundary', 'low_jargon_narration']),
      );
      final deAi = profiles.firstWhere((profile) => profile.id == 'de_ai');
      expect(deAi.rules, isNotEmpty);
      expect(deAi.metadata['builtin'], isTrue);
    });
  });
}
