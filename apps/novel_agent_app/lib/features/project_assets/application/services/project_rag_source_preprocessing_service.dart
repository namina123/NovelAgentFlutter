import 'dart:async';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/desktop_text_file_picker_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_smart_import_agent_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_smart_import_orchestration_service.dart';
import '../../../book_deconstruction/application/services/book_deconstruction_smart_import_result.dart';
import '../../../workbench/application/controllers/generate_draft_use_case_factory.dart';
import '../models/project_rag_preprocess_result.dart';

typedef ProjectRagPreprocessProgressCallback =
    FutureOr<void> Function(String statusMessage);

class ProjectRagSourcePreprocessingService {
  ProjectRagSourcePreprocessingService({
    DesktopTextFilePickerService? sourcePickerService,
    AppSettings? Function()? readSettings,
    GenerateDraftUseCaseFactory? generateDraftUseCaseFactory,
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
  }) : _sourcePickerService =
           sourcePickerService ?? const DesktopTextFilePickerService(),
       _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService();

  final DesktopTextFilePickerService _sourcePickerService;
  final AppSettings? Function()? _readSettings;
  final GenerateDraftUseCaseFactory? _generateDraftUseCaseFactory;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;

  Future<ProjectRagPreprocessResult?> pickAndPreprocess({
    required ProjectDescriptor project,
    ProjectRagPreprocessProgressCallback? onProgress,
  }) async {
    final selectedPath = await _sourcePickerService.pickSingleFile(
      dialogTitle: '选择待整理的源文文件',
    );
    if (selectedPath == null) {
      return null;
    }
    return preprocess(
      project: project,
      sourcePaths: <String>[selectedPath],
      onProgress: onProgress,
    );
  }

  Future<ProjectRagPreprocessResult> preprocess({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    ProjectRagPreprocessProgressCallback? onProgress,
  }) async {
    final cleanPaths = sourcePaths
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (cleanPaths.isEmpty) {
      return const ProjectRagPreprocessResult(
        ok: false,
        normalizedSourceText: '',
        displaySourceName: '',
        recentSourcePath: '',
        note: '缺少待整理的源文。',
      );
    }
    await _emitProgress(onProgress, '正在整理源文...');
    final smartResult = await _trySmartNormalize(
      project: project,
      sourcePaths: cleanPaths,
      onProgress: onProgress,
    );
    if (smartResult != null &&
        smartResult.normalizedSourceText.trim().isNotEmpty) {
      final primaryPath = cleanPaths.first;
      return ProjectRagPreprocessResult(
        ok: true,
        normalizedSourceText: smartResult.normalizedSourceText,
        displaySourceName: _displayName(primaryPath),
        recentSourcePath: primaryPath,
        note: smartResult.note,
        usedSmartNormalization: true,
      );
    }
    await _emitProgress(onProgress, '正在按离线规则整理纯文本...');
    final normalizedText = await _buildOfflineNormalizedText(cleanPaths);
    if (normalizedText.trim().isEmpty) {
      return ProjectRagPreprocessResult(
        ok: false,
        normalizedSourceText: '',
        displaySourceName: _displayName(cleanPaths.first),
        recentSourcePath: cleanPaths.first,
        note: smartResult?.note.trim().isNotEmpty == true
            ? smartResult!.note
            : '未能整理出可用纯文本。',
      );
    }
    final smartNote = smartResult?.note.trim() ?? '';
    return ProjectRagPreprocessResult(
      ok: true,
      normalizedSourceText: normalizedText,
      displaySourceName: _displayName(cleanPaths.first),
      recentSourcePath: cleanPaths.first,
      note: smartNote.isEmpty
          ? '已使用离线规则整理为可提取纯文本。'
          : '$smartNote 已回退使用离线规则整理为可提取纯文本。',
      usedSmartNormalization: false,
    );
  }

  Future<BookDeconstructionSmartImportResult?> _trySmartNormalize({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    ProjectRagPreprocessProgressCallback? onProgress,
  }) async {
    final readSettings = _readSettings;
    final generateDraftUseCaseFactory = _generateDraftUseCaseFactory;
    if (readSettings == null || generateDraftUseCaseFactory == null) {
      return null;
    }
    final settings = readSettings();
    if (settings == null || settings.providers.isEmpty) {
      return null;
    }
    final provider = _resolveProvider(settings);
    if (provider == null) {
      return null;
    }
    final modelId = _resolveModelId(settings, provider);
    if (modelId.isEmpty) {
      return null;
    }
    await _emitProgress(onProgress, '正在用智能拆书整理纯文本...');
    final orchestrationService =
        BookDeconstructionSmartImportOrchestrationService(
          agentService: BookDeconstructionSmartImportAgentService(
            readSettings: readSettings,
            generateDraftUseCaseFactory: generateDraftUseCaseFactory,
          ),
        );
    return orchestrationService.execute(
      project: project,
      sourcePaths: sourcePaths,
      providerId: provider.id,
      modelId: modelId,
    );
  }

  ProviderEndpointSettings? _resolveProvider(AppSettings settings) {
    final defaultProviderId = settings.defaultProviderId.trim();
    if (defaultProviderId.isNotEmpty) {
      for (final provider in settings.providers) {
        if (provider.id == defaultProviderId) {
          return provider;
        }
      }
    }
    return settings.providers.isEmpty ? null : settings.providers.first;
  }

  String _resolveModelId(
    AppSettings settings,
    ProviderEndpointSettings provider,
  ) {
    final defaultModelId = settings.defaultModelId.trim();
    if (defaultModelId.isNotEmpty) {
      return defaultModelId;
    }
    return provider.modelId.trim();
  }

  Future<String> _buildOfflineNormalizedText(List<String> sourcePaths) async {
    final sections = <String>[];
    for (final sourcePath in sourcePaths) {
      final fileText = await _readNormalizedSourceText(sourcePath);
      final cleaned = _applyOfflineCleanup(fileText);
      if (cleaned.isEmpty) {
        continue;
      }
      if (sections.isNotEmpty) {
        sections.add('');
      }
      sections.add(cleaned);
    }
    return sections.join('\n').trim();
  }

  Future<String> _readNormalizedSourceText(String sourcePath) async {
    final document = await _sourceDocumentReaderService.read(
      sourceFilePath: sourcePath,
    );
    return document.sourceText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  String _applyOfflineCleanup(String sourceText) {
    final normalized = sourceText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final keptLines = <String>[];
    var blankLineOpen = false;
    for (final rawLine in normalized.split('\n')) {
      final trimmed = rawLine.trimRight();
      final content = trimmed.trim();
      if (content.isEmpty) {
        if (!blankLineOpen && keptLines.isNotEmpty) {
          keptLines.add('');
          blankLineOpen = true;
        }
        continue;
      }
      if (_shouldDropLine(content)) {
        continue;
      }
      keptLines.add(trimmed);
      blankLineOpen = false;
    }
    return keptLines.join('\n').trim();
  }

  bool _shouldDropLine(String line) {
    const blockedContains = <String>[
      '最新网址',
      '最新域名',
      '收藏本站',
      '手机用户请浏览',
      '广告',
      '本章未完',
      '点击下一页',
      '请记住本书首发域名',
    ];
    for (final pattern in blockedContains) {
      if (line.contains(pattern)) {
        return true;
      }
    }
    final blockedPatterns = <RegExp>[
      RegExp(r'^\s*ps[:：]?', caseSensitive: false),
      RegExp(r'^\s*第?\s*\d+\s*/\s*\d+\s*页\s*$'),
      RegExp(r'^\s*www\.', caseSensitive: false),
      RegExp(r'^\s*https?://', caseSensitive: false),
    ];
    for (final pattern in blockedPatterns) {
      if (pattern.hasMatch(line)) {
        return true;
      }
    }
    return false;
  }

  String _displayName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '源文';
    }
    return normalized.split('/').last.trim();
  }

  Future<void> _emitProgress(
    ProjectRagPreprocessProgressCallback? onProgress,
    String statusMessage,
  ) async {
    if (onProgress == null) {
      return;
    }
    await onProgress(statusMessage);
  }
}
