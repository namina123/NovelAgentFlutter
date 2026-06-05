import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_information_projection_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkspaceInformationProjectionService', () {
    test(
      'build projects user-facing information summaries and pending confirmations',
      () {
        const service = WorkspaceInformationProjectionService();

        final viewData = service.build(
          workspaceEntries: const <JsonMap>[
            <String, Object?>{
              'relative_path': 'knowledge/项目知识摘要.md',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path': 'knowledge/设计元素摘要.md',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path': 'research/资料研究摘要.md',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path': 'references/引用作品边界.md',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path':
                  '.novel_agent/information/knowledge_cards/knowledge_1.json',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path':
                  '.novel_agent/information/design_elements/design_1.json',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path':
                  '.novel_agent/information/research_requests/research_1.json',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path':
                  '.novel_agent/information/reference_works/reference_1.json',
              'is_dir': false,
            },
            <String, Object?>{
              'relative_path':
                  'tracking/context_activation/2026-06-05/activation_report.json',
              'is_dir': false,
            },
          ],
          fileContents: <String, String>{
            '.novel_agent/information/knowledge_cards/knowledge_1.json':
                jsonEncode(<String, Object?>{
                  'card_id': 'knowledge_1',
                  'title': '王朝年号',
                  'summary': '需要确认帝国年号是否已经固定。',
                  'lifecycle_status': InformationLifecycleStatuses.proposed,
                }),
            '.novel_agent/information/design_elements/design_1.json':
                jsonEncode(<String, Object?>{
                  'design_id': 'design_1',
                  'design_label': '双线叙事',
                  'lifecycle_status': InformationLifecycleStatuses.proposed,
                }),
            '.novel_agent/information/research_requests/research_1.json':
                jsonEncode(<String, Object?>{
                  'request_id': 'research_1',
                  'request_state': 'pending_confirmation',
                  'research_request': <String, Object?>{'query': '古代驿站传信速度'},
                }),
            '.novel_agent/information/reference_works/reference_1.json':
                jsonEncode(<String, Object?>{
                  'reference_work_id': 'reference_1',
                  'title': '参考作品 A',
                  'declared_usage_intent': '只参考宫廷组织方式',
                  'allowed_usage_summary': '边界待确认',
                  'requires_confirmation': true,
                }),
            'tracking/context_activation/2026-06-05/activation_report.json':
                jsonEncode(<String, Object?>{
                  'metadata': <String, Object?>{
                    'selected_context_sections': <Object?>[
                      <String, Object?>{
                        'target_path': 'knowledge/项目知识摘要.md',
                        'source_kind': 'project_knowledge_card',
                        'explanation': '本轮需要使用世界观设定。',
                      },
                      <String, Object?>{
                        'target_path': 'knowledge/设计元素摘要.md',
                        'source_kind': 'project_design_element',
                        'explanation': '本轮需要使用结构巧思。',
                      },
                    ],
                    'omitted_context_sections': <Object?>[
                      <String, Object?>{
                        'target_path': 'research/资料研究摘要.md',
                        'source_kind': 'project_research_note',
                        'explanation': '当前段落不依赖外部资料。',
                        'omission_reason': '资料太旧',
                      },
                      <String, Object?>{
                        'target_path': 'references/引用作品边界.md',
                        'source_kind': 'project_reference_work',
                        'explanation': '先不引入引用关系。',
                        'omission_reason': '还没确认边界',
                      },
                    ],
                  },
                }),
          },
        );

        expect(viewData.summary, '已整理 4 组资料摘要，4 项待确认');
        expect(viewData.usageSummary, '本轮已使用：知识、巧思；本轮未使用：研究、引用边界');
        expect(
          viewData.entries.map((entry) => entry.title).toList(growable: false),
          <String>['知识摘要', '巧思与设计', '研究摘要', '引用边界'],
        );
        expect(
          viewData.pendingEntries.map((entry) => entry.title).toSet(),
          <String>{'待确认知识', '待确认巧思', '待确认研究', '待确认引用边界'},
        );

        final knowledgeEntry = viewData.entries.firstWhere(
          (entry) => entry.title == '知识摘要',
        );
        expect(knowledgeEntry.usageLabel, '本轮已使用 1 次');
        expect(knowledgeEntry.relativePath, 'knowledge/项目知识摘要.md');

        final researchEntry = viewData.entries.firstWhere(
          (entry) => entry.title == '研究摘要',
        );
        expect(researchEntry.usageLabel, '本轮未使用');
        expect(researchEntry.riskLabel, contains('资料太旧'));

        final pendingKnowledge = viewData.pendingEntries.firstWhere(
          (entry) => entry.title == '待确认知识',
        );
        expect(pendingKnowledge.subtitle, '王朝年号');
        expect(pendingKnowledge.statusLabel, '待确认');

        final pendingResearch = viewData.pendingEntries.firstWhere(
          (entry) => entry.title == '待确认研究',
        );
        expect(pendingResearch.subtitle, '古代驿站传信速度');
        expect(pendingResearch.actionLabel, '查看待确认');
      },
    );
  });
}
