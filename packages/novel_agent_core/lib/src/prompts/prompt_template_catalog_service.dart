import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'prompt_template_normalizer_service.dart';

class PromptTemplateCatalogService {
  PromptTemplateCatalogService({
    PromptTemplateNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ?? PromptTemplateNormalizerService();

  final PromptTemplateNormalizerService _normalizerService;

  List<String> coreTemplateIds() {
    // 中文注释: 这些 id 对应旧项目里已经约定好的内置模板入口，后续适配层和 UI 都会依赖它们。
    return const <String>[
      'system_generalist',
      'tool_policy',
      'context_pack',
      'chapter_atomic',
      'review_report',
    ];
  }

  List<JsonMap> defaultTemplates() {
    // 中文注释: 默认模板作为可复制基线存在，真正项目覆盖和持久化由适配层负责。
    return <JsonMap>[
      _normalizerService.normalizeTemplate(<String, Object?>{
        'id': 'system_generalist',
        'name': '综合创作智能体系统提示',
        'scope': 'global',
        'locked_core': true,
        'description': '默认全能智能体的基础角色说明。',
        'content':
            '你是 NOVEL Agent 的综合创作智能体，服务中文小说创作。\n'
            '当前项目：{{project_title}}\n'
            '当前智能体：{{agent_name}}\n'
            '智能体职责：{{agent_role}}\n'
            '智能体系统提示：{{agent_system_prompt}}\n'
            '当前意图：{{intent}}\n'
            '用户请求：{{user_request}}\n\n'
            '请把用户目标转化为可执行创作动作；需要正式读写时使用工具，不要假装已经读取或写入文件。',
      }),
      _normalizerService.normalizeTemplate(<String, Object?>{
        'id': 'tool_policy',
        'name': '工具策略提示',
        'scope': 'global',
        'locked_core': true,
        'description': '工具调用和安全写入规则的模板入口。',
        'content':
            '工具策略模板入口。\n'
            '可用工具：{{tool_list}}\n'
            '策略模式：{{tool_mode}}\n'
            '当前意图：{{intent}}\n\n'
            '{{tool_policy_body}}\n\n'
            '所有读写改删只能操作当前项目相对路径。',
      }),
      _normalizerService.normalizeTemplate(<String, Object?>{
        'id': 'context_pack',
        'name': '上下文包提示',
        'scope': 'project',
        'locked_core': false,
        'description': '把 context pack 注入模型请求时使用的说明。',
        'content':
            '本次上下文包由 ContextAssembler 按预算组装。\n'
            '上下文摘要：{{context_summary}}\n\n'
            '{{context_pack}}\n\n'
            '用户请求：{{user_request}}\n\n'
            '如果上下文包记录了省略或截断，请不要编造未读取内容。',
      }),
      _normalizerService.normalizeTemplate(<String, Object?>{
        'id': 'chapter_atomic',
        'name': '章节原子任务提示',
        'scope': 'task',
        'locked_core': false,
        'description': '执行单章/场景任务时的提示骨架。',
        'content':
            '任务目标：{{task_goal}}\n章节：{{chapter}}\n约束：{{constraints}}\n请输出章节正文，并标注需要更新的设定和角色状态。',
      }),
      _normalizerService.normalizeTemplate(<String, Object?>{
        'id': 'review_report',
        'name': '审稿报告提示',
        'scope': 'task',
        'locked_core': false,
        'description': '连续性、文风和剧情检查的通用报告提示。',
        'content': '检查范围：{{scope}}\n检查目标：{{review_goal}}\n请按问题、影响、建议输出。',
      }),
    ];
  }

  JsonMap defaultTemplate(String templateId) {
    // 中文注释: 读取内置模板时只按 id 匹配，方便上层做恢复默认和缺省兜底。
    final cleanId = _normalizerService
        .templatePath(templateId)
        .split('/')
        .last
        .replaceAll('.json', '');
    for (final template in defaultTemplates()) {
      if (ValueReaders.stringValue(template['id']) == cleanId) {
        return ValueReaders.deepCopyMap(template);
      }
    }
    return <String, Object?>{};
  }
}
