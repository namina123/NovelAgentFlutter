import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'host_tool_permission_context.dart';
import 'host_tool_permission_decision.dart';
import 'host_tool_permission_dispositions.dart';

class HostToolPermissionPolicyService {
  const HostToolPermissionPolicyService();

  static const String capabilityRead = 'read';
  static const String capabilityWrite = 'write';
  static const String capabilityDelete = 'delete';
  static const String capabilityNetwork = 'network';
  static const String capabilityProcess = 'process';
  static const String capabilitySubAgents = 'sub_agents';
  static const String capabilityLongTaskControl = 'long_task_control';
  static const String capabilityFormalDelivery = 'formal_delivery';

  HostToolPermissionDecision decide({
    required String toolName,
    JsonMap arguments = const <String, Object?>{},
    HostToolPermissionContext? hostPermissionContext,
  }) {
    final cleanToolName = toolName.trim();
    final capability = _requiredCapability(cleanToolName, arguments);
    if (capability.isEmpty) {
      return const HostToolPermissionDecision(
        disposition: HostToolPermissionDispositions.accepted,
        reason: '该工具不受额外宿主权限门控。',
        policyRef: 'policy.host_tool_permission_not_gated',
      );
    }
    if (hostPermissionContext == null) {
      return HostToolPermissionDecision(
        disposition: HostToolPermissionDispositions.accepted,
        reason: '当前宿主未提供工具权限上下文，回退到兼容放行。',
        policyRef: 'policy.host_tool_permission_context_missing_fallback_allow',
        requiredCapability: capability,
        metadata: <String, Object?>{
          'tool_name': cleanToolName,
          'required_capability': capability,
        },
      );
    }
    if (_isAllowed(capability, hostPermissionContext)) {
      return HostToolPermissionDecision(
        disposition: HostToolPermissionDispositions.accepted,
        reason: '宿主已允许该能力。',
        policyRef: 'policy.host_tool_permission_allowed',
        requiredCapability: capability,
        metadata: <String, Object?>{
          'tool_name': cleanToolName,
          'required_capability': capability,
          'host_permission_context': hostPermissionContext.toJson(),
        },
      );
    }
    if (_needsUserConfirmation(hostPermissionContext.confirmationMode)) {
      return HostToolPermissionDecision(
        disposition: HostToolPermissionDispositions.needsUserConfirmation,
        reason: _waitingReason(cleanToolName, capability),
        policyRef: 'policy.host_tool_permission_waiting_user_confirmation',
        requiredCapability: capability,
        metadata: <String, Object?>{
          'tool_name': cleanToolName,
          'required_capability': capability,
          'host_permission_context': hostPermissionContext.toJson(),
        },
      );
    }
    return HostToolPermissionDecision(
      disposition: HostToolPermissionDispositions.blocked,
      reason: _blockedReason(cleanToolName, capability),
      policyRef: 'policy.host_tool_permission_blocked',
      requiredCapability: capability,
      metadata: <String, Object?>{
        'tool_name': cleanToolName,
        'required_capability': capability,
        'host_permission_context': hostPermissionContext.toJson(),
      },
    );
  }

  String _requiredCapability(String toolName, JsonMap arguments) {
    switch (toolName) {
      case 'list_project_files':
      case 'read_project_file':
      case 'get_project_file_info':
      case 'search_project_files':
      case 'list_history_sessions':
      case 'load_agent_skill':
        return capabilityRead;
      case 'write_project_file':
      case 'edit_project_file':
      case 'create_project_entry':
      case 'move_project_file':
      case 'rename_project_file':
      case 'rename_project':
      case 'reorder_project_file':
      case 'manipulate_project_file_lines':
      case 'create_backup':
      case 'restore_backup':
      case 'update_world_state':
      case 'update_character_state':
      case 'update_foreshadow_state':
      case 'update_timeline_state':
      case 'update_relationship_state':
      case 'summarize_context':
      case 'run_continuity_check':
      case 'set_agent_tasks':
        return capabilityWrite;
      case 'create_chapter_task':
      case 'mark_task_status':
        return capabilityLongTaskControl;
      case 'delete_project_file':
        return capabilityDelete;
      case 'request_gateway_tool':
        return _gatewayCapability(arguments);
      case 'start_long_task_run':
        return capabilityLongTaskControl;
      case 'call_sub_agent':
        return capabilitySubAgents;
      case 'submit_chapter_delivery':
        return capabilityFormalDelivery;
      default:
        return '';
    }
  }

  String _gatewayCapability(JsonMap arguments) {
    final gatewayTool = ValueReaders.stringValue(
      arguments['gateway_tool'],
      ValueReaders.stringValue(
        arguments['tool'],
        ValueReaders.stringValue(arguments['name']),
      ),
    ).trim();
    switch (gatewayTool) {
      case 'search_internet':
      case 'fetch_url_content':
      case 'generate_image':
        return capabilityNetwork;
      case 'run_command':
        return capabilityProcess;
      default:
        return capabilityProcess;
    }
  }

  bool _isAllowed(String capability, HostToolPermissionContext context) {
    switch (capability) {
      case capabilityRead:
        return context.allowRead;
      case capabilityWrite:
        return context.allowWrite;
      case capabilityDelete:
        return context.allowDelete;
      case capabilityNetwork:
        return context.allowNetwork;
      case capabilityProcess:
        return context.allowProcess;
      case capabilitySubAgents:
        return context.allowSubAgents;
      case capabilityLongTaskControl:
        return context.allowLongTaskControl;
      case capabilityFormalDelivery:
        return context.allowFormalDelivery;
      default:
        return true;
    }
  }

  bool _needsUserConfirmation(String confirmationMode) {
    return confirmationMode.trim().toLowerCase() ==
        HostToolConfirmationModes.userConfirmationRequired;
  }

  String _waitingReason(String toolName, String capability) {
    return '工具 $toolName 需要宿主权限确认后才能继续：$capability。';
  }

  String _blockedReason(String toolName, String capability) {
    return '工具 $toolName 当前被宿主权限策略阻止：$capability。';
  }
}
