import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/runtime_baseline_catalog_service.dart';
import '../runtime/runtime_baseline_execution_mode_service.dart';
import 'project_runtime_profile.dart';

class ProjectRuntimeProfileDocumentService {
  ProjectRuntimeProfileDocumentService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    RuntimeBaselineExecutionModeService? runtimeBaselineExecutionModeService,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runtimeBaselineExecutionModeService =
           runtimeBaselineExecutionModeService ??
           RuntimeBaselineExecutionModeService();

  static const String profileRelativePath =
      '.novel_agent/settings/runtime_profile.json';

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final RuntimeBaselineExecutionModeService
  _runtimeBaselineExecutionModeService;

  ProjectRuntimeProfile buildProfile({
    required String projectType,
    required String runtimeBaselineId,
  }) {
    // 中文注释: 这里把项目级默认运行配置快照统一固化，后续 GUI/CLI 启动长任务都从同一合同起步。
    final cleanProjectType = projectType.trim();
    final cleanBaselineId = runtimeBaselineId.trim();
    final baseline = _runtimeBaselineCatalogService.byId(cleanBaselineId);
    final runtimeMode = _runtimeBaselineExecutionModeService.resolveRuntimeMode(
      runtimeBaselineId: cleanBaselineId,
    );
    return ProjectRuntimeProfile(
      projectType: cleanProjectType,
      runtimeBaselineId: cleanBaselineId,
      runtimeMode: runtimeMode,
      initialRunOptions: <String, Object?>{
        'runtime_baseline_id': cleanBaselineId,
        'runtime_mode': runtimeMode,
        'auto_start_on_create': false,
        'unattended': baseline?.unattended ?? false,
        'auto_advance_chapters': baseline?.autoAdvanceChapters ?? false,
        'keep_alive_across_project_switch':
            baseline?.keepAliveAcrossProjectSwitch ?? false,
      },
    );
  }

  ProjectRuntimeProfile parse(
    String content, {
    String fallbackProjectType = '',
    String fallbackRuntimeBaselineId = '',
  }) {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      return buildProfile(
        projectType: fallbackProjectType,
        runtimeBaselineId: fallbackRuntimeBaselineId,
      );
    }
    try {
      final parsed = jsonDecode(cleanContent);
      if (parsed is! Map<Object?, Object?>) {
        return buildProfile(
          projectType: fallbackProjectType,
          runtimeBaselineId: fallbackRuntimeBaselineId,
        );
      }
      return fromJson(
        Map<String, Object?>.from(parsed),
        fallbackProjectType: fallbackProjectType,
        fallbackRuntimeBaselineId: fallbackRuntimeBaselineId,
      );
    } catch (_) {
      return buildProfile(
        projectType: fallbackProjectType,
        runtimeBaselineId: fallbackRuntimeBaselineId,
      );
    }
  }

  ProjectRuntimeProfile fromJson(
    JsonMap json, {
    String fallbackProjectType = '',
    String fallbackRuntimeBaselineId = '',
  }) {
    final projectType = ValueReaders.stringValue(
      json['project_type'],
      fallbackProjectType,
    ).trim();
    final runtimeBaselineId = ValueReaders.stringValue(
      json['runtime_baseline_id'],
      fallbackRuntimeBaselineId,
    ).trim();
    final runtimeMode = _runtimeBaselineExecutionModeService.resolveRuntimeMode(
      runtimeBaselineId: runtimeBaselineId,
      runtimeMode: ValueReaders.stringValue(json['runtime_mode']),
    );
    final initialRunOptions = ValueReaders.mapValue(
      json['initial_run_options'],
    );
    return ProjectRuntimeProfile(
      projectType: projectType,
      runtimeBaselineId: runtimeBaselineId,
      runtimeMode: runtimeMode,
      initialRunOptions: initialRunOptions.isEmpty
          ? buildProfile(
              projectType: projectType,
              runtimeBaselineId: runtimeBaselineId,
            ).initialRunOptions
          : initialRunOptions,
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
    );
  }

  JsonMap toJson(ProjectRuntimeProfile profile) {
    return <String, Object?>{
      'schema_version': profile.schemaVersion,
      'project_type': profile.projectType,
      'runtime_baseline_id': profile.runtimeBaselineId,
      'runtime_mode': profile.runtimeMode,
      'initial_run_options': ValueReaders.deepCopyMap(
        profile.initialRunOptions,
      ),
    };
  }

  String encode(ProjectRuntimeProfile profile) {
    return const JsonEncoder.withIndent('  ').convert(toJson(profile));
  }
}
