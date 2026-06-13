import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_reference_extraction_runtime_models.dart';

class ProjectReferenceExtractionRequestBuilderService {
  const ProjectReferenceExtractionRequestBuilderService();

  ProjectReferenceExtractionRequest build(
    ProjectReferenceExtractionRequestInput input,
  ) {
    final absoluteSourceFilePath = File(
      input.sourceFilePath.trim(),
    ).absolute.path;
    final sourceFileName = absoluteSourceFilePath
        .replaceAll('\\', '/')
        .split('/')
        .last;
    return ProjectReferenceExtractionRequest(
      sourceFilePath: absoluteSourceFilePath,
      packageId: input.packageId.trim(),
      packageKind: input.packageKind.trim().isEmpty
          ? 'reference_work_package'
          : input.packageKind.trim(),
      displayName: _resolveDisplayName(
        explicitDisplayName: input.displayName,
        sourceFileName: sourceFileName,
      ),
      packageVersionId: input.packageVersionId.trim(),
      versionLabel: input.versionLabel.trim(),
      packageNamespace: input.packageNamespace.trim(),
      createdBy: input.createdBy.trim(),
      sourceLanguage: input.sourceLanguage.trim(),
      targetLanguage: input.targetLanguage.trim().isEmpty
          ? 'zh-CN'
          : input.targetLanguage.trim(),
      maxChapterEntries: input.maxChapterEntries > 0
          ? input.maxChapterEntries
          : 6,
      maxEntityEntries: input.maxEntityEntries > 0 ? input.maxEntityEntries : 6,
      exportBundle: input.exportBundle,
      attachToProject: input.attachToProject,
      projectMountedEntries: input.projectMountedEntries,
      explicitProjectionConfirmationGranted:
          input.explicitProjectionConfirmationGranted,
      bundleOutputDirectory: input.bundleOutputDirectory.trim(),
      runId: input.runId.trim(),
      strategyProfileId: input.strategyProfileId.trim(),
      availableContextChars: input.availableContextChars > 0
          ? input.availableContextChars
          : 0,
      additionalStrategyProfiles:
          List<ReferenceExtractionStrategyProfile>.unmodifiable(
            input.additionalStrategyProfiles,
          ),
    );
  }

  String _resolveDisplayName({
    required String explicitDisplayName,
    required String sourceFileName,
  }) {
    final trimmed = explicitDisplayName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return sourceFileName.isEmpty ? '参考资料提取' : '参考资料提取：$sourceFileName';
  }
}

class ProjectReferenceExtractionRequestInput {
  const ProjectReferenceExtractionRequestInput({
    required this.sourceFilePath,
    this.packageId = '',
    this.packageKind = 'reference_work_package',
    this.displayName = '',
    this.packageVersionId = '',
    this.versionLabel = '',
    this.packageNamespace = '',
    this.createdBy = '',
    this.sourceLanguage = '',
    this.targetLanguage = 'zh-CN',
    this.maxChapterEntries = 6,
    this.maxEntityEntries = 6,
    this.exportBundle = true,
    this.attachToProject = true,
    this.projectMountedEntries = true,
    this.explicitProjectionConfirmationGranted = true,
    this.bundleOutputDirectory = '',
    this.runId = '',
    this.strategyProfileId = '',
    this.availableContextChars = 0,
    this.additionalStrategyProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  });

  final String sourceFilePath;
  final String packageId;
  final String packageKind;
  final String displayName;
  final String packageVersionId;
  final String versionLabel;
  final String packageNamespace;
  final String createdBy;
  final String sourceLanguage;
  final String targetLanguage;
  final int maxChapterEntries;
  final int maxEntityEntries;
  final bool exportBundle;
  final bool attachToProject;
  final bool projectMountedEntries;
  final bool explicitProjectionConfirmationGranted;
  final String bundleOutputDirectory;
  final String runId;
  final String strategyProfileId;
  final int availableContextChars;
  final List<ReferenceExtractionStrategyProfile> additionalStrategyProfiles;
}
