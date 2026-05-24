class PromptTemplatesViewData {
  const PromptTemplatesViewData({
    required this.title,
    required this.description,
    required this.status,
    required this.entries,
    required this.selectedTemplateId,
    required this.editor,
    required this.previewText,
    required this.scopeOptions,
  });

  final String title;
  final String description;
  final String status;
  final List<PromptTemplateEntryViewData> entries;
  final String selectedTemplateId;
  final PromptTemplateEditorViewData editor;
  final String previewText;
  final List<PromptTemplateScopeOptionViewData> scopeOptions;

  factory PromptTemplatesViewData.initial() {
    return PromptTemplatesViewData(
      title: '提示模板',
      description: '',
      status: '',
      entries: const <PromptTemplateEntryViewData>[],
      selectedTemplateId: '',
      editor: PromptTemplateEditorViewData.empty(),
      previewText: '',
      scopeOptions: const <PromptTemplateScopeOptionViewData>[
        PromptTemplateScopeOptionViewData(id: 'global', label: '全局'),
        PromptTemplateScopeOptionViewData(id: 'project', label: '项目'),
        PromptTemplateScopeOptionViewData(id: 'task', label: '任务'),
      ],
    );
  }
}

class PromptTemplateEntryViewData {
  const PromptTemplateEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.relativePath,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String relativePath;
  final bool isSelected;
}

class PromptTemplateEditorViewData {
  const PromptTemplateEditorViewData({
    required this.id,
    required this.name,
    required this.scope,
    required this.description,
    required this.content,
    required this.variablesJson,
    required this.relativePath,
    required this.isBuiltin,
  });

  final String id;
  final String name;
  final String scope;
  final String description;
  final String content;
  final String variablesJson;
  final String relativePath;
  final bool isBuiltin;

  factory PromptTemplateEditorViewData.empty() {
    return const PromptTemplateEditorViewData(
      id: '',
      name: '',
      scope: 'project',
      description: '',
      content: '',
      variablesJson: '{}',
      relativePath: '',
      isBuiltin: false,
    );
  }
}

class PromptTemplateScopeOptionViewData {
  const PromptTemplateScopeOptionViewData({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class PromptTemplateEditorRequestViewData {
  const PromptTemplateEditorRequestViewData({
    required this.id,
    required this.name,
    required this.scope,
    required this.description,
    required this.content,
    required this.variablesJson,
  });

  final String id;
  final String name;
  final String scope;
  final String description;
  final String content;
  final String variablesJson;
}
