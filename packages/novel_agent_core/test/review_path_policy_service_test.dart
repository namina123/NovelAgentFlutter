import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewPathPolicyService', () {
    final service = ReviewPathPolicyService();

    test('converts markdown and json sibling paths safely', () {
      expect(
        service.reviewJsonPath('reviews/continuity/ch01.md'),
        'reviews/continuity/ch01.json',
      );
      expect(
        service.reviewMarkdownPath('reviews/continuity/ch01.json'),
        'reviews/continuity/ch01.md',
      );
    });

    test('rejects invalid paths outside reviews root', () {
      expect(service.reviewJsonPath('drafts/ch01.md'), isEmpty);
      expect(service.reviewMarkdownPath('../reviews/ch01.json'), isEmpty);
    });
  });
}
