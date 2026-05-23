import '../common/json_types.dart';
import '../common/value_readers.dart';

class PromptTemplateRenderer {
  String renderTemplate(JsonMap template, JsonMap variables) {
    // 中文注释: 模板渲染只做简单替换，保持跨平台、可审计和易调试。
    var content = ValueReaders.stringValue(template['content']);
    for (final entry in variables.entries) {
      content = content.replaceAll(
        '{{${entry.key}}}',
        ValueReaders.stringValue(entry.value),
      );
    }
    return content;
  }
}
