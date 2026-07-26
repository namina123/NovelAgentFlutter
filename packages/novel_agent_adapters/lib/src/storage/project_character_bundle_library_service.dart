import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_bundle_apply_service.dart';
import 'project_bundle_directory_layout_service.dart';
import 'project_bundle_file_access_service.dart';
import 'project_bundle_preview_mapper_service.dart';
import 'project_bundle_write_file.dart';
import 'project_bundle_write_plan.dart';
import 'project_character_profile_repository.dart';
import 'project_organization_profile_repository.dart';

class ProjectCharacterBundleLibraryService {
  ProjectCharacterBundleLibraryService({
    required ProjectCharacterProfileRepository characterRepository,
    required ProjectOrganizationProfileRepository organizationRepository,
    required ProjectBundleFileAccessService fileAccessService,
    required ProjectBundleApplyService applyService,
    ProjectBundlePreviewMapperService? previewMapperService,
    ProjectBundleDirectoryLayoutService? directoryLayoutService,
    CharacterCardBundleDocumentService? documentService,
    CharacterCardBundleImportPreviewService? previewService,
    CharacterProfileNormalizerService? characterNormalizerService,
    OrganizationProfileNormalizerService? organizationNormalizerService,
    CharacterProfileMarkdownCodecService? characterCodecService,
    OrganizationProfileMarkdownCodecService? organizationCodecService,
  }) : _characterRepository = characterRepository,
       _organizationRepository = organizationRepository,
       _fileAccessService = fileAccessService,
       _applyService = applyService,
       _previewMapperService =
           previewMapperService ?? const ProjectBundlePreviewMapperService(),
       _directoryLayoutService =
           directoryLayoutService ??
           const ProjectBundleDirectoryLayoutService(),
       _documentService =
           documentService ?? CharacterCardBundleDocumentService(),
       _previewService =
           previewService ?? CharacterCardBundleImportPreviewService(),
       _characterNormalizerService =
           characterNormalizerService ??
           const CharacterProfileNormalizerService(),
       _organizationNormalizerService =
           organizationNormalizerService ??
           const OrganizationProfileNormalizerService(),
       _characterCodecService =
           characterCodecService ?? CharacterProfileMarkdownCodecService(),
       _organizationCodecService =
           organizationCodecService ??
           OrganizationProfileMarkdownCodecService();

  final ProjectCharacterProfileRepository _characterRepository;
  final ProjectOrganizationProfileRepository _organizationRepository;
  final ProjectBundleFileAccessService _fileAccessService;
  final ProjectBundleApplyService _applyService;
  final ProjectBundlePreviewMapperService _previewMapperService;
  final ProjectBundleDirectoryLayoutService _directoryLayoutService;
  final CharacterCardBundleDocumentService _documentService;
  final CharacterCardBundleImportPreviewService _previewService;
  final CharacterProfileNormalizerService _characterNormalizerService;
  final OrganizationProfileNormalizerService _organizationNormalizerService;
  final CharacterProfileMarkdownCodecService _characterCodecService;
  final OrganizationProfileMarkdownCodecService _organizationCodecService;

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
    final characters = await _characterRepository.listProfiles(project);
    final organizations = await _organizationRepository.listProfiles(project);
    final bundle = _documentService.buildBundle(
      characters: characters,
      organizations: organizations,
      title: title,
      description: description,
    );
    final directoryName = _directoryLayoutService.exportDirectoryName(
      bundleKind: BundleKind.characterCardBundle,
      title: ValueReaders.stringValue(bundle['title']),
    );
    final files = <String, String>{
      'bundle.json': _documentService.encodeBundle(bundle),
      for (final character in characters)
        'assets/characters/${character.id}.md': _characterCodecService.encode(
          character,
        ),
      for (final organization in organizations)
        'assets/organizations/${organization.id}.md': _organizationCodecService
            .encode(organization),
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
      return <String, Object?>{
        'ok': false,
        'error': 'Bundle 源不存在或缺少 bundle.json。',
      };
    }
    final preview = _previewService.previewBundle(
      bundleContent: source.bundleContent,
      existingCharacters: (await _characterRepository.listProfiles(
        project,
      )).map(_characterNormalizerService.toDocument).toList(growable: false),
      existingOrganizations: (await _organizationRepository.listProfiles(
        project,
      )).map(_organizationNormalizerService.toDocument).toList(growable: false),
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
    for (final rawCharacter in ValueReaders.mapList(bundle['characters'])) {
      final character = _characterNormalizerService.normalize(rawCharacter);
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
    for (final rawOrganization in ValueReaders.mapList(
      bundle['organizations'],
    )) {
      final organization = _organizationNormalizerService.normalize(
        rawOrganization,
      );
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
    return ProjectBundleWritePlan(
      bundleKind: BundleKind.characterCardBundle,
      title: ValueReaders.stringValue(preview['title']),
      sourcePath: sourcePath,
      files: files,
      skippedPaths: skippedPaths,
    );
  }

  Map<String, String> _actionByTargetPath(JsonMap preview) {
    final result = <String, String>{};
    for (final item in ValueReaders.mapList(preview['items'])) {
      result[ValueReaders.stringValue(item['target_path'])] =
          ValueReaders.stringValue(item['action']);
    }
    return result;
  }
}
