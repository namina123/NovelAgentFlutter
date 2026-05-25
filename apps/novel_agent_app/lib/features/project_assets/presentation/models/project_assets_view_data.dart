class ProjectAssetsViewData {
  const ProjectAssetsViewData({
    required this.title,
    required this.description,
    required this.status,
    required this.activeTabId,
    required this.tabs,
    required this.entries,
    required this.styleEditor,
    required this.foreshadowEditor,
  });

  final String title;
  final String description;
  final String status;
  final String activeTabId;
  final List<ProjectAssetsTabViewData> tabs;
  final List<ProjectAssetEntryViewData> entries;
  final StyleProfileEditorViewData styleEditor;
  final ForeshadowRecordEditorViewData foreshadowEditor;

  factory ProjectAssetsViewData.initial() {
    return ProjectAssetsViewData(
      title: '项目资产',
      description: '集中管理风格、伏笔与项目资产包。',
      status: '',
      activeTabId: 'styles',
      tabs: const <ProjectAssetsTabViewData>[
        ProjectAssetsTabViewData(id: 'styles', label: '风格'),
        ProjectAssetsTabViewData(id: 'foreshadows', label: '伏笔'),
      ],
      entries: const <ProjectAssetEntryViewData>[],
      styleEditor: StyleProfileEditorViewData.empty(),
      foreshadowEditor: ForeshadowRecordEditorViewData.empty(),
    );
  }
}

class ProjectAssetsTabViewData {
  const ProjectAssetsTabViewData({required this.id, required this.label});

  final String id;
  final String label;
}

class ProjectAssetEntryViewData {
  const ProjectAssetEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.relativePath,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String relativePath;
  final bool isSelected;
}

class StyleProfileEditorViewData {
  const StyleProfileEditorViewData({
    required this.id,
    required this.displayName,
    required this.summary,
    required this.genre,
    required this.tone,
    required this.audience,
    required this.tagsText,
    required this.guardrailsText,
    required this.examplePathsText,
    required this.inheritedIdsText,
    required this.defaultForProject,
    required this.relativePath,
  });

  final String id;
  final String displayName;
  final String summary;
  final String genre;
  final String tone;
  final String audience;
  final String tagsText;
  final String guardrailsText;
  final String examplePathsText;
  final String inheritedIdsText;
  final bool defaultForProject;
  final String relativePath;

  factory StyleProfileEditorViewData.empty() {
    return const StyleProfileEditorViewData(
      id: '',
      displayName: '',
      summary: '',
      genre: '',
      tone: '',
      audience: '',
      tagsText: '',
      guardrailsText: '',
      examplePathsText: '',
      inheritedIdsText: '',
      defaultForProject: false,
      relativePath: '',
    );
  }
}

class ForeshadowRecordEditorViewData {
  const ForeshadowRecordEditorViewData({
    required this.id,
    required this.title,
    required this.status,
    required this.summary,
    required this.plantedChapterPath,
    required this.targetPayoffPath,
    required this.relatedEntityIdsText,
    required this.relatedPathsText,
    required this.triggerConditionsText,
    required this.payoffExpectationsText,
    required this.tagsText,
    required this.notes,
    required this.relativePath,
  });

  final String id;
  final String title;
  final String status;
  final String summary;
  final String plantedChapterPath;
  final String targetPayoffPath;
  final String relatedEntityIdsText;
  final String relatedPathsText;
  final String triggerConditionsText;
  final String payoffExpectationsText;
  final String tagsText;
  final String notes;
  final String relativePath;

  factory ForeshadowRecordEditorViewData.empty() {
    return const ForeshadowRecordEditorViewData(
      id: '',
      title: '',
      status: 'planted',
      summary: '',
      plantedChapterPath: '',
      targetPayoffPath: '',
      relatedEntityIdsText: '',
      relatedPathsText: '',
      triggerConditionsText: '',
      payoffExpectationsText: '',
      tagsText: '',
      notes: '',
      relativePath: '',
    );
  }
}

class StyleProfileEditorRequestViewData {
  const StyleProfileEditorRequestViewData({
    required this.id,
    required this.displayName,
    required this.summary,
    required this.genre,
    required this.tone,
    required this.audience,
    required this.tagsText,
    required this.guardrailsText,
    required this.examplePathsText,
    required this.inheritedIdsText,
    required this.defaultForProject,
  });

  final String id;
  final String displayName;
  final String summary;
  final String genre;
  final String tone;
  final String audience;
  final String tagsText;
  final String guardrailsText;
  final String examplePathsText;
  final String inheritedIdsText;
  final bool defaultForProject;
}

class ForeshadowRecordEditorRequestViewData {
  const ForeshadowRecordEditorRequestViewData({
    required this.id,
    required this.title,
    required this.status,
    required this.summary,
    required this.plantedChapterPath,
    required this.targetPayoffPath,
    required this.relatedEntityIdsText,
    required this.relatedPathsText,
    required this.triggerConditionsText,
    required this.payoffExpectationsText,
    required this.tagsText,
    required this.notes,
  });

  final String id;
  final String title;
  final String status;
  final String summary;
  final String plantedChapterPath;
  final String targetPayoffPath;
  final String relatedEntityIdsText;
  final String relatedPathsText;
  final String triggerConditionsText;
  final String payoffExpectationsText;
  final String tagsText;
  final String notes;
}

class ProjectAssetBundleImportRequestViewData {
  const ProjectAssetBundleImportRequestViewData({
    required this.absolutePath,
    required this.overwrite,
  });

  final String absolutePath;
  final bool overwrite;
}

class ProjectAssetBundleExportRequestViewData {
  const ProjectAssetBundleExportRequestViewData({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
