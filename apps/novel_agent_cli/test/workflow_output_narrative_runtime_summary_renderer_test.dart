import 'package:novel_agent_cli/commands/workflow/workflow_output_narrative_runtime_summary_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeRuntimeSummaryRenderer', () {
    final renderer = NarrativeRuntimeSummaryRenderer();

    test('extracts narrative runtime contract from shared workflow output', () {
      final contract = renderer.extractContract(const <String, Object?>{
        'execution': <String, Object?>{
          'activation_report_summary': '已完成基础激活。',
          'chapter_delivery_state': 'delivered',
          'chapter_delivery_path': 'chapters/第01章.md',
          'stop_diagnosis': <String, Object?>{
            'present': true,
            'code': 'delivery_manual_attention',
            'label': '内容质量关口',
          },
          'analysis_information': <String, Object?>{
            'knowledge_card_ids': <Object?>['knowledge-1'],
          },
        },
        'changed_paths': <Object?>[
          '.novel_agent/information/knowledge_cards/knowledge-1.json',
          'knowledge/项目知识摘要.md',
        ],
        'checkpoint_review': <String, Object?>{
          'review': <String, Object?>{
            'summary': '章节已完成。',
            'information_summary': '待研究 1 项。',
          },
        },
        'constraints': <String, Object?>{
          'present': true,
          'expression_constraint_active': true,
          'expression_constraint_policy_mode': 'adaptive',
          'expression_constraint_applied': true,
          'summary': '表达限制当前建议加强后续章节执行。',
          'expression_constraint_gate': <String, Object?>{
            'present': true,
            'risk_signals': <Object?>['总而言之'],
          },
        },
        'expression_constraint_projection': <String, Object?>{
          'present': true,
          'status': 'suggest_strengthen',
          'status_label': '建议加强',
          'summary': '表达限制当前建议加强后续章节执行。',
          'policy_mode': 'adaptive',
          'active': true,
          'applied': true,
          'suggest_strengthen': true,
        },
      });

      expect(contract['activation_report_summary'], '已完成基础激活。');
      expect(contract['chapter_delivery_state'], 'delivered');
      expect(contract['chapter_delivery_path'], 'chapters/第01章.md');
      expect(contract['stop_diagnosis'], isA<Map>());
      expect(contract['expression_constraint_contract'], isA<Map>());
      expect(contract['information_contract'], isA<Map>());
      expect(contract['continuity_counts'], containsPair('total', 0));
    });

    test('renders narrative summary by consuming the extracted contract', () {
      final contract = renderer.extractContract(const <String, Object?>{
        'run_center_contract': <String, Object?>{
          'stop_diagnosis': <String, Object?>{
            'present': true,
            'code': 'delivery_manual_attention',
            'label': '内容质量关口',
          },
        },
        'execution': <String, Object?>{
          'activation_report_summary': '已完成基础激活。',
          'chapter_delivery_state': 'delivered',
          'chapter_delivery_path': 'chapters/第01章.md',
          'analysis_information': <String, Object?>{
            'knowledge_card_ids': <Object?>['knowledge-1'],
            'design_element_ids': <Object?>['design-1'],
            'research_note_ids': <Object?>['research-1'],
            'reference_work_ids': <Object?>['reference-1'],
          },
        },
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
      });

      final lines = renderer.renderLines(contract);

      expect(lines, contains('Activation：已完成基础激活。'));
      expect(lines, contains('Delivery：delivered | chapters/第01章.md'));
      expect(lines, contains('Review：章节已完成。'));
      expect(lines, contains('资料状态：已执行研究'));
      expect(lines, contains('待研究 1 项，引用边界 1 项。'));
      expect(lines, contains('章节交付：已交付 | chapters/第01章.md'));
      expect(lines, contains('停止原因：内容质量关口（delivery_manual_attention）'));
    });
  });
}
