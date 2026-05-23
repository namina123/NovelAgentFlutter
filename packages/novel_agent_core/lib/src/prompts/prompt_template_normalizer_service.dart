import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'prompt_template_id_service.dart';
import 'prompt_template_scope_service.dart';
import 'prompt_template_variable_service.dart';

class PromptTemplateNormalizerService {
  PromptTemplateNormalizerService({
    PromptTemplateIdService? idService,
    PromptTemplateScopeService? scopeService,
    PromptTemplateVariableService? variableService,
  }) : _idService = idService ?? PromptTemplateIdService(),
       _scopeService = scopeService ?? PromptTemplateScopeService(),
       _variableService = variableService ?? PromptTemplateVariableService();

  final PromptTemplateIdService _idService;
  final PromptTemplateScopeService _scopeService;
  final PromptTemplateVariableService _variableService;

  JsonMap normalizeTemplate(JsonMap template) {
    // 中文注释: 模板规范化把默认值、作用域和变量名集中收敛，避免界面和运行层重复补字段。
    final content = ValueReaders.stringValue(template['content']);
    final id = _idService.safeId(ValueReaders.stringValue(template['id']));
    final result = <String, Object?>{
      'schema_version': 1,
      'id': id,
      'name': ValueReaders.stringValue(
        template['name'],
        ValueReaders.stringValue(template['id'], '未命名模板'),
      ),
      'scope': _scopeService.normalizeScope(
        ValueReaders.stringValue(template['scope'], 'project'),
      ),
      'description': ValueReaders.stringValue(template['description']),
      'content': content,
      'locked_core': ValueReaders.boolValue(template['locked_core']),
      'variables': _variableService.extractVariables(content),
      'updated_at': ValueReaders.stringValue(template['updated_at']),
    };
    if (template.containsKey('relative_path')) {
      result['relative_path'] = template['relative_path'];
    }
    return result;
  }

  String templatePath(String templateId) {
    // 中文注释: 核心只负责相对路径规则，不碰实际存储读写。
    final cleanId = _idService.safeId(templateId);
    if (cleanId.isEmpty) {
      return '';
    }
    return 'prompts/$cleanId.json';
  }
}
