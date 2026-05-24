import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/prompt_templates_view_data.dart';

class PromptTemplatesViewDataService {
  const PromptTemplatesViewDataService();

  PromptTemplatesViewData build({
    required List<JsonMap> templates,
    required JsonMap selectedTemplate,
    required String selectedTemplateId,
    required String previewText,
    String status = '',
  }) {
    // 中文注释: 模板页列表、编辑器和预览状态在这里统一投影，保持控制器只维护原始模板状态。
    final resolvedSelectedTemplate = _resolvedSelectedTemplate(
      templates,
      selectedTemplate,
      selectedTemplateId,
    );
    final resolvedSelectedTemplateId = ValueReaders.stringValue(
      resolvedSelectedTemplate['id'],
    );
    return PromptTemplatesViewData(
      title: '提示模板',
      description: '浏览内置与项目级模板，编辑 prompts/ 覆盖项，并预览变量渲染结果。',
      status: status,
      entries: templates
          .map(
            (template) => PromptTemplateEntryViewData(
              id: ValueReaders.stringValue(template['id']),
              title: ValueReaders.stringValue(template['name'], '未命名模板'),
              subtitle: _entrySubtitle(template),
              relativePath: ValueReaders.stringValue(template['relative_path']),
              isSelected:
                  ValueReaders.stringValue(template['id']) ==
                  resolvedSelectedTemplateId,
            ),
          )
          .toList(growable: false),
      selectedTemplateId: resolvedSelectedTemplateId,
      editor: _editorFromTemplate(resolvedSelectedTemplate),
      previewText: previewText,
      scopeOptions: PromptTemplatesViewData.initial().scopeOptions,
    );
  }

  PromptTemplateEditorViewData emptyEditor() {
    // 中文注释: 新建模板时始终回到同一空编辑器骨架，避免页面自己猜默认值。
    return PromptTemplateEditorViewData.empty();
  }

  PromptTemplateEditorViewData _editorFromTemplate(JsonMap template) {
    if (template.isEmpty) {
      return emptyEditor();
    }
    return PromptTemplateEditorViewData(
      id: ValueReaders.stringValue(template['id']),
      name: ValueReaders.stringValue(template['name']),
      scope: ValueReaders.stringValue(template['scope'], 'project'),
      description: ValueReaders.stringValue(template['description']),
      content: ValueReaders.stringValue(template['content']),
      variablesJson: const JsonEncoder.withIndent('  ').convert(
        _seedVariables(template),
      ),
      relativePath: ValueReaders.stringValue(template['relative_path']),
      isBuiltin: ValueReaders.boolValue(template['locked_core']) &&
          ValueReaders.stringValue(template['relative_path']).trim().isEmpty,
    );
  }

  JsonMap _resolvedSelectedTemplate(
    List<JsonMap> templates,
    JsonMap selectedTemplate,
    String selectedTemplateId,
  ) {
    if (selectedTemplate.isNotEmpty) {
      return ValueReaders.deepCopyMap(selectedTemplate);
    }
    for (final template in templates) {
      if (ValueReaders.stringValue(template['id']) == selectedTemplateId) {
        return ValueReaders.deepCopyMap(template);
      }
    }
    if (templates.isEmpty) {
      return <String, Object?>{};
    }
    return ValueReaders.deepCopyMap(templates.first);
  }

  String _entrySubtitle(JsonMap template) {
    final scope = ValueReaders.stringValue(template['scope'], 'project');
    final source = ValueReaders.stringValue(template['relative_path']).trim().isEmpty
        ? '内置'
        : '项目';
    return '$scope｜$source';
  }

  JsonMap _seedVariables(JsonMap template) {
    final result = <String, Object?>{};
    for (final variable in ValueReaders.stringList(template['variables'])) {
      result[variable] = '';
    }
    if (result.isEmpty) {
      result['project_title'] = '';
      result['user_request'] = '';
    }
    return result;
  }
}
