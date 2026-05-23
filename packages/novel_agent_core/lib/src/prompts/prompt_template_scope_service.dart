class PromptTemplateScopeService {
  String normalizeScope(String scope) {
    // 中文注释: 模板作用域只允许已知分类，避免项目模板写出未知目录和错误标签。
    if (const <String>{'global', 'project', 'agent', 'task'}.contains(scope)) {
      return scope;
    }
    return 'project';
  }
}
