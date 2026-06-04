import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';

typedef ProbeResultValidator =
    Future<Map<String, Object?>> Function(DraftGenerationResult result);

class ProbeApiConfig {
  const ProbeApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  final String baseUrl;
  final String apiKey;
  final String modelId;
}

final class ProbeReportCategories {
  static const String success = 'success';
  static const String technicalFailure = 'technical_failure';
  static const String waitingUser = 'waiting_user';
  static const String budgetFailure = 'budget_failure';
  static const String contentQualityFailure = 'content_quality_failure';
}

Future<ProbeApiConfig> loadProbeApiConfig({
  String probeName = 'novel_agent_app_probe',
  bool requireRealProbeOptIn = true,
  bool allowLegacyTestApi = true,
  bool allowTempSettingsFallback = true,
  String? repoRootOverride,
  Directory? startDirectory,
  Map<String, String>? environment,
}) async {
  // 中文注释: app 侧真实探针统一走仓库级本地配置入口，避免每支脚本继续各自读取密钥文件。
  final config = await loadLocalProbeApiConfig(
    probeName: probeName,
    requireRealProbeOptIn: requireRealProbeOptIn,
    allowLegacyTestApi: allowLegacyTestApi,
    allowTempSettingsFallback: allowTempSettingsFallback,
    repoRootOverride: repoRootOverride,
    startDirectory: startDirectory,
    environment: environment,
  );
  return ProbeApiConfig(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    modelId: config.modelId,
  );
}

Future<Map<String, Object?>> runDraftProbeCase({
  required GenerateDraftUseCase useCase,
  required ProjectDescriptor project,
  required String modelId,
  required String prompt,
  required ProbeResultValidator validator,
}) async {
  // 中文注释: 真实 probe 只消费 production 合同，不再在探针层补私有 retry/repair 逻辑。
  final phases = <String>[];
  try {
    final result = await useCase.execute(
      project: project,
      userPrompt: prompt,
      modelId: modelId,
      title: 'Mode Probe',
      requestOptions: const <String, Object?>{'stream': true},
      contextSettings: const <String, Object?>{},
      modelProfile: const <String, Object?>{},
      onProgress: (progress) {
        phases.add(progress.phase);
      },
    );
    final validation = await validator(result);
    final ok = ValueReaders.boolValue(validation['ok']);
    return <String, Object?>{
      ...validation,
      'ok': ok,
      'report_category': classifyDraftProbeReportCategory(
        ok: ok,
        result: result,
        validation: validation,
      ),
      'progress_phases': phases,
      'executed_tools': result.executedTools,
      'written_paths': result.writtenPaths,
      'changed_paths': result.changedPaths,
      'waiting_for_user_choice': result.waitingForUserChoice,
      'reasoning_content': result.reasoningContent,
      'tool_error_summary': result.toolErrorSummary,
      'draft_markdown': result.draftMarkdown,
    };
  } catch (error, stackTrace) {
    final summary = '$error';
    return <String, Object?>{
      'ok': false,
      'summary': summary,
      'stack_trace': '$stackTrace',
      'progress_phases': phases,
      'report_category': classifyDraftProbeReportCategory(
        ok: false,
        errorSummary: summary,
      ),
    };
  }
}

String classifyDraftProbeReportCategory({
  required bool ok,
  DraftGenerationResult? result,
  JsonMap validation = const <String, Object?>{},
  String errorSummary = '',
}) {
  final explicitCategory = ValueReaders.stringValue(
    validation['report_category'],
    ValueReaders.stringValue(validation['probe_failure_category']),
  ).trim();
  if (explicitCategory.isNotEmpty) {
    return explicitCategory;
  }
  if (ok) {
    return ProbeReportCategories.success;
  }
  final waitingForUser =
      ValueReaders.boolValue(validation['waiting_for_user_choice']) ||
      (result?.waitingForUserChoice ?? false);
  if (waitingForUser) {
    return ProbeReportCategories.waitingUser;
  }
  final summary = [
    errorSummary,
    ValueReaders.stringValue(validation['summary']),
    result?.toolErrorSummary ?? '',
  ].join(' ').toLowerCase();
  if (_isBudgetLikeFailureSummary(summary)) {
    return ProbeReportCategories.budgetFailure;
  }
  if (errorSummary.trim().isNotEmpty || (result?.stoppedByToolError ?? false)) {
    return ProbeReportCategories.technicalFailure;
  }
  return ProbeReportCategories.contentQualityFailure;
}

bool _isBudgetLikeFailureSummary(String summary) {
  return summary.contains('context length') ||
      summary.contains('maximum context') ||
      summary.contains('token limit') ||
      summary.contains('max tokens') ||
      summary.contains('budget') ||
      summary.contains('quota') ||
      summary.contains('rate limit') ||
      summary.contains('insufficient_quota') ||
      summary.contains('too many requests') ||
      summary.contains('余额') ||
      summary.contains('额度') ||
      summary.contains('上下文长度');
}
