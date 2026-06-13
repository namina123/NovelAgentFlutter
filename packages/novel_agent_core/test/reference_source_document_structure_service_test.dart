import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceDocumentStructureService', () {
    const service = ReferenceSourceDocumentStructureService();

    test('detects explicit chapters from noisy prefixed headings', () {
      final structure = service.analyze('''
1.Sample Novel.txt

¡¡¡¡Sample Novel
¡¡¡¡CHAPTER ONE
¡¡¡¡THE BOY WHO LIVED
Harry lived under the stairs.

����CHAPTER TWO
The letters started arriving.

　　CHAPTER THREE
Hagrid crossed the sea.
''');

      expect(
        structure.structureKind,
        ReferenceSourceDocumentStructureKinds.explicitChapter,
      );
      expect(structure.sections, hasLength(3));
      expect(
        structure.sections.map((entry) => entry.heading).toList(),
        <String>['CHAPTER ONE', 'CHAPTER TWO', 'CHAPTER THREE'],
      );
      expect(structure.sections.first.content, contains('THE BOY WHO LIVED'));
      expect(
        structure.sections.first.content,
        contains('Harry lived under the stairs.'),
      );
    });

    test('falls back to paragraph clusters when headings are absent', () {
      final structure = service.analyze('''
Harry walked through the corridor.

Owls circled above the castle.

Letters kept arriving at Privet Drive.
''');

      expect(
        structure.structureKind,
        ReferenceSourceDocumentStructureKinds.paragraphCluster,
      );
      expect(structure.sections, isNotEmpty);
    });
  });
}
