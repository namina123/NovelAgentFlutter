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
            'knowledge/项目知识摘要.md': _projectionMarkdown(
              title: '知识摘要',
              sourceOfTruthPath: 'project-information://knowledge_cards',
              sourceIdentity:
                  '来源-source-1 / `imports/reference/source-1.txt` / kind:`user`',
            ),
            'knowledge/设计元素摘要.md': _projectionMarkdown(
              title: '巧思与设计',
              sourceOfTruthPath: 'project-information://design_elements',
              sourceIdentity:
                  '设计-source-1 / `imports/reference/design-1.txt` / kind:`user`',
            ),
            'research/资料研究摘要.md': _projectionMarkdown(
              title: '研究摘要',
              sourceOfTruthPath: 'project-information://research_notes',
              sourceIdentity:
                  '研究-source-1 / `imports/reference/research-1.txt` / kind:`tool`',
            ),
            'references/引用作品边界.md': _projectionMarkdown(
              title: '引用边界',
              sourceOfTruthPath: 'project-information://reference_works',
              sourceIdentity:
                  '引用-source-1 / `imports/reference/reference-1.txt` / kind:`user`',
            ),
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
                  'report_id': 'activation-report-1',
                  'plan_id': 'activation-plan-1',
                  'source': 'project_context_activation_adapter',
                  'budget_chars': 6000,
                  'used_chars': 1200,
                  'omitted_chars': 800,
                  'items': <Object?>[
                    <String, Object?>{
                      'item_id': 'knowledge:knowledge_1',
                      'source': 'project_knowledge_card',
                      'title': '王朝年号',
                      'target_path': 'knowledge/项目知识摘要.md',
                      'activation_reasons': <Object?>['information_policy'],
                      'requested_chars': 500,
                      'included_chars': 320,
                      'selected': true,
                      'omitted': false,
                      'truncated': false,
                      'metadata': <String, Object?>{
                        'source_kind': 'project_knowledge_card',
                        'explanation': '本轮需要使用世界观设定。',
                        'source_of_truth_locator':
                            'project-information://knowledge_cards',
                      },
                    },
                    <String, Object?>{
                      'item_id': 'design:design_1',
                      'source': 'project_design_element',
                      'title': '双线叙事',
                      'target_path': 'knowledge/设计元素摘要.md',
                      'activation_reasons': <Object?>['information_policy'],
                      'requested_chars': 420,
                      'included_chars': 260,
                      'selected': true,
                      'omitted': false,
                      'truncated': false,
                      'metadata': <String, Object?>{
                        'source_kind': 'project_design_element',
                        'explanation': '本轮需要使用结构巧思。',
                        'source_of_truth_locator':
                            'project-information://design_elements',
                      },
                    },
                    <String, Object?>{
                      'item_id': 'research:research_1',
                      'source': 'project_research_note',
                      'title': '古代驿站传信速度',
                      'target_path': 'research/资料研究摘要.md',
                      'activation_reasons': <Object?>['information_policy'],
                      'requested_chars': 360,
                      'included_chars': 0,
                      'selected': false,
                      'omitted': true,
                      'truncated': false,
                      'omission_reason': '资料太旧',
                      'metadata': <String, Object?>{
                        'source_kind': 'project_research_note',
                        'explanation': '当前段落不依赖外部资料。',
                        'source_of_truth_locator':
                            'project-information://research_notes',
                      },
                    },
                    <String, Object?>{
                      'item_id': 'reference:reference_1',
                      'source': 'project_reference_work',
                      'title': '参考作品 A',
                      'target_path': 'references/引用作品边界.md',
                      'activation_reasons': <Object?>['information_policy'],
                      'requested_chars': 280,
                      'included_chars': 0,
                      'selected': false,
                      'omitted': true,
                      'truncated': false,
                      'omission_reason': '还没确认边界',
                      'metadata': <String, Object?>{
                        'source_kind': 'project_reference_work',
                        'explanation': '先不引入引用关系。',
                        'source_of_truth_locator':
                            'project-information://reference_works',
                      },
                    },
                  ],
                  'selected_item_ids': <Object?>[
                    'knowledge:knowledge_1',
                    'design:design_1',
                  ],
                  'omitted_item_ids': <Object?>[
                    'research:research_1',
                    'reference:reference_1',
                  ],
                  'truncated_item_ids': <Object?>[],
                  'summary': '已为本轮选择 2 条资料上下文。',
                  'schema_version': '1.0',
                  'metadata': <String, Object?>{
                    'selected_context_sections': <Object?>[],
                    'omitted_context_sections': <Object?>[],
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
        expect(knowledgeEntry.mountStatusLabel, '已挂载');
        expect(knowledgeEntry.usageLabel, '本轮已使用 1 次');
        expect(knowledgeEntry.relativePath, 'knowledge/项目知识摘要.md');
        expect(
          knowledgeEntry.sourceOfTruthSummary,
          '真相源：project-information://knowledge_cards',
        );
        expect(knowledgeEntry.sourceIdentitySummary, contains('来源-source-1'));

        final researchEntry = viewData.entries.firstWhere(
          (entry) => entry.title == '研究摘要',
        );
        expect(researchEntry.mountStatusLabel, '已挂载');
        expect(researchEntry.usageLabel, '本轮未使用');
        expect(researchEntry.riskLabel, contains('资料太旧'));
        expect(
          researchEntry.sourceOfTruthSummary,
          '真相源：project-information://research_notes',
        );

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
        expect(pendingResearch.pendingResearchRequestId, 'research_1');
      },
    );
  });
}

String _projectionMarkdown({
  required String title,
  required String sourceOfTruthPath,
  required String sourceIdentity,
}) {
  return '''---
projection_id: projection-test
title: $title
projection_only: true
source_of_truth_paths:
  - $sourceOfTruthPath
editable_draft_blocks:
  - note
---

# $title

- 来源身份：$sourceIdentity
''';
}
