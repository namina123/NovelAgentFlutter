class PromptTemplateVariableService {
  List<String> extractVariables(String content) {
    // 中文注释: 变量提取保持朴素字符串扫描，避免为简单模板系统引入重解析器。
    final result = <String>[];
    var cursor = 0;
    while (cursor < content.length) {
      final start = content.indexOf('{{', cursor);
      if (start < 0) {
        break;
      }
      final end = content.indexOf('}}', start + 2);
      if (end < 0) {
        break;
      }
      final variable = content.substring(start + 2, end).trim();
      if (variable.isNotEmpty && !result.contains(variable)) {
        result.add(variable);
      }
      cursor = end + 2;
    }
    return result;
  }
}
