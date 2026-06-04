import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'domain_tool_error.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_outcome_statuses.dart';
import 'domain_tool_permission_dispositions.dart';
import 'domain_tool_request.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_dispatcher.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_permission_policy_service.dart';

class NarrativeDomainToolDispatchService
    implements NarrativeDomainToolDispatcher {
  NarrativeDomainToolDispatchService({
    required Iterable<NarrativeDomainToolHandler> handlers,
    NarrativePermissionPolicyService? permissionPolicyService,
  }) : _capabilities = handlers
           .map((handler) => handler.capability)
           .toList(growable: false),
       _handlersByToolName = <String, NarrativeDomainToolHandler>{
         for (final handler in handlers) handler.capability.toolName: handler,
       },
       _permissionPolicyService =
           permissionPolicyService ?? const NarrativePermissionPolicyService();

  final List<NarrativeDomainToolCapability> _capabilities;
  final Map<String, NarrativeDomainToolHandler> _handlersByToolName;
  final NarrativePermissionPolicyService _permissionPolicyService;

  @override
  List<NarrativeDomainToolCapability> get capabilities => _capabilities;

  @override
  NarrativeDomainToolCapability? capabilityFor(String toolName) {
    return _handlersByToolName[toolName.trim()]?.capability;
  }

  @override
  bool canDispatch(String toolName) {
    return _handlersByToolName.containsKey(toolName.trim());
  }

  @override
  Future<DomainToolOutcome> dispatch({
    required DomainToolRequest request,
  }) async {
    final validationErrors = request.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        errorCode: 'invalid_domain_tool_request',
        message: '领域工具请求缺少必填字段。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
      );
    }

    final handler = _handlersByToolName[request.toolName];
    if (handler == null) {
      return _executionFailedOutcome(
        request: request,
        errorCode: 'unsupported_domain_tool',
        message: '当前 dispatcher 未注册该领域工具 handler。',
      );
    }

    if (!handler.capability.supportsSource(request.source)) {
      return _invalidPayloadOutcome(
        request: request,
        errorCode: 'unsupported_source_type',
        message: '当前领域工具 handler 不支持该 source_type。',
        errorDetails: <String, Object?>{
          'source_type': request.source.sourceType,
          'supported_sources': handler.capability.supportedSourceTypes,
        },
      );
    }

    final permissionDecision = _permissionPolicyService.decide(request);
    if (permissionDecision.disposition ==
            DomainToolPermissionDispositions.needsUserConfirmation ||
        permissionDecision.disposition ==
            DomainToolPermissionDispositions.rejected) {
      return _permissionPolicyService.buildPermissionOutcome(
        outcomeId: _outcomeIdFor(request, 'permission'),
        request: request,
        outcomePayload: <String, Object?>{
          'capability': handler.capability.toJson(),
        },
      );
    }

    final handledOutcome = await handler.handle(
      request: request,
      permissionDecision: permissionDecision,
    );
    return handledOutcome.copyWith(
      callId: _safeCallId(request),
      toolName: _safeToolName(request),
      outcomeStatus: _normalizeOutcomeStatus(
        handledOutcome.outcomeStatus,
        permissionDecision.disposition,
      ),
      permissionDecision:
          handledOutcome.permissionDecision ?? permissionDecision,
      toolRoundEvidence:
          handledOutcome.toolRoundEvidence ?? request.toolRoundEvidence,
      schemaVersion: handledOutcome.schemaVersion.isEmpty
          ? request.schemaVersion
          : handledOutcome.schemaVersion,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...handledOutcome.metadata,
        'capability': handler.capability.toJson(),
      }),
    );
  }

  DomainToolOutcome _invalidPayloadOutcome({
    required DomainToolRequest request,
    required String errorCode,
    required String message,
    JsonMap errorDetails = const <String, Object?>{},
  }) {
    return DomainToolOutcome(
      outcomeId: _outcomeIdFor(request, 'invalid_payload'),
      callId: _safeCallId(request),
      toolName: _safeToolName(request),
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      error: DomainToolError(
        errorCode: errorCode,
        message: message,
        errorDetails: ValueReaders.deepCopyMap(errorDetails),
      ),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
    );
  }

  DomainToolOutcome _executionFailedOutcome({
    required DomainToolRequest request,
    required String errorCode,
    required String message,
  }) {
    return DomainToolOutcome(
      outcomeId: _outcomeIdFor(request, 'execution_failed'),
      callId: _safeCallId(request),
      toolName: _safeToolName(request),
      outcomeStatus: DomainToolOutcomeStatuses.executionFailed,
      error: DomainToolError(errorCode: errorCode, message: message),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
    );
  }

  String _normalizeOutcomeStatus(
    String outcomeStatus,
    String permissionDisposition,
  ) {
    if (permissionDisposition == DomainToolPermissionDispositions.proposed &&
        outcomeStatus == DomainToolOutcomeStatuses.accepted) {
      return DomainToolOutcomeStatuses.proposed;
    }
    return outcomeStatus;
  }

  String _outcomeIdFor(DomainToolRequest request, String suffix) {
    return '${_safeToolName(request)}:${_safeCallId(request)}:$suffix';
  }

  String _safeCallId(DomainToolRequest request) {
    final normalized = request.callId.trim();
    return normalized.isEmpty ? 'invalid_call_id' : normalized;
  }

  String _safeToolName(DomainToolRequest request) {
    final normalized = request.toolName.trim();
    return normalized.isEmpty ? 'unknown_domain_tool' : normalized;
  }
}
