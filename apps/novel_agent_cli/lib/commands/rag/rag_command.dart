import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';
import '../shared/cli_arguments.dart';
import '../shared/cli_command_context.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_project_artifact_label_service.dart';

class RagCommand {
  RagCommand({
    required ProjectRepository projectRepository,
    required TerminalPrinter printer,
    CliProjectArtifactLabelService? projectArtifactLabelService,
    RagTxtCorpusIngestionService? ragTxtCorpusIngestionService,
    RagProjectMountSummaryService? ragProjectMountSummaryService,
    ProjectRagRetrievalToolExecutor? ragRetrievalToolExecutor,
  }) : _projectRepository = projectRepository,
       _printer = printer,
       _projectArtifactLabelService =
           projectArtifactLabelService ?? const CliProjectArtifactLabelService(),
       _ragTxtCorpusIngestionService =
           ragTxtCorpusIngestionService ?? RagTxtCorpusIngestionService(),
       _ragProjectMountSummaryService =
           ragProjectMountSummaryService ?? RagProjectMountSummaryService(),
       _ragRetrievalToolExecutor =
           ragRetrievalToolExecutor ?? ProjectRagRetrievalToolExecutor();

  final ProjectRepository _projectRepository;
  final TerminalPrinter _printer;
  final CliProjectArtifactLabelService _projectArtifactLabelService;
  final RagTxtCorpusIngestionService _ragTxtCorpusIngestionService;
  final RagProjectMountSummaryService _ragProjectMountSummaryService;
  final ProjectRagRetrievalToolExecutor _ragRetrievalToolExecutor;

  Future<int> run(List<String> args) async {
    // 中文注释: rag 命令组只负责薄入口分发，不在 CLI 层重新发明 RAG 业务中心。
    final action = args.isEmpty ? 'help' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'build':
        return _runBuild(rest);
      case 'list':
        return _runList(rest);
      case 'mount':
        return _runMount(rest);
      case 'diagnostics':
        return _runDiagnostics(rest);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 rag 子命令: $action');
        _printHelp();
        return CliExitCodes.invalidInput;
    }
  }

  Future<int> _runBuild(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final sourcePath =
        _optionValue(args, '--source') ?? _optionValue(args, '--path') ?? '';
    if (sourcePath.trim().isEmpty) {
      _printer.error('请通过 --source 指定 txt 源文件路径。');
      return 2;
    }
    final corpusPackage = RagCorpusPackage(
      corpusId: _optionValue(args, '--corpus-id')?.trim().isNotEmpty == true
          ? _optionValue(args, '--corpus-id')!.trim()
          : _buildCorpusId(sourcePath),
      title: _optionValue(args, '--title')?.trim().isNotEmpty == true
          ? _optionValue(args, '--title')!.trim()
          : 'RAG txt corpus',
      sourceKind: 'txt',
      buildMode: 'basic',
      language: _optionValue(args, '--language') ?? '',
      segmentationStrategy: _optionValue(args, '--segmentation') ?? '',
      chunkStrategy: _optionValue(args, '--chunk-strategy') ?? '',
      embeddingBackend: _optionValue(args, '--embedding-backend') ?? '',
      indexBackend: _optionValue(args, '--index-backend') ?? '',
      version: _optionValue(args, '--version') ?? 'v1',
    );
    try {
      final builtCorpus = await _ragTxtCorpusIngestionService.ingestFile(
        project: context.project,
        sourceFilePath: sourcePath,
        corpusPackage: corpusPackage,
      );
      _printer.success('RAG txt 语料已构建。');
      _printCorpusSummary(builtCorpus);
      return 0;
    } catch (error) {
      _printer.error('RAG txt 语料构建失败: $error');
      return 1;
    }
  }

  Future<int> _runList(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final repository = SqliteRagMetadataRepository();
    final items = await repository.listCorpora(context.project);
    if (items.isEmpty) {
      _printer.info('当前项目没有 RAG 语料。');
      return 0;
    }
    _printer.block(
      'RAG 语料列表',
      items.map(_formatCorpusLine).join('\n'),
    );
    return 0;
  }

  Future<int> _runMount(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final corpusId = _optionValue(args, '--corpus-id') ?? '';
    if (corpusId.trim().isEmpty) {
      _printer.error('请通过 --corpus-id 指定要挂载的语料。');
      return 2;
    }
    final repository = SqliteRagMetadataRepository();
    final corpus = await repository.readCorpus(
      context.project,
      corpusId: corpusId.trim(),
    );
    if (corpus == null) {
      _printer.error('未找到对应的 RAG 语料。');
      return 1;
    }
    final binding = RetrievalMountBinding(
      bindingId:
          '${context.project.id}_${corpus.corpusId}_mount_${DateTime.now().millisecondsSinceEpoch}',
      projectId: context.project.id,
      corpusId: corpus.corpusId,
      mountScope: _optionValue(args, '--scope') ?? 'project',
      priority: CliArguments(args).intValue('--priority', 100),
      usagePolicy: _optionValue(args, '--usage-policy') ?? 'evidence_only',
      activationPolicy:
          _optionValue(args, '--activation-policy') ?? 'project_activation',
      createdAt: DateTime.now().toIso8601String(),
      metadata: <String, Object?>{
        'source_corpus_title': corpus.title,
      },
    );
    await repository.upsertMountBinding(context.project, binding);
    _printer.success('RAG 语料已挂载。');
    _printer.info('项目: ${context.project.name}');
    _printer.info('语料: ${corpus.title}');
    _printer.info(
      '项目路径: ${_projectArtifactLabelService.formatPath('rag/${binding.bindingId}.json')}',
    );
    return 0;
  }

  Future<int> _runDiagnostics(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final summary = await _ragProjectMountSummaryService.summarize(
      context.project,
    );
    final corpusId = _optionValue(args, '--corpus-id') ?? '';
    final queryText = _optionValue(args, '--query') ?? '';
    final diagnostics = await _ragRetrievalToolExecutor.retrievePassages(
      context.project,
      <String, Object?>{
        'query_id': 'cli_rag_diagnostics',
        'query_text': queryText,
        'project_id': context.project.id,
        if (corpusId.trim().isNotEmpty)
          'corpus_filters': <String>[corpusId.trim()],
        'top_k': CliArguments(args).intValue('--top-k', 5),
      },
    );
    _printer.block('RAG 挂载摘要', _prettyJson(summary.toJson()));
    _printer.block('RAG 检索诊断', _prettyJson(diagnostics));
    return ValueReaders.boolValue(diagnostics['ok']) ? 0 : 1;
  }

  Future<CliProjectContext?> _projectContext(List<String> args) async {
    // 中文注释: rag 命令和其他 CLI 子命令共用项目打开规则，但不自己维护 settings。
    final projectPath = _optionValue(args, '--project');
    if (projectPath == null || projectPath.trim().isEmpty) {
      _printer.error('请通过 --project 指定项目路径。');
      return null;
    }
    final project = await _projectRepository.openByPath(projectPath);
    if (project == null) {
      _printer.error('项目不存在: $projectPath');
      return null;
    }
    return CliProjectContext(
      commandContext: CliCommandContext(
        settings: const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[],
        ),
        defaultProjectPath: projectPath,
      ),
      project: project,
      projectPath: projectPath,
    );
  }

  void _printCorpusSummary(RagCorpusPackage corpus) {
    _printer.block(
      'RAG 语料摘要',
      [
        '语料 ID：${corpus.corpusId}',
        '标题：${corpus.title}',
        '来源类型：${corpus.sourceKind}',
        '构建方式：${corpus.buildMode}',
        if (corpus.language.trim().isNotEmpty) '语言：${corpus.language}',
        '章数：${corpus.chapterCount}',
        'chunk 数：${corpus.chunkCount}',
        '模型辅助：${corpus.isModelAssisted ? '是' : '否'}',
        if (corpus.indexBackend.trim().isNotEmpty) '索引后端：${corpus.indexBackend}',
      ].join('\n'),
    );
  }

  void _printHelp() {
    // 中文注释: rag help 只展示已经落地的最小命令族，不提前暴露未实现的后端细节。
    CliHelpContract.printHelpBlock(_printer, 'rag help', [
      'rag build --source D:\\book.txt [--corpus-id corpus_1] [--project 路径]',
      'rag list [--project 路径]',
      'rag mount --corpus-id corpus_1 [--project 路径]',
      'rag diagnostics --query "镜潮" [--corpus-id corpus_1] [--project 路径]',
    ]);
  }

  String _buildCorpusId(String sourcePath) {
    // 中文注释: CLI 生成的 corpus id 只依赖文件名和时间戳，便于回放和排障。
    final fileName = File(sourcePath).uri.pathSegments.isEmpty
        ? 'txt'
        : File(sourcePath).uri.pathSegments.last;
    final cleanName = fileName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return 'rag_${cleanName.isEmpty ? 'txt' : cleanName}_$timestamp';
  }

  String _formatCorpusLine(RagCorpusPackage corpus) {
    // 中文注释: 列表只输出稳定摘要字段，避免 CLI 变成 corpus 细节浏览器。
    return [
      corpus.corpusId,
      corpus.title,
      corpus.sourceKind,
      corpus.buildMode,
      '${corpus.chapterCount}章/${corpus.chunkCount}chunk',
      if (corpus.indexBackend.trim().isNotEmpty) corpus.indexBackend,
    ].where((entry) => entry.trim().isNotEmpty).join('｜');
  }

  String? _optionValue(List<String> args, String name) {
    return CliArguments(args).value(name);
  }

  String _prettyJson(JsonMap value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
