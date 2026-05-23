class PromptTemplateIdService {
  String safeId(String value) {
    // 中文注释: 模板 id 会进入项目内路径，因此这里和旧项目一样做轻量安全收敛。
    var result = value.trim();
    for (final token in const <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
      ' ',
    ]) {
      result = result.replaceAll(token, '_');
    }
    if (result.length > 80) {
      result = result.substring(0, 80);
    }
    return result;
  }
}
