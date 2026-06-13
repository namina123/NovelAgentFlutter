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
      expect(
        deAi.rules,
        contains('少把“行，……”“行, ……”这类突兀口头起手句当作轻松感捷径；人物真要口头化时，先让语气、动作和上下文把口吻托住。'),
      );
      expect(deAi.riskSignals, contains('“行，'));
      expect(deAi.riskSignals, contains('“行,'));
      expect(deAi.metadata['builtin'], isTrue);
    });
  });
}
