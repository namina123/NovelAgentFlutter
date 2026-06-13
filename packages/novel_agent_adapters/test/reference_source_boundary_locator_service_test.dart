import 'package:novel_agent_adapters/src/reference_extraction/reference_source_boundary_locator_service.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceBoundaryLocatorService', () {
    const service = ReferenceSourceBoundaryLocatorService();

    test('prefers nearby explicit chapter boundaries around the target', () {
      final chapterA = 'CHAPTER ONE\n${'a' * 530}\n\n';
      final chapterB = 'CHAPTER TWO\n${'b' * 530}\n\n';
      final chapterC = 'CHAPTER THREE\n${'c' * 530}\n\n';
      final sourceText = '$chapterA$chapterB$chapterC';

      final location = service.locateNearTarget(
        sourceText: sourceText,
        targetChars: 560,
        chapterToleranceChars: 120,
      );

      expect(location.boundaryKind, ReferenceSourceBoundaryKinds.chapterStart);
      expect(location.sectionHeading, 'CHAPTER TWO');
      expect(location.distanceFromTarget, lessThanOrEqualTo(40));
      expect(location.previewAfter, contains('bbbb'));
    });

    test('falls back to paragraph break when no chapter boundary is near', () {
      final paragraphA = '${'前文' * 240}\n\n';
      final paragraphB = '${'中段' * 260}\n\n';
      final paragraphC = '${'后文' * 260}\n\n';
      final sourceText = '$paragraphA$paragraphB$paragraphC';

      final location = service.locateNearTarget(
        sourceText: sourceText,
        targetChars: 980,
        chapterToleranceChars: 20,
        paragraphSearchWindowChars: 120,
      );

      expect(
        location.boundaryKind,
        anyOf(
          ReferenceSourceBoundaryKinds.paragraphBreak,
          ReferenceSourceBoundaryKinds.lineBreak,
        ),
      );
      expect(location.boundaryOffset, greaterThan(900));
      expect(location.distanceFromTarget, lessThanOrEqualTo(120));
    });

    test('returns below-target marker when source is shorter than target', () {
      final location = service.locateNearTarget(
        sourceText: '短文本',
        targetChars: 1000000,
      );

      expect(location.boundaryKind, ReferenceSourceBoundaryKinds.belowTarget);
      expect(location.boundaryOffset, 3);
      expect(location.sourceLength, 3);
    });
  });
}
