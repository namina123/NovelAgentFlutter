import 'package:novel_agent_cli/commands/workflow/workflow_output_summary_service.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowOutputSummaryService', () {
    const service = WorkflowOutputSummaryService();

    test(
      'narrative summary includes information counts signal and projection paths',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          <String, Object?>{
            'changed_paths': <Object?>[
              '.novel_agent/information/knowledge_cards/knowledge-1.json',
              '.novel_agent/information/design_elements/design-1.json',
              '.novel_agent/information/research_notes/research-1.json',
              '.novel_agent/information/reference_works/reference-1.json',
              'knowledge/项目知识摘要.md',
              'knowledge/设计元素摘要.md',
              'research/资料研究摘要.md',
              'references/引用作品边界.md',
            ],
            'checkpoint_review': <String, Object?>{
              'review': <String, Object?>{
                'summary': '章节已完成。',
                'information_summary': '待研究 1 项，引用边界 1 项。',
              },
            },
          },
        );

        final lines = service.narrativeBriefLines(contract);

        expect(
          lines,
          contains(
            'Information：knowledge 1 | design 1 | research 1 | reference 1',
          ),
        );
        expect(lines, contains('Information Signal：待研究 1 项，引用边界 1 项。'));
        expect(
          lines,
          contains(
            'Information Projections：knowledge/项目知识摘要.md | knowledge/设计元素摘要.md | research/资料研究摘要.md | references/引用作品边界.md',
          ),
        );
      },
    );

    test('information summary still shows zero counts without payload details', () {
      final contract = service.extractNarrativeRuntimeContract(
        const <String, Object?>{
          'changed_paths': <Object?>[],
          'checkpoint_review': <String, Object?>{
            'review': <String, Object?>{},
          },
        },
      );

      final lines = service.narrativeBriefLines(contract);

      expect(
        lines,
        contains(
          'Information：knowledge 0 | design 0 | research 0 | reference 0',
        ),
      );
      expect(
        lines,
        contains(
          'Information Projections：knowledge/项目知识摘要.md | knowledge/设计元素摘要.md | research/资料研究摘要.md | references/引用作品边界.md',
        ),
      );
      expect(
        lines.any((line) => line.contains('payload')),
        isFalse,
      );
    });

    test('analysis information ids can backfill counts without changed paths', () {
      final contract = service.extractNarrativeRuntimeContract(
        const <String, Object?>{
          'changed_paths': <Object?>[],
          'analysis_information': <String, Object?>{
            'knowledge_card_ids': <Object?>['knowledge-1', 'knowledge-2'],
            'design_element_ids': <Object?>['design-1'],
            'research_note_ids': <Object?>['research-1'],
          },
        },
      );

      final lines = service.narrativeBriefLines(contract);

      expect(
        lines,
        contains(
          'Information：knowledge 2 | design 1 | research 1 | reference 0',
        ),
      );
    });
  });
}
