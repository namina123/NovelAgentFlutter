import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_structured_source_projection_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_source_resolution_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_app/shared/services/desktop_text_file_picker_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'execute runs shared runtime contract and reports projection summary',
    () async {
      final calls = <String, Object?>{};
      final service = ProjectReferenceExtractionExecutionService(
        readSettings: () => const AppSettings(
          defaultProviderId: 'provider_a',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'deepseek-v4-flash',
          defaultProjectPath: 'D:/Projects/demo',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'provider_a',
              title: 'Provider A',
              protocol: 'openai_compatible',
              baseUrl: 'https://example.invalid/v1',
              apiKey: 'test-key',
              modelId: 'deepseek-v4-flash',
              description: 'test',
              isDefault: true,
            ),
          ],
        ),
        llmGatewayFactory: (provider, networkSettings) {
          calls['provider_id'] = provider.id;
          return _FakeLlmGateway();
        },
        executeReferenceExtraction:
            ({
              required project,
              required llmGateway,
              required modelId,
              required request,
            }) async {
              calls['project_id'] = project.id;
              calls['model_id'] = modelId;
              calls['source_file_path'] = request.sourceFilePath;
              calls['display_name'] = request.displayName;
              calls['source_language'] = request.sourceLanguage;
              calls['strategy_profile_id'] = request.strategyProfileId;
              calls['target_language'] = request.targetLanguage;
              calls['available_context_chars'] = request.availableContextChars;
              calls['export_bundle'] = request.exportBundle;
              calls['attach_to_project'] = request.attachToProject;
              calls['project_mounted_entries'] = request.projectMountedEntries;
              return const ProjectReferenceExtractionResult(
                runId: 'run_1',
                packageId: 'pkg_a',
                packageVersionId: 'v1',
                sourceFilePath: 'D:/source/book.txt',
                sourceDecodeMode: 'utf8',
                groupResolutionKind: 'single_agent_fallback',
                selectedGroupId: 'reference_extraction_group',
                strategyProfileId: 'reference_extraction.standard',
                executionConcurrencyMode:
                    ReferenceExtractionConcurrencyModes.single,
                proposalCount: 6,
                acceptedProposalCount: 3,
                finalizedEntryCount: 12,
                publishedSnapshotAvailable: true,
                projectMountStatus: ProjectReferenceMountStatuses.applied,
                generatedProjectionPaths: <String>[
                  'knowledge/项目知识摘要.md',
                  'research/资料研究摘要.md',
                ],
              );
            },
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'project_reference_extraction_execution_service_test_',
      );
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}reference_source.txt',
      );
      await sourceFile.writeAsString('sample');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project_a',
          name: '测试项目',
          rootPath: 'D:/Projects/demo',
        ),
        sourceFilePath: sourceFile.path,
        strategyProfileId: 'reference_extraction.fact_focused',
      );

      expect(result.ok, isTrue);
      expect(result.didMutateProject, isTrue);
      expect(result.statusMessage, contains('接纳 3 条'));
      expect(result.statusMessage, contains('knowledge/项目知识摘要.md'));
      expect(calls['provider_id'], 'provider_a');
      expect(calls['project_id'], 'project_a');
      expect(calls['model_id'], 'deepseek-v4-flash');
      expect(calls['source_file_path'], sourceFile.absolute.path);
      expect(calls['display_name'], '参考资料提取：reference_source.txt');
      expect(calls['source_language'], '');
      expect(calls['strategy_profile_id'], 'reference_extraction.fact_focused');
      expect(calls['target_language'], 'zh-CN');
      expect(calls['available_context_chars'], 131072);
      expect(calls['export_bundle'], isTrue);
      expect(calls['attach_to_project'], isTrue);
      expect(calls['project_mounted_entries'], isTrue);
    },
  );

  test(
    'execute analysis-only stages a publishable snapshot without mounting project assets',
    () async {
      ProjectReferenceExtractionRequest? capturedRequest;
      final service = ProjectReferenceExtractionExecutionService(
        readSettings: () => const AppSettings(
          defaultProviderId: 'provider_a',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'deepseek-v4-flash',
          defaultProjectPath: 'D:/Projects/demo',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'provider_a',
              title: 'Provider A',
              protocol: 'openai_compatible',
              baseUrl: 'https://example.invalid/v1',
              apiKey: 'test-key',
              modelId: 'deepseek-v4-flash',
              description: 'test',
              isDefault: true,
            ),
          ],
        ),
        llmGatewayFactory: (_, networkSettings) => _FakeLlmGateway(),
        executeReferenceExtraction:
            ({
              required project,
              required llmGateway,
              required modelId,
              required request,
            }) async {
              capturedRequest = request;
              return const ProjectReferenceExtractionResult(
                runId: 'analysis_only_run',
                packageId: 'analysis_only_package',
                packageVersionId: 'v1',
                sourceFilePath: 'D:/source/book.txt',
                sourceDecodeMode: 'utf8',
                groupResolutionKind: 'single_agent_fallback',
                selectedGroupId: 'reference_extraction_group',
                strategyProfileId: 'reference_extraction.standard',
                executionConcurrencyMode:
                    ReferenceExtractionConcurrencyModes.single,
                proposalCount: 8,
                acceptedProposalCount: 5,
                finalizedEntryCount: 11,
                runStatus: ReferenceExtractionRunStatuses.completedPublishable,
                deliveryStatus: ReferenceExtractionDeliveryStatuses.publishable,
                outputCompletionStatus: OutputCompletionStatuses.completed,
                publishedSnapshotAvailable: true,
                projectMountStatus: ProjectReferenceMountStatuses.notRequested,
              );
            },
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'project_reference_extraction_analysis_only_test_',
      );
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}analysis_only_source.txt',
      );
      await sourceFile.writeAsString('sample');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project_analysis_only',
          name: '拆书分析项目',
          rootPath: 'D:/Projects/demo',
        ),
        sourceFilePath: sourceFile.path,
        analysisOnly: true,
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.exportBundle, isFalse);
      expect(capturedRequest!.attachToProject, isFalse);
      expect(capturedRequest!.projectMountedEntries, isFalse);
      expect(capturedRequest!.explicitProjectionConfirmationGranted, isFalse);
      expect(result.ok, isTrue);
      expect(result.didMutateProject, isFalse);
      expect(result.hasStagedPackage, isTrue);
      expect(result.runId, 'analysis_only_run');
      expect(result.packageId, 'analysis_only_package');
      expect(result.packageVersionId, 'v1');
      expect(result.statusMessage, contains('暂存 11 条结构化条目'));
      expect(result.statusMessage, contains('尚未应用到项目资产'));
    },
  );

  test(
    'execute resumes semantic continuation until published snapshot is available',
    () async {
      final runIds = <String>[];
      final packageIds = <String>[];
      final packageVersionIds = <String>[];
      var callCount = 0;
      final service = ProjectReferenceExtractionExecutionService(
        readSettings: () => const AppSettings(
          defaultProviderId: 'provider_a',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'deepseek-v4-flash',
          defaultProjectPath: 'D:/Projects/demo',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'provider_a',
              title: 'Provider A',
              protocol: 'openai_compatible',
              baseUrl: 'https://example.invalid/v1',
              apiKey: 'test-key',
              modelId: 'deepseek-v4-flash',
              description: 'test',
              isDefault: true,
            ),
          ],
        ),
        llmGatewayFactory: (_, networkSettings) => _FakeLlmGateway(),
        executeReferenceExtraction:
            ({
              required project,
              required llmGateway,
              required modelId,
              required request,
            }) async {
              callCount += 1;
              runIds.add(request.runId);
              packageIds.add(request.packageId);
              packageVersionIds.add(request.packageVersionId);
              if (callCount == 1) {
                return const ProjectReferenceExtractionResult(
                  runId: 'gui_run_1',
                  packageId: 'pkg_semantic',
                  packageVersionId: 'v_semantic',
                  sourceFilePath: 'D:/source/book.txt',
                  sourceDecodeMode: 'utf8',
                  groupResolutionKind: 'single_agent_fallback',
                  selectedGroupId: 'reference_extraction_group',
                  strategyProfileId: 'reference_extraction.standard',
                  executionConcurrencyMode:
                      ReferenceExtractionConcurrencyModes.single,
                  proposalCount: 6,
                  acceptedProposalCount: 4,
                  finalizedEntryCount: 0,
                  runStatus: ReferenceExtractionRunStatuses
                      .awaitingSemanticContinuation,
                  deliveryStatus:
                      ReferenceExtractionDeliveryStatuses.stagingOnly,
                  outputCompletionStatus:
                      OutputCompletionStatuses.coverageInsufficient,
                  needsContinuation: true,
                  publishedSnapshotAvailable: false,
                  projectMountStatus:
                      ProjectReferenceMountStatuses.snapshotUnavailable,
                );
              }
              return const ProjectReferenceExtractionResult(
                runId: 'gui_run_1',
                packageId: 'pkg_semantic',
                packageVersionId: 'v_semantic',
                sourceFilePath: 'D:/source/book.txt',
                sourceDecodeMode: 'utf8',
                groupResolutionKind: 'single_agent_fallback',
                selectedGroupId: 'reference_extraction_group',
                strategyProfileId: 'reference_extraction.standard',
                executionConcurrencyMode:
                    ReferenceExtractionConcurrencyModes.single,
                proposalCount: 8,
                acceptedProposalCount: 6,
                finalizedEntryCount: 10,
                runStatus: ReferenceExtractionRunStatuses.completedPublishable,
                deliveryStatus: ReferenceExtractionDeliveryStatuses.publishable,
                outputCompletionStatus: OutputCompletionStatuses.completed,
                needsContinuation: false,
                publishedSnapshotAvailable: true,
                projectMountStatus: ProjectReferenceMountStatuses.applied,
                generatedProjectionPaths: <String>['knowledge/项目知识摘要.md'],
              );
            },
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'project_reference_extraction_execution_service_test_',
      );
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}semantic_reference_source.txt',
      );
      await sourceFile.writeAsString('sample');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project_semantic',
          name: '测试项目',
          rootPath: 'D:/Projects/demo',
        ),
        sourceFilePath: sourceFile.path,
      );

      expect(result.ok, isTrue);
      expect(result.didMutateProject, isTrue);
      expect(callCount, 2);
      expect(runIds, hasLength(2));
      expect(runIds.first, isNotEmpty);
      expect(runIds.first, runIds.last);
      expect(packageIds, <String>['', 'pkg_semantic']);
      expect(packageVersionIds, <String>['', 'v_semantic']);
      expect(result.statusMessage, contains('沉淀 10 条'));
    },
  );

  test('execute reports incomplete extraction instead of fake success', () async {
    final service = ProjectReferenceExtractionExecutionService(
      readSettings: () => const AppSettings(
        defaultProviderId: 'provider_a',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-v4-flash',
        defaultProjectPath: 'D:/Projects/demo',
        autoSaveDrafts: false,
        providers: <ProviderEndpointSettings>[
          ProviderEndpointSettings(
            id: 'provider_a',
            title: 'Provider A',
            protocol: 'openai_compatible',
            baseUrl: 'https://example.invalid/v1',
            apiKey: 'test-key',
            modelId: 'deepseek-v4-flash',
            description: 'test',
            isDefault: true,
          ),
        ],
      ),
      llmGatewayFactory: (_, networkSettings) => _FakeLlmGateway(),
      executeReferenceExtraction:
          ({
            required project,
            required llmGateway,
            required modelId,
            required request,
          }) async => const ProjectReferenceExtractionResult(
            runId: 'gui_run_incomplete',
            packageId: 'pkg_incomplete',
            packageVersionId: 'v_incomplete',
            sourceFilePath: 'D:/source/book.txt',
            sourceDecodeMode: 'utf8',
            groupResolutionKind: 'single_agent_fallback',
            selectedGroupId: 'reference_extraction_group',
            strategyProfileId: 'reference_extraction.standard',
            executionConcurrencyMode:
                ReferenceExtractionConcurrencyModes.single,
            proposalCount: 6,
            acceptedProposalCount: 4,
            finalizedEntryCount: 0,
            runStatus:
                ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
            deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
            outputCompletionStatus:
                OutputCompletionStatuses.coverageInsufficient,
            needsContinuation: false,
            publishedSnapshotAvailable: false,
            projectMountStatus:
                ProjectReferenceMountStatuses.snapshotUnavailable,
            deliveryRationale: 'coverage followup required',
          ),
    );
    final tempDir = await Directory.systemTemp.createTemp(
      'project_reference_extraction_execution_service_test_',
    );
    final sourceFile = File(
      '${tempDir.path}${Platform.pathSeparator}incomplete_reference_source.txt',
    );
    await sourceFile.writeAsString('sample');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final result = await service.execute(
      project: const ProjectDescriptor(
        id: 'project_incomplete',
        name: '测试项目',
        rootPath: 'D:/Projects/demo',
      ),
      sourceFilePath: sourceFile.path,
    );

    expect(result.ok, isFalse);
    expect(result.didMutateProject, isFalse);
    expect(result.statusMessage, contains('暂未完成'));
    expect(result.statusMessage, contains('coverage_insufficient'));
  });

  test('pickAndExecute reports cancel without mutating project', () async {
    final service = ProjectReferenceExtractionExecutionService(
      readSettings: () => null,
      llmGatewayFactory: (_, networkSettings) => _FakeLlmGateway(),
      executeReferenceExtraction:
          ({
            required project,
            required llmGateway,
            required modelId,
            required request,
          }) async {
            throw UnimplementedError();
          },
      sourcePickerService: _FakePickerService(null),
    );

    final result = await service.pickAndExecute(
      project: const ProjectDescriptor(
        id: 'project_a',
        name: '测试项目',
        rootPath: 'D:/Projects/demo',
      ),
    );

    expect(result.ok, isFalse);
    expect(result.didMutateProject, isFalse);
    expect(result.statusMessage, '已取消参考资料提取。');
  });

  test(
    'pickAndExecute uses structured deconstruction source in analysis-only mode without mounting project assets',
    () async {
      final workspacePort = LocalProjectWorkspacePort();
      const project = ProjectDescriptor(
        id: 'project_deconstruction',
        name: '拆书测试项目',
        rootPath: 'D:/Projects/deconstruction_reference_project',
        projectType: BookDeconstructionConstants.projectTypeId,
      );
      final structuredPath =
          const BookDeconstructionStructuredSourceProjectionService()
              .targetPath(storageStrategy: project.storageStrategy);
      await workspacePort.writeTextFile(
        project.rootPath,
        structuredPath,
        '# 拆书结构化源文\n\n## 规范化正文\n\n第一章 港口风暴',
      );
      String? capturedSourcePath;
      ProjectReferenceExtractionRequest? capturedRequest;
      final service = ProjectReferenceExtractionExecutionService(
        readSettings: () => const AppSettings(
          defaultProviderId: 'provider_a',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'deepseek-v4-flash',
          defaultProjectPath: 'D:/Projects/demo',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'provider_a',
              title: 'Provider A',
              protocol: 'openai_compatible',
              baseUrl: 'https://example.invalid/v1',
              apiKey: 'test-key',
              modelId: 'deepseek-v4-flash',
              description: 'test',
              isDefault: true,
            ),
          ],
        ),
        llmGatewayFactory: (_, networkSettings) => _FakeLlmGateway(),
        executeReferenceExtraction:
            ({
              required project,
              required llmGateway,
              required modelId,
              required request,
            }) async {
              capturedSourcePath = request.sourceFilePath;
              capturedRequest = request;
              return const ProjectReferenceExtractionResult(
                runId: 'run_deconstruction',
                packageId: 'pkg_a',
                packageVersionId: 'v1',
                sourceFilePath: 'D:/source/book.txt',
                sourceDecodeMode: 'utf8',
                groupResolutionKind: 'single_agent_fallback',
                selectedGroupId: 'reference_extraction_group',
                strategyProfileId: 'reference_extraction.standard',
                executionConcurrencyMode:
                    ReferenceExtractionConcurrencyModes.single,
                proposalCount: 4,
                acceptedProposalCount: 2,
                finalizedEntryCount: 6,
                publishedSnapshotAvailable: true,
                projectMountStatus: ProjectReferenceMountStatuses.applied,
                generatedProjectionPaths: <String>['knowledge/项目知识摘要.md'],
              );
            },
        sourcePickerService: const _FakePickerService(null),
        sourceResolutionService:
            ProjectReferenceExtractionSourceResolutionService(
              workspacePort: workspacePort,
            ),
      );

      final result = await service.pickAndExecute(
        project: project,
        analysisOnly: true,
      );

      expect(result.ok, isTrue);
      expect(result.didMutateProject, isFalse);
      expect(result.statusMessage, contains('已使用拆书产物作为提取源文。'));
      expect(result.statusMessage, contains('尚未应用到项目资产'));
      expect(capturedSourcePath, isNotNull);
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.exportBundle, isFalse);
      expect(capturedRequest!.attachToProject, isFalse);
      expect(capturedRequest!.projectMountedEntries, isFalse);
      expect(
        capturedSourcePath!.replaceAll('\\', '/'),
        endsWith('analysis/book_deconstruction_structured_source.md'),
      );
    },
  );

  test(
    'source resolution uses the structured projection after a book project transitions to long_novel',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'project_reference_extraction_composite_project_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final compositeProject = ProjectDescriptor(
        id: 'transitioned_book_project',
        name: '已转长篇的拆书项目',
        rootPath: tempDir.path,
        projectType: 'long_novel',
        additionalTraitIds: const <String>['book_deconstruction'],
      );
      final workspacePort = LocalProjectWorkspacePort();
      final structuredPath =
          const BookDeconstructionStructuredSourceProjectionService()
              .targetPath(storageStrategy: compositeProject.storageStrategy);
      await workspacePort.writeTextFile(
        compositeProject.rootPath,
        structuredPath,
        '# 拆书结构化源文\n\n第一章 港口风暴',
      );

      var pickerCalled = false;
      final result =
          await ProjectReferenceExtractionSourceResolutionService(
            workspacePort: workspacePort,
          ).resolve(
            project: compositeProject,
            pickSourceFile: () async {
              pickerCalled = true;
              return null;
            },
          );

      expect(result.ok, isTrue);
      expect(result.usedDeconstructionProjection, isTrue);
      expect(result.statusMessage, '已使用拆书产物作为提取源文。');
      expect(pickerCalled, isFalse);
      expect(
        result.sourceFilePath.replaceAll('\\', '/'),
        endsWith('analysis/book_deconstruction_structured_source.md'),
      );
    },
  );
}

class _FakePickerService extends DesktopTextFilePickerService {
  const _FakePickerService(this.selection);

  final String? selection;

  @override
  Future<String?> pickSingleFile({required String dialogTitle}) async {
    return selection;
  }
}

class _FakeLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) {
    throw UnimplementedError();
  }
}
