import '../common/host_platform.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../settings/app_settings.dart';
import '../settings/model_execution_profile_service.dart';
import '../settings/provider_endpoint_settings.dart';
import '../project/project_descriptor.dart';
import '../tools/tool_exposure_policy_service.dart';
import '../workflow/continuous_task_tool_exposure_runtime_resolver_service.dart';
import 'child_run_package.dart';
import 'project_agent_binding.dart';
import 'project_agent_binding_normalizer_service.dart';
import 'project_agent_binding_resolver_service.dart';

class SubAgentEffectiveExecutionProfileService {
  SubAgentEffectiveExecutionProfileService({
    ModelExecutionProfileService? modelExecutionProfileService,
    ToolExposurePolicyService? toolExposurePolicyService,
    ContinuousTaskToolExposureRuntimeResolverService?
    continuousTaskToolExposureRuntimeResolverService,
    ProjectAgentBindingResolverService? projectAgentBindingResolverService,
    ProjectAgentBindingNormalizerService? projectAgentBindingNormalizerService,
  }) : _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _toolExposurePolicyService =
           toolExposurePolicyService ?? const ToolExposurePolicyService(),
       _continuousTaskToolExposureRuntimeResolverService =
           continuousTaskToolExposureRuntimeResolverService ??
           const ContinuousTaskToolExposureRuntimeResolverService(),
       _projectAgentBindingResolverService =
           projectAgentBindingResolverService ??
           const ProjectAgentBindingResolverService(),
       _projectAgentBindingNormalizerService =
           projectAgentBindingNormalizerService ??
           ProjectAgentBindingNormalizerService();

  final ModelExecutionProfileService _modelExecutionProfileService;
  final ToolExposurePolicyService _toolExposurePolicyService;
  final ContinuousTaskToolExposureRuntimeResolverService
  _continuousTaskToolExposureRuntimeResolverService;
  final ProjectAgentBindingResolverService _projectAgentBindingResolverService;
  final ProjectAgentBindingNormalizerService
  _projectAgentBindingNormalizerService;

  JsonMap resolve({
    required JsonMap package,
    required JsonMap childAgent,
    required JsonMap mainContext,
    required ProjectDescriptor project,
    required HostPlatform hostPlatform,
    required String parentModelId,
  }) {
    // 中文注释: 这里把 child package、运行时设置和项目范围绑定统一收束成“本次 child 真正会怎么跑”的稳定视图。
    final childRunPackage = ChildRunPackage.fromJson(
      ValueReaders.mapValue(package['child_run_package']),
    );
    final settings = _runtimeSettings(mainContext);
    final projectBinding = _resolveProjectBinding(
      mainContext,
      childRunPackage.agentId,
    );
    final resolvedModel = _resolveModelProfile(
      settings: settings,
      childRunPackage: childRunPackage,
      childAgent: childAgent,
      projectBinding: projectBinding,
      parentModelId: parentModelId,
    );
    final blockedToolIds = _mergedBlockedToolIds(childRunPackage, childAgent);
    final requestedToolIds = _requestedToolIds(childRunPackage, childAgent);
    final toolExposureResolution =
        _continuousTaskToolExposureRuntimeResolverService.resolve(
          candidateToolIds: requestedToolIds,
          selectedCollaborationGroup: ValueReaders.mapValue(
            mainContext['selected_collaboration_group'],
          ),
          runtimeContext: <String, Object?>{
            'task_family_id': ValueReaders.stringValue(
              mainContext['continuous_task_family_id'],
            ),
            'mode': ValueReaders.stringValue(
              mainContext['sub_agent_binding_mode_id'],
            ),
            'task_type': ValueReaders.stringValue(mainContext['task_type']),
          },
          intent: ValueReaders.stringValue(mainContext['intent']),
          explicitTaskFamilyId: ValueReaders.stringValue(
            mainContext['continuous_task_family_id'],
          ),
          explicitRunKind: ValueReaders.stringValue(
            mainContext['continuous_task_run_kind'],
          ),
        );
    final allowedToolIds = _toolExposurePolicyService.filterExposedToolIds(
      toolExposureResolution.visibleToolIds
          .where((toolId) => !blockedToolIds.contains(toolId))
          .toList(growable: false),
      hostPlatform: hostPlatform,
      projectType: project.projectType,
      isSubAgent: true,
    );
    final runtimeProfile = ValueReaders.mapValue(
      resolvedModel['runtime_profile'],
    );
    return <String, Object?>{
      'model_id': ValueReaders.stringValue(
        runtimeProfile['model'],
        ValueReaders.stringValue(resolvedModel['resolved_model_id']),
      ),
      'provider_id': ValueReaders.stringValue(resolvedModel['provider_id']),
      'runtime_profile': runtimeProfile,
      'request_options': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(resolvedModel['request_options']),
      ),
      'allowed_tool_ids': allowedToolIds,
      'blocked_tool_ids': blockedToolIds.toList(growable: false),
      'continuous_task_tool_exposure_resolution': toolExposureResolution
          .toJson(),
      'context_budget_chars': childRunPackage.budgetPolicy.contextBudgetChars,
      'output_budget_chars': childRunPackage.budgetPolicy.outputBudgetChars,
      'token_budget': childRunPackage.budgetPolicy.tokenBudget,
      'max_retry_count': childRunPackage.budgetPolicy.maxRetryCount,
      'max_tool_rounds': childRunPackage.budgetPolicy.maxToolRounds,
      'max_concurrent_children':
          childRunPackage.budgetPolicy.maxConcurrentChildren,
      'timeout_seconds': childRunPackage.budgetPolicy.timeoutSeconds,
      if (projectBinding != null)
        'project_agent_binding': _projectAgentBindingNormalizerService
            .toDocument(projectBinding),
    };
  }

  JsonMap _resolveModelProfile({
    required AppSettings? settings,
    required ChildRunPackage childRunPackage,
    required JsonMap childAgent,
    required ProjectAgentBinding? projectBinding,
    required String parentModelId,
  }) {
    final fallbackModelId = _preferredModelId(childRunPackage, childAgent);
    if (settings == null) {
      return <String, Object?>{
        'provider_id': '',
        'resolved_model_id': fallbackModelId.isEmpty
            ? parentModelId
            : fallbackModelId,
        'runtime_profile': <String, Object?>{
          'model': fallbackModelId.isEmpty ? parentModelId : fallbackModelId,
          'thinking_enabled': childRunPackage.modelPolicy.thinkingEnabled,
          'thinking_effort': childRunPackage.modelPolicy.thinkingEffort,
          if (childRunPackage.modelPolicy.temperature != null)
            'temperature': childRunPackage.modelPolicy.temperature,
          if (childRunPackage.modelPolicy.topP != null)
            'top_p': childRunPackage.modelPolicy.topP,
          if (childRunPackage.modelPolicy.topK != null)
            'top_k': childRunPackage.modelPolicy.topK,
          'supports_file_attachments': false,
          'supports_image_attachments': false,
          'supports_attachment_urls_only': false,
          'supports_multi_attachments': false,
        },
        'request_options': <String, Object?>{
          if (childRunPackage.modelPolicy.temperature != null)
            'temperature': childRunPackage.modelPolicy.temperature,
          if (childRunPackage.modelPolicy.topP != null)
            'top_p': childRunPackage.modelPolicy.topP,
          if (childRunPackage.modelPolicy.topK != null)
            'top_k': childRunPackage.modelPolicy.topK,
        },
      };
    }
    final provider = _providerForProfile(
      settings,
      childRunPackage.modelPolicy.providerProfile,
    );
    return _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      overrideModelId: fallbackModelId,
      agent: childAgent,
      projectAgentBinding: projectBinding,
    );
  }

  String _preferredModelId(
    ChildRunPackage childRunPackage,
    JsonMap childAgent,
  ) {
    final agentModelId = ValueReaders.stringValue(
      childAgent['model_id'],
      ValueReaders.stringValue(childAgent['model']),
    ).trim();
    if (agentModelId.isNotEmpty) {
      return agentModelId;
    }
    return childRunPackage.modelPolicy.requestedModelId.trim();
  }

  ProviderEndpointSettings? _providerForProfile(
    AppSettings settings,
    String providerProfile,
  ) {
    final profileId = providerProfile.trim();
    if (profileId.isEmpty || profileId == 'default') {
      return null;
    }
    for (final provider in settings.providers) {
      if (provider.id == profileId) {
        return provider;
      }
    }
    return null;
  }

  List<String> _requestedToolIds(
    ChildRunPackage childRunPackage,
    JsonMap childAgent,
  ) {
    final allowedToolIds = _declaredAllowedToolIds(childRunPackage, childAgent);
    if (allowedToolIds.isEmpty) {
      return const <String>[];
    }
    return allowedToolIds.toSet().toList(growable: false);
  }

  Set<String> _mergedBlockedToolIds(
    ChildRunPackage childRunPackage,
    JsonMap childAgent,
  ) {
    final blocked = <String>{
      ...childRunPackage.permissionPolicy.blockedToolIds,
      ..._toolPolicyBlockedToolIds(childAgent),
    };
    if (!childRunPackage.permissionPolicy.allowRecursiveDelegation) {
      blocked.add('call_sub_agent');
    }
    if (!childRunPackage.permissionPolicy.allowUserQuestions) {
      blocked.add('present_user_options');
    }
    if (!childRunPackage.permissionPolicy.allowFormalDelivery) {
      blocked.add('submit_chapter_delivery');
    }
    if (!childRunPackage.permissionPolicy.allowLongTaskControl) {
      blocked.add('start_long_task_run');
    }
    return blocked;
  }

  List<String> _declaredAllowedToolIds(
    ChildRunPackage childRunPackage,
    JsonMap childAgent,
  ) {
    final fromContract = childRunPackage.permissionPolicy.allowedToolIds;
    if (fromContract.isNotEmpty) {
      return fromContract;
    }
    return _toolPolicyAllowedToolIds(childAgent);
  }

  List<String> _toolPolicyAllowedToolIds(JsonMap childAgent) {
    return ValueReaders.stringList(_toolPolicyOf(childAgent)['allowed_tools']);
  }

  List<String> _toolPolicyBlockedToolIds(JsonMap childAgent) {
    return ValueReaders.stringList(_toolPolicyOf(childAgent)['blocked_tools']);
  }

  JsonMap _toolPolicyOf(JsonMap childAgent) {
    final direct = ValueReaders.mapValue(childAgent['tool_policy']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final extensions = ValueReaders.mapValue(
      childAgent['novel_agent_extensions'],
    );
    final extensionPolicy = ValueReaders.mapValue(extensions['tool_policy']);
    if (extensionPolicy.isNotEmpty) {
      return extensionPolicy;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(childAgent['metadata'])['tool_policy'],
    );
  }

  AppSettings? _runtimeSettings(JsonMap mainContext) {
    final value = mainContext['sub_agent_runtime_settings'];
    return value is AppSettings ? value : null;
  }

  ProjectAgentBinding? _resolveProjectBinding(
    JsonMap mainContext,
    String agentId,
  ) {
    final bindings = _projectBindings(mainContext);
    if (bindings.isEmpty || agentId.trim().isEmpty) {
      return null;
    }
    final scoped = bindings
        .where((binding) => binding.agentId == agentId)
        .toList(growable: false);
    if (scoped.isEmpty) {
      return null;
    }
    return _projectAgentBindingResolverService.resolvePreferredBinding(
      scoped,
      modeId: ValueReaders.stringValue(
        mainContext['sub_agent_binding_mode_id'],
      ),
      stageId: ValueReaders.stringValue(
        mainContext['sub_agent_binding_stage_id'],
      ),
    );
  }

  List<ProjectAgentBinding> _projectBindings(JsonMap mainContext) {
    final rawValue = mainContext['sub_agent_bindings'];
    if (rawValue is List<ProjectAgentBinding>) {
      return List<ProjectAgentBinding>.unmodifiable(rawValue);
    }
    final result = <ProjectAgentBinding>[];
    for (final rawBinding in ValueReaders.objectList(rawValue)) {
      final binding = _projectAgentBindingNormalizerService.normalize(
        ValueReaders.mapValue(rawBinding),
      );
      if (binding.agentId.trim().isNotEmpty) {
        result.add(binding);
      }
    }
    return result;
  }
}
