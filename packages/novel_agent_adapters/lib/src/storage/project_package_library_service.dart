import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_asset_library_service.dart';
import 'project_bundle_apply_service.dart';
import 'project_bundle_directory_layout_service.dart';
import 'project_bundle_file_access_service.dart';
import 'project_bundle_preview_mapper_service.dart';
import 'project_bundle_write_file.dart';
import 'project_bundle_write_plan.dart';
import 'project_character_profile_repository.dart';
import 'project_organization_profile_repository.dart';
import 'project_prompt_template_service.dart';
import 'project_relationship_repository.dart';
import 'project_runtime_profile_repository.dart';
import 'project_timeline_repository.dart';

class ProjectPackageLibraryService {
  ProjectPackageLibraryService({
    required ProjectWorkspacePort workspacePort,
    required ProjectRuntimeProfileRepository runtimeProfileRepository,
    required ProjectPromptTemplateService promptTemplateService,
    required ProjectCharacterProfileRepository characterRepository,
    required ProjectOrganizationProfileRepository organizationRepository,
    required ProjectAssetLibraryService assetLibraryService,
    required ProjectRelationshipRepository relationshipRepository,
    required ProjectTimelineRepository timelineRepository,
    required ProjectBundleFileAccessService fileAccessService,
    required ProjectBundleApplyService applyService,
    ProjectBundlePreviewMapperService? previewMapperService,
    ProjectBundleDirectoryLayoutService? directoryLayoutService,
    ProjectPackageDocumentService? documentService,
    ProjectPackageImportPreviewService? previewService,
    ProjectManifestCodecService? manifestCodecService,
    ProjectRuntimeProfileDocumentService? runtimeProfileDocumentService,
    PromptTemplateNormalizerService? promptTemplateNormalizerService,
    StyleProfileNormalizerService? styleNormalizerService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
    RelationshipRecordNormalizerService? relationshipNormalizerService,
    TimelineRecordNormalizerService? timelineNormalizerService,
    CharacterProfileMarkdownCodecService? characterCodecService,
    OrganizationProfileMarkdownCodecService? organizationCodecService,
    StyleProfileMarkdownCodecService? styleCodecService,
    ForeshadowRecordMarkdownCodecService? foreshadowCodecService,
    RelationshipRecordMarkdownCodecService? relationshipCodecService,
    TimelineRecordMarkdownCodecService? timelineCodecService,
  }) : _workspacePort = workspacePort,
       _runtimeProfileRepository = runtimeProfileRepository,
       _promptTemplateService = promptTemplateService,
       _characterRepository = characterRepository,
       _organizationRepository = organizationRepository,
       _assetLibraryService = assetLibraryService,
       _relationshipRepository = relationshipRepository,
       _timelineRepository = timelineRepository,
       _fileAccessService = fileAccessService,
       _applyService = applyService,
       _previewMapperService =
           previewMapperService ?? const ProjectBundlePreviewMapperService(),
       _directoryLayoutService =
           directoryLayoutService ?? const ProjectBundleDirectoryLayoutService(),
       _documentService = documentService ?? ProjectPackageDocumentService(),
       _previewService = previewService ?? ProjectPackageImportPreviewService(),
       _manifestCodecService =
           manifestCodecService ?? ProjectManifestCodecService(),
       _runtimeProfileDocumentService =
           runtimeProfileDocumentService ??
           ProjectRuntimeProfileDocumentService(),
       _promptTemplateNormalizerService =
           promptTemplateNormalizerService ?? PromptTemplateNormalizerService(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _relationshipNormalizerService =
           relationshipNormalizerService ??
           const RelationshipRecordNormalizerService(),
       _timelineNormalizerService =
           timelineNormalizerService ?? const TimelineRecordNormalizerService(),
       _characterCodecService =
           characterCodecService ?? CharacterProfileMarkdownCodecService(),
       _organizationCodecService =
           organizationCodecService ?? OrganizationProfileMarkdownCodecService(),
       _styleCodecService =
           styleCodecService ?? StyleProfileMarkdownCodecService(),
       _foreshadowCodecService =
           foreshadowCodecService ?? ForeshadowRecordMarkdownCodecService(),
       _relationshipCodecService =
           relationshipCodecService ?? RelationshipRecordMarkdownCodecService(),
       _timelineCodecService =
           timelineCodecService ?? TimelineRecordMarkdownCodecService();

  final ProjectWorkspacePort _workspacePort;
  final ProjectRuntimeProfileRepository _runtimeProfileRepository;
  final ProjectPromptTemplateService _promptTemplateService;
  final ProjectCharacterProfileRepository _characterRepository;
  final ProjectOrganizationProfileRepository _organizationRepository;
  final ProjectAssetLibraryService _assetLibraryService;
  final ProjectRelationshipRepository _relationshipRepository;
  final ProjectTimelineRepository _timelineRepository;
  final ProjectBundleFileAccessService _fileAccessService;
  final ProjectBundleApplyService _applyService;
  final ProjectBundlePreviewMapperService _previewMapperService;
  final ProjectBundleDirectoryLayoutService _directoryLayoutService;
  final ProjectPackageDocumentService _documentService;
  final ProjectPackageImportPreviewService _previewService;
  final ProjectManifestCodecService _manifestCodecService;
  final ProjectRuntimeProfileDocumentService _runtimeProfileDocumentService;
  final PromptTemplateNormalizerService _promptTemplateNormalizerService;
  final StyleProfileNormalizerService _styleNormalizerService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final RelationshipRecordNormalizerService _relationshipNormalizerService;
  final TimelineRecordNormalizerService _timelineNormalizerService;
  final CharacterProfileMarkdownCodecService _characterCodecService;
  final OrganizationProfileMarkdownCodecService _organizationCodecService;
  final StyleProfileMarkdownCodecService _styleCodecService;
  final ForeshadowRecordMarkdownCodecService _foreshadowCodecService;
  final RelationshipRecordMarkdownCodecService _relationshipCodecService;
  final TimelineRecordMarkdownCodecService _timelineCodecService;

  Future<JsonMap> previewImport(
    ProjectDescriptor project, {
    required String sourcePath,
    bool overwrite = false,
  }) async {
    final state = await _loadState(
      project,
      sourcePath: sourcePath,
      overwrite: overwrite,
    );
    if (!ValueReaders.boolValue(state['ok'])) {
      return state;
    }
    return <String, Object?>{
      'ok': true,
      'source_root_path': state['source_root_path'],
      'source_bundle_path': state['source_bundle_path'],
      'preview': state['preview'],
    };
  }

  Future<JsonMap> buildImportWritePlan(
    ProjectDescriptor project, {
    required String sourcePath,
    bool overwrite = false,
  }) async {
    final state = await _loadState(
      project,
      sourcePath: sourcePath,
      overwrite: overwrite,
    );
    if (!ValueReaders.boolValue(state['ok'])) {
      return state;
    }
    final plan = _buildPlan(
      sourcePath: ValueReaders.stringValue(state['source_bundle_path']),
      bundle: ValueReaders.mapValue(state['bundle']),
      preview: ValueReaders.mapValue(state['preview']),
    );
    return <String, Object?>{'ok': true, 'write_plan': plan.toJson()};
  }

  Future<JsonMap> importBundle(
    ProjectDescriptor project, {
    required String sourcePath,
    bool overwrite = false,
  }) async {
    final state = await _loadState(
      project,
      sourcePath: sourcePath,
      overwrite: overwrite,
    );
    if (!ValueReaders.boolValue(state['ok'])) {
      return state;
    }
    final plan = _buildPlan(
      sourcePath: ValueReaders.stringValue(state['source_bundle_path']),
      bundle: ValueReaders.mapValue(state['bundle']),
      preview: ValueReaders.mapValue(state['preview']),
    );
    return _applyService.applyToProject(project, plan);
  }

  Future<JsonMap> exportBundle(
    ProjectDescriptor project, {
    required String targetDirectoryPath,
    String title = '',
    String description = '',
  }) async {
    final manifest = await _loadManifest(project);
    final runtimeProfile = await _runtimeProfileRepository.load(project);
    final characters = await _characterRepository.listProfiles(project);
    final organizations = await _organizationRepository.listProfiles(project);
    final styles = (await _assetLibraryService.listStyles(
      project,
    )).map(_styleNormalizerService.normalize).toList(growable: false);
    final foreshadows = (await _assetLibraryService.listForeshadows(
      project,
    )).map(_foreshadowNormalizerService.normalize).toList(growable: false);
    final relationships = await _relationshipRepository.list(project);
    final timelines = await _timelineRepository.list(project);
    final templates = await _promptTemplateService.listProjectTemplates(project);
    final bundle = _documentService.buildBundle(
      projectId: project.id,
      manifest: manifest,
      runtimeProfile: runtimeProfile,
      characters: characters,
      organizations: organizations,
      styles: styles,
      foreshadows: foreshadows,
      relationships: relationships,
      timelines: timelines,
      promptTemplates: templates,
      title: title,
      description: description,
    );
    final directoryName = _directoryLayoutService.exportDirectoryName(
      bundleKind: BundleKind.projectPackage,
      title: ValueReaders.stringValue(bundle['title']),
    );
    final files = <String, String>{
      'bundle.json': _documentService.encodeBundle(bundle),
      ProjectManifestCodecService.manifestRelativePath:
          _manifestCodecService.encode(manifest),
      ProjectRuntimeProfileDocumentService.profileRelativePath:
          _runtimeProfileDocumentService.encode(runtimeProfile),
      for (final character in characters)
        'assets/characters/${character.id}.md': _characterCodecService.encode(character),
      for (final organization in organizations)
        'assets/organizations/${organization.id}.md': _organizationCodecService.encode(organization),
      for (final style in styles) 'assets/styles/${style.id}.style.md': _styleCodecService.encode(style),
      for (final foreshadow in foreshadows)
        'assets/foreshadows/${foreshadow.id}.foreshadow.md': _foreshadowCodecService.encode(foreshadow),
      for (final relationship in relationships)
        'assets/relationships/${relationship.id}.relationship.md': _relationshipCodecService.encode(relationship),
      for (final timeline in timelines)
        'assets/timeline/${timeline.id}.timeline.md': _timelineCodecService.encode(timeline),
      for (final template in templates)
        'prompts/${ValueReaders.stringValue(template['id'])}.json': _encodeJson(
          _promptTemplateNormalizerService.normalizeTemplate(template),
        ),
    };
    final exportDirectoryPath = await _fileAccessService.writeExportDirectory(
      targetDirectoryPath: targetDirectoryPath,
      directoryName: directoryName,
      files: files,
    );
    return <String, Object?>{
      'ok': true,
      'export_directory_path': exportDirectoryPath,
      'bundle_file_path': _fileAccessService.joinWithinDirectory(
        exportDirectoryPath,
        'bundle.json',
      ),
      'written_files': files.keys.toList(growable: false),
    };
  }

  Future<JsonMap> _loadState(
    ProjectDescriptor project, {
    required String sourcePath,
    required bool overwrite,
  }) async {
    final source = await _fileAccessService.readBundleSource(sourcePath);
    if (source == null) {
      return <String, Object?>{'ok': false, 'error': 'Bundle 源不存在或缺少 bundle.json。'};
    }
    final preview = _previewService.previewBundle(
      bundleContent: source.bundleContent,
      existingProjectId: project.id,
      existingCharacters: (await _characterRepository.listProfiles(project))
          .map((item) => const CharacterProfileNormalizerService().toDocument(item))
          .toList(growable: false),
      existingOrganizations:
          (await _organizationRepository.listProfiles(project))
              .map(
                (item) => const OrganizationProfileNormalizerService()
                    .toDocument(item),
              )
              .toList(growable: false),
      existingStyles: await _assetLibraryService.listStyles(project),
      existingForeshadows: await _assetLibraryService.listForeshadows(project),
      existingRelationships: (await _relationshipRepository.list(project))
          .map(_relationshipNormalizerService.toDocument)
          .toList(growable: false),
      existingTimelines: (await _timelineRepository.list(project))
          .map(_timelineNormalizerService.toDocument)
          .toList(growable: false),
      existingTemplates: await _promptTemplateService.listProjectTemplates(
        project,
      ),
      overwrite: overwrite,
    );
    return <String, Object?>{
      'ok': true,
      'source_root_path': source.rootDirectoryPath,
      'source_bundle_path': source.bundleFilePath,
      'bundle': _documentService.parseBundle(source.bundleContent),
      'preview': _previewMapperService.toJson(preview),
    };
  }

  ProjectBundleWritePlan _buildPlan({
    required String sourcePath,
    required JsonMap bundle,
    required JsonMap preview,
  }) {
    final actionByPath = _actionByTargetPath(preview);
    final files = <ProjectBundleWriteFile>[];
    final skippedPaths = <String>[];
    final projectTargetPath = ProjectManifestCodecService.manifestRelativePath;
    if (actionByPath[projectTargetPath] == 'skip') {
      skippedPaths.add(projectTargetPath);
      skippedPaths.add(ProjectRuntimeProfileDocumentService.profileRelativePath);
    } else {
      final manifest = _manifestCodecService.fromJson(
        ValueReaders.mapValue(bundle['project_manifest']),
      );
      final runtimeProfile = _runtimeProfileDocumentService.fromJson(
        ValueReaders.mapValue(bundle['runtime_profile']),
      );
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'project_manifest',
          entryId: ValueReaders.stringValue(
            ValueReaders.mapValue(bundle['project'])['project_id'],
          ),
          targetPath: projectTargetPath,
          content: _manifestCodecService.encode(manifest),
        ),
      );
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'runtime_profile',
          entryId: runtimeProfile.runtimeBaselineId,
          targetPath: ProjectRuntimeProfileDocumentService.profileRelativePath,
          content: _runtimeProfileDocumentService.encode(runtimeProfile),
        ),
      );
    }
    _appendCharacterFiles(bundle, actionByPath, files, skippedPaths);
    _appendOrganizationFiles(bundle, actionByPath, files, skippedPaths);
    _appendStyleFiles(bundle, actionByPath, files, skippedPaths);
    _appendForeshadowFiles(bundle, actionByPath, files, skippedPaths);
    _appendRelationshipFiles(bundle, actionByPath, files, skippedPaths);
    _appendTimelineFiles(bundle, actionByPath, files, skippedPaths);
    _appendTemplateFiles(bundle, actionByPath, files, skippedPaths);
    return ProjectBundleWritePlan(
      bundleKind: BundleKind.projectPackage,
      title: ValueReaders.stringValue(preview['title']),
      sourcePath: sourcePath,
      files: files,
      skippedPaths: skippedPaths,
    );
  }

  void _appendCharacterFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawCharacter in ValueReaders.mapList(bundle['characters'])) {
      final character = const CharacterProfileNormalizerService().normalize(
        rawCharacter,
      );
      if (character.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/characters/${character.id}.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'character',
          entryId: character.id,
          targetPath: targetPath,
          content: _characterCodecService.encode(character),
        ),
      );
    }
  }

  void _appendOrganizationFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawOrganization in ValueReaders.mapList(bundle['organizations'])) {
      final organization = const OrganizationProfileNormalizerService()
          .normalize(rawOrganization);
      if (organization.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/organizations/${organization.id}.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'organization',
          entryId: organization.id,
          targetPath: targetPath,
          content: _organizationCodecService.encode(organization),
        ),
      );
    }
  }

  void _appendStyleFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawStyle in ValueReaders.mapList(bundle['styles'])) {
      final style = _styleNormalizerService.normalize(rawStyle);
      if (style.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/styles/${style.id}.style.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'style',
          entryId: style.id,
          targetPath: targetPath,
          content: _styleCodecService.encode(style),
        ),
      );
    }
  }

  void _appendForeshadowFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawForeshadow in ValueReaders.mapList(bundle['foreshadows'])) {
      final foreshadow = _foreshadowNormalizerService.normalize(rawForeshadow);
      if (foreshadow.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/foreshadows/${foreshadow.id}.foreshadow.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'foreshadow',
          entryId: foreshadow.id,
          targetPath: targetPath,
          content: _foreshadowCodecService.encode(foreshadow),
        ),
      );
    }
  }

  void _appendRelationshipFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawRelationship in ValueReaders.mapList(bundle['relationships'])) {
      final relationship = _relationshipNormalizerService.normalize(
        rawRelationship,
      );
      if (relationship.id.trim().isEmpty) {
        continue;
      }
      final targetPath =
          'assets/relationships/${relationship.id}.relationship.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'relationship',
          entryId: relationship.id,
          targetPath: targetPath,
          content: _relationshipCodecService.encode(relationship),
        ),
      );
    }
  }

  void _appendTimelineFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawTimeline in ValueReaders.mapList(bundle['timelines'])) {
      final timeline = _timelineNormalizerService.normalize(rawTimeline);
      if (timeline.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/timeline/${timeline.id}.timeline.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'timeline',
          entryId: timeline.id,
          targetPath: targetPath,
          content: _timelineCodecService.encode(timeline),
        ),
      );
    }
  }

  void _appendTemplateFiles(
    JsonMap bundle,
    Map<String, String> actionByPath,
    List<ProjectBundleWriteFile> files,
    List<String> skippedPaths,
  ) {
    for (final rawTemplate in ValueReaders.mapList(bundle['prompt_templates'])) {
      final template = _promptTemplateNormalizerService.normalizeTemplate(
        rawTemplate,
      );
      final templateId = ValueReaders.stringValue(template['id']).trim();
      if (templateId.isEmpty) {
        continue;
      }
      final targetPath = _promptTemplateNormalizerService.templatePath(
        templateId,
      );
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'prompt_template',
          entryId: templateId,
          targetPath: targetPath,
          content: _encodeJson(template),
        ),
      );
    }
  }

  Future<ProjectManifest> _loadManifest(ProjectDescriptor project) async {
    final content = await _workspacePort.readTextFile(
      project.rootPath,
      ProjectManifestCodecService.manifestRelativePath,
    );
    return _manifestCodecService.parse(
      content ?? '',
      fallbackTitle: project.name,
      fallbackProjectType: project.projectType,
      fallbackStorageStrategy: project.storageStrategy,
      fallbackRuntimeBaselineId: project.runtimeBaselineId,
    );
  }

  Map<String, String> _actionByTargetPath(JsonMap preview) {
    final result = <String, String>{};
    for (final item in ValueReaders.mapList(preview['items'])) {
      result[ValueReaders.stringValue(item['target_path'])] = ValueReaders
          .stringValue(item['action']);
    }
    return result;
  }

  String _encodeJson(JsonMap value) {
    return '${const JsonEncoder.withIndent('  ').convert(value)}\n';
  }
}
