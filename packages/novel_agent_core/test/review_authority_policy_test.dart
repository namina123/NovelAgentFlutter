import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewAuthorityPolicy', () {
    test('standard project and long task differ only by trigger authority', () {
      const standard = ReviewAuthorityPolicy.standardProject();
      const longTask = ReviewAuthorityPolicy.longTask();

      expect(standard.validateBasics(), isEmpty);
      expect(longTask.validateBasics(), isEmpty);
      expect(
        standard.triggerAuthority,
        ReviewTriggerAuthorities.agentGroupPolicy,
      );
      expect(
        longTask.triggerAuthority,
        ReviewTriggerAuthorities.runtimeSupervisorPolicy,
      );
      expect(
        standard.executionAuthority,
        longTask.executionAuthority,
      );
      expect(
        standard.schedulingAuthority,
        longTask.schedulingAuthority,
      );
    });

    test('codec preserves unknown fields through metadata bag', () {
      final policy = ReviewAuthorityPolicy.fromJson(<String, Object?>{
        'trigger_authority': ReviewTriggerAuthorities.runtimeSupervisorPolicy,
        'future_switch': <String, Object?>{'enabled': true},
        'metadata': <String, Object?>{'source': 'test'},
      });

      final encoded = policy.toJson();

      expect(policy.validateBasics(), isEmpty);
      expect(policy.metadata['source'], 'test');
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_switch'])['enabled'],
        ),
        isTrue,
      );
    });

    test('validation reports invalid authority values', () {
      final invalid = ReviewAuthorityPolicy.fromJson(<String, Object?>{
        'trigger_authority': 'writer_decides',
        'execution_authority': 'reviewer_decides_schedule',
        'scheduling_authority': 'reviewer_executes_followup',
      });

      expect(
        invalid.validateBasics(),
        containsAll(<String>[
          ReviewAuthorityPolicyValidationCodes.invalidTriggerAuthority,
          ReviewAuthorityPolicyValidationCodes.invalidExecutionAuthority,
          ReviewAuthorityPolicyValidationCodes.invalidSchedulingAuthority,
        ]),
      );
    });
  });
}
