import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskProjectFileSectionPlanService', () {
    final service = LongTaskProjectFileSectionPlanService(
      pathPolicyService: LongTaskPathPolicyService(),
    );

    test(
      'splits persistent paths and task source paths into planned sections',
      () {
        final sections = service.build(const <String, Object?>{
          'source_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'styles/seed_autopilot_style.md',
            'outline/总纲.md',
          ],
          'metadata': <String, Object?>{
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
              'styles/seed_autopilot_style.md',
            ],
          },
        });

        expect(sections, hasLength(2));
        expect(
          ValueReaders.stringValue(sections.first['id']),
          'task_persistent_context',
        );
        expect(
          ValueReaders.stringList(sections.first['paths']),
          contains('styles/seed_autopilot_style.md'),
        );
        expect(
          ValueReaders.stringValue(sections.last['id']),
          'task_source_paths',
        );
        expect(ValueReaders.stringList(sections.last['paths']), <String>[
          'outline/总纲.md',
        ]);
      },
    );
  });
}
