import 'package:test/test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectCapabilityService.hasBookDeconstruction', () {
    final service = ProjectCapabilityService();

    test('projectType=book_deconstruction 退化识别为 true（旧项目）', () {
      expect(
        service.hasBookDeconstruction(
          projectTypeId: BookDeconstructionConstants.projectTypeId,
        ),
        isTrue,
      );
    });

    test('复合项目：projectType=novel + 持久化 book_deconstruction trait 为 true', () {
      expect(
        service.hasBookDeconstruction(
          projectTypeId: 'novel',
          additionalTraitIds: const <String>['book_deconstruction'],
        ),
        isTrue,
      );
    });

    test('普通小说项目无拆书能力', () {
      expect(service.hasBookDeconstruction(projectTypeId: 'novel'), isFalse);
    });

    test('复合后切到 long_novel 仍保留拆书能力', () {
      expect(
        service.hasBookDeconstruction(
          projectTypeId: 'long_novel',
          additionalTraitIds: const <String>['book_deconstruction'],
        ),
        isTrue,
      );
    });
  });
}
