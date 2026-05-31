import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContextAssemblerService', () {
    test(
      'assembles static, memory and project file sections into context pack',
      () {
        // 中文注释: 这里验证 context assembler 会把固定片段、记忆片段和项目文件片段统一收束进一个上下文包。
        final assembler = ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        );

        final result = assembler.assemble(<String, Object?>{
          'project': <String, Object?>{
            'title': '示例长篇项目',
            'project_type': 'novel',
            'stage': 'opening',
            'path': 'D:/projects/demo',
          },
          'project_files': <Object?>[
            <String, Object?>{
              'relative_path': 'styles/main_style.md',
              'is_dir': false,
            },
          ],
          'project_file_contents': <String, Object?>{
            'styles/main_style.md': '保持冷静克制的叙事语气。',
          },
          'memory_sections': <Object?>[
            <String, Object?>{
              'id': 'memory_1',
              'title': '记忆',
              'priority': 88,
              'content': '主角不能提前得知系统真相。',
            },
          ],
          'user_prompt': '写一个开局',
          'session_context': '用户已经确定题材。',
          'intent': 'draft',
          'agent': <String, Object?>{'name': '综合创作智能体', 'role': '写作'},
        });

        expect(result['context_text'], contains('项目概况'));
        expect(result['context_text'], contains('主角不能提前得知系统真相'));
        expect(result['context_text'], contains('保持冷静克制的叙事语气'));
      },
    );

    test(
      'promotes constitution, expression constraints and style into shared creative rule stack sections',
      () {
        // 中文注释: 这里验证宪法、模式引导、表达限制和风格会先被提炼成共享约束层，再进入上下文包。
        final assembler = ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        );

        final result = assembler.assemble(<String, Object?>{
          'project': <String, Object?>{
            'title': '示例长篇项目',
            'project_type': 'novel',
            'stage': 'opening',
            'path': 'D:/projects/demo',
          },
          'project_file_contents': <String, Object?>{
            'specs/project_spec.md': '''
# 项目创作宪法

本书长期承诺是压迫感和逆转感。

## 核心原则

- 角色动机必须稳定。
''',
            'styles/main.style.md': '''
---
id: style.main
display_name: 主风格
guardrails:
  - 每章必须推进主线
---

# 主风格

保持冷静克制。
''',
            'tracking/modes/seed_autopilot_novel/guidance.md': '''
# 灵感托管式长篇 引导摘要

当前已经确认主线方向和托管边界。

## 阶段答案

- 高压权谋与持续逆转。
- 总纲和重大转折先确认。
''',
          },
          'expression_constraint_profiles': const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板化表达和解释腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少工整排比和空心总结。'],
            },
          ],
          'project_expression_constraint_bindings': const <Object?>[
            <String, Object?>{
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
          'memory_sections': const <Object?>[
            <String, Object?>{
              'id': 'legacy_mode_style',
              'title': '风格锚点',
              'priority': 97,
              'creative_layer': 'style',
              'content': '旧片段应被新约束栈替代。',
            },
            <String, Object?>{
              'id': 'legacy_expression_constraint',
              'title': '旧表达限制',
              'priority': 96,
              'creative_layer': 'expression_constraint',
              'content': '旧限制片段应被新约束栈替代。',
            },
          ],
          'user_prompt': '写一个开局',
          'session_context': '用户已经确定题材。',
          'intent': 'draft',
          'agent': <String, Object?>{'name': '综合创作智能体', 'role': '写作'},
        });

        expect(result['context_text'], contains('项目创作宪法'));
        expect(result['context_text'], contains('模式引导约束'));
        expect(result['context_text'], contains('表达限制规范'));
        expect(result['context_text'], contains('项目风格规范'));
        expect(result['context_text'], isNot(contains('旧片段应被新约束栈替代')));
        expect(result['context_text'], isNot(contains('旧限制片段应被新约束栈替代')));
        expect(
          ValueReaders.stringValue(result['creative_rule_summary']),
          contains('优先级：项目创作宪法 > 模式引导 > 表达限制 > 项目风格'),
        );
        expect(
          ValueReaders.stringValue(result['creative_rule_summary']),
          contains('表达限制：去 AI 风'),
        );
      },
    );

    test('adds foreshadow timeline and relationship sections into context', () {
      // 中文注释: 这里验证共享叙事资产会在上下文包中形成独立片段，而不是只散落为普通文件摘录。
      final assembler = ContextAssemblerService(
        budgetService: ContextBudgetService(),
        staticSectionService: ContextStaticSectionService(
          projectPromptContract: ProjectPromptContract(),
        ),
        projectFileSectionService: ContextProjectFileSectionService(),
      );

      final result = assembler.assemble(<String, Object?>{
        'project': <String, Object?>{
          'title': '示例长篇项目',
          'project_type': 'novel',
          'stage': 'drafting',
          'path': 'D:/projects/demo',
        },
        'project_file_contents': <String, Object?>{
          'assets/foreshadows/tower_key.foreshadow.md': '''
---
id: tower_key
title: 塔楼密钥
status: pending_payoff
---

# 塔楼密钥

这是必须在中盘回收的关键伏笔。
''',
          'assets/timeline/tower_night.timeline.md': '''
---
id: tower_night
display_name: 塔楼之夜
sequence: 12
---

# 塔楼之夜

主角正式卷入塔楼事件。
''',
          'assets/relationships/master_apprentice.relationship.md': '''
---
id: master_apprentice
display_name: 师徒裂痕
left_entity_id: hero
right_entity_id: mentor
---

# 师徒裂痕

双方信任出现裂口。
''',
        },
        'intent': 'draft',
        'user_prompt': '继续写下一章',
      });

      expect(result['context_text'], contains('待回收伏笔'));
      expect(result['context_text'], contains('最近时间线'));
      expect(result['context_text'], contains('关键关系变化'));
    });

    test(
      'suppresses long expression constraint sections for non-creative intents',
      () {
        final assembler = ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        );

        final result = assembler.assemble(<String, Object?>{
          'project': <String, Object?>{
            'title': '示例项目',
            'project_type': 'novel',
            'stage': 'discussion',
            'path': 'D:/projects/demo',
          },
          'intent': 'chat',
          'user_prompt': '我们先聊聊故事方向。',
          'expression_constraint_profiles': const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板化表达和解释腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少工整排比和空心总结。'],
            },
          ],
          'project_expression_constraint_bindings': const <Object?>[
            <String, Object?>{
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
          'memory_sections': const <Object?>[
            <String, Object?>{
              'id': 'legacy_expression_constraint',
              'title': '旧表达限制',
              'priority': 96,
              'creative_layer': 'expression_constraint',
              'content': '旧限制片段不应在闲聊轮次泄漏进上下文。',
            },
          ],
        });

        expect(result['context_text'], isNot(contains('表达限制规范')));
        expect(result['context_text'], isNot(contains('旧限制片段不应在闲聊轮次泄漏进上下文。')));
        expect(
          ValueReaders.stringValue(result['creative_rule_summary']),
          isNot(contains('表达限制：')),
        );
        expect(result['expression_constraint_injection_mode'], 'disabled');
      },
    );
  });
}
