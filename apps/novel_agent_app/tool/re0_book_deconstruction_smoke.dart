import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/desktop_book_deconstruction_source_picker_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  final repoRoot = Directory.current.parent.parent.path;
  final excerptPath = '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}re0_book_deconstruction_smoke${Platform.pathSeparator}re0_300k_excerpt.txt';
  final sourceFile = File(excerptPath);
  if (!await sourceFile.exists()) {
    stderr.writeln('excerpt missing: $excerptPath');
    exitCode = 1;
    return;
  }
  final workspaceRoot = Directory('$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}re0_book_deconstruction_smoke${Platform.pathSeparator}workspace')..createSync(recursive: true);
  final settingsRoot = Directory('${workspaceRoot.path}${Platform.pathSeparator}settings')..createSync(recursive: true);
  final projectsRoot = Directory('${workspaceRoot.path}${Platform.pathSeparator}projects')..createSync(recursive: true);
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: workspaceRoot.path,
    settingsRootPath: settingsRoot.path,
    defaultProjectRootPath: projectsRoot.path,
    allowConfiguredProjectPathOverride: false,
  );
  final project = ProjectDescriptor(
    id: 're0_smoke_project',
    name: 'RE0 拆书烟测',
    rootPath: '${projectsRoot.path}${Platform.pathSeparator}re0_smoke_project',
    projectType: BookDeconstructionConstants.projectTypeId,
  );
  Directory(project.rootPath).createSync(recursive: true);

  final controller = BookDeconstructionController(
    readProjectFileUseCase: ReadProjectFileUseCase(bundle.projectWorkspacePort),
    writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
      projectWorkspacePort: bundle.projectWorkspacePort,
    ),
    narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
      workspacePort: bundle.projectWorkspacePort,
    ),
    readCurrentProject: () => project,
    syncWorkbenchResources: () async {},
    onBackRequested: () {},
    sourcePickerService: _FixedPicker(sourceFile.path),
  );

  await controller.initialize();
  await controller.onBookDeconstructionImportFileRequested();
  await controller.onBookDeconstructionBuildPreviewRequested();

  final viewData = controller.viewData;
  final previewTitles = viewData.previewSections.map((item) => item.title).toList(growable: false);
  final summary = <String, Object?>{
    'source_path': sourceFile.path,
    'status': viewData.status,
    'source_length': viewData.sourceContent.length,
    'preview_section_titles': previewTitles,
    'preview_section_count': previewTitles.length,
    'plan_group_count': viewData.planGroups.length,
    'selected_item_count': viewData.selectedItemCount,
    'total_item_count': viewData.totalItemCount,
    'has_continuity': viewData.continuity != null,
    'confirmed_preview_path': viewData.confirmedPreviewPath,
  };

  final output = File('${workspaceRoot.path}${Platform.pathSeparator}re0_smoke_result.json');
  await output.writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(output.path);
}

class _FixedPicker extends DesktopBookDeconstructionSourcePickerService {
  _FixedPicker(this.path);

  final String path;

  @override
  Future<String?> pickSourceFile() async => path;
}
