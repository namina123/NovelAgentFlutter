import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  const service = ProjectContentPathPolicyService();

  test('normalizes unified narrative and information content types', () {
    expect(service.normalizeContentType('正文'), 'chapter');
    expect(service.normalizeContentType('样章'), 'sample');
    expect(service.normalizeContentType('研究'), 'knowledge');
    expect(service.normalizeContentType('提取'), 'analysis');
    expect(service.normalizeContentType('原文归档'), 'source_original');
    expect(service.normalizeContentType('派生续写'), 'derived_continuation_narrative');
    expect(service.normalizeContentType('派生同人'), 'derived_fanfic_narrative');
  });

  test('maps unified content types to stable directories', () {
    expect(service.directoryForContentType('chapter'), 'chapters');
    expect(service.directoryForContentType('sample'), 'samples');
    expect(service.directoryForContentType('knowledge'), 'knowledge');
    expect(service.directoryForContentType('analysis'), 'analysis');
    expect(
      service.directoryForContentType('source_original'),
      'sources/original',
    );
    expect(
      service.directoryForContentType('derived_continuation_narrative'),
      'chapters/inherited/continuation',
    );
    expect(
      service.directoryForContentType('derived_fanfic_narrative'),
      'chapters/inherited/fanfic',
    );
  });

  test('infers unified content types from canonical paths', () {
    expect(service.inferContentTypeFromPath('knowledge/research_note.md'), 'knowledge');
    expect(service.inferContentTypeFromPath('research/reference.md'), 'knowledge');
    expect(service.inferContentTypeFromPath('sources/original/demo.md'), 'source_original');
    expect(
      service.inferContentTypeFromPath('chapters/inherited/continuation/001_demo.md'),
      'derived_continuation_narrative',
    );
    expect(
      service.inferContentTypeFromPath('chapters/inherited/fanfic/001_demo.md'),
      'derived_fanfic_narrative',
    );
    expect(
      service.inferContentTypeFromPath('.novel_agent/information/research_notes/001.json'),
      'knowledge',
    );
  });
}
