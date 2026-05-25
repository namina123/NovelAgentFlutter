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
  });
}
