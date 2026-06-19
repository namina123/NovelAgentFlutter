import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_smart_import_agent_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_smart_import_workspace_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('smart import agent service reads normalized output from temp workspace', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_smart_import_agent_service_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final sourceFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}source.txt',
    );
    await sourceFile.writeAsString('第一章 广告\n正文内容\n第二章 继续');

    final workspaceService = BookDeconstructionSmartImportWorkspaceService();
    final workspace = await workspaceService.create(
      project: ProjectDescriptor(
        id: 'project-smart-import',
        name: '拆书项目',
        rootPath: tempDirectory.path,
        projectType: BookDeconstructionConstants.projectTypeId,
      ),
      sourcePaths: <String>[sourceFile.path],
      sourceDocumentReaderService: ReferenceSourceDocumentFileReaderService(),
    );

    final scriptedUseCase = ScriptedGenerateDraftUseCase(
      resultBuilder:
          ({
            required ProjectDescriptor project,
            required String userPrompt,
            required String modelId,
          }) {
            final normalizedFile = File(
              '${project.rootPath}${Platform.pathSeparator}outputs${Platform.pathSeparator}normalized_source.md',
            );
            normalizedFile.parent.createSync(recursive: true);
            normalizedFile.writeAsStringSync('第一章\n正文内容\n第二章\n继续');
            final reportFile = File(
              '${project.rootPath}${Platform.pathSeparator}outputs${Platform.pathSeparator}import_report.md',
            );
            reportFile.parent.createSync(recursive: true);
            reportFile.writeAsStringSync('已清理广告并识别章节。');
            return DraftGenerationResult(
              project: project,
              projectInfo: const <String, Object?>{},
              userPrompt: userPrompt,
              prompt: userPrompt,
              modelId: modelId,
              draftMarkdown: 'done',
              contextPack: const <String, Object?>{},
              selectedPaths: const <String>[],
              executedTools: const <Object?>[],
              writtenPaths: const <String>[],
              changedPaths: const <String>[],
              transcriptMessages: const <JsonMap>[],
              waitingForUserChoice: false,
              reasoningContent: '',
              stoppedByToolError: false,
              toolErrorSummary: '',
            );
          },
    )..releaseResult();

    final settings = AppSettings(
      defaultAgentId: 'default-agent',
      providers: const <ProviderEndpointSettings>[
        ProviderEndpointSettings(
          id: 'provider-1',
          title: 'Provider',
          protocol: 'openai_compatible',
          baseUrl: 'https://example.invalid/v1',
          apiKey: 'test-key',
          modelId: 'test-model',
          description: 'test',
        ),
      ],
      defaultProviderId: 'provider-1',
      defaultModelId: 'test-model',
      defaultProjectPath: tempDirectory.path,
    );

    final service = BookDeconstructionSmartImportAgentService(
      readSettings: () => settings,
      generateDraftUseCaseFactory: (_, _) => scriptedUseCase,
    );

    final result = await service.execute(
      workspace: workspace,
      providerId: 'provider-1',
      modelId: 'test-model',
    );

    expect(result.applied, isTrue);
    expect(result.normalizedSourceText, contains('正文内容'));
    expect(result.reportPath, 'outputs/import_report.md');
    expect(result.reportContent, contains('已清理广告'));
    expect(scriptedUseCase.lastModelId, 'test-model');
  });
}
