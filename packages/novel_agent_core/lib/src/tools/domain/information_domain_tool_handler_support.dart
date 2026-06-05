import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../information.dart';
import 'domain_tool_error.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_outcome_statuses.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_permission_dispositions.dart';
import 'domain_tool_request.dart';

class InformationDomainToolHandlerSupport {
  const InformationDomainToolHandlerSupport();

  DomainToolOutcome buildStructuredOutcome({
    required DomainToolRequest request,
    required String outcomeIdPrefix,
    required InformationPermissionDecision informationPermissionDecision,
    required JsonMap outcomePayload,
    DomainToolPermissionDecision? upstreamPermissionDecision,
    JsonMap metadata = const <String, Object?>{},
    String forbiddenErrorCode = 'forbidden_information_payload',
    String forbiddenMessage = '当前 payload 违反信息权限策略，不能进入信息层。',
  }) {
    // 中文注释: 信息 handler 统一把 information 权限姿态折叠成 domain outcome，避免每个 handler 重复拼装审计字段。
    if (informationPermissionDecision.disposition ==
        InformationPermissionDispositions.forbiddenAutoApply) {
      return buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: outcomeIdPrefix,
        errorCode: forbiddenErrorCode,
        message: forbiddenMessage,
        permissionDecision: toDomainPermissionDecision(
          informationPermissionDecision,
        ),
        errorDetails: <String, Object?>{
          'information_permission_decision': informationPermissionDecision
              .toJson(),
          if (upstreamPermissionDecision != null)
            'upstream_permission_decision': upstreamPermissionDecision.toJson(),
        },
        metadata: metadata,
      );
    }

    return DomainToolOutcome(
      outcomeId: _outcomeIdFor(request, outcomeIdPrefix),
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: _outcomeStatusFor(
        informationPermissionDecision.disposition,
      ),
      permissionDecision: toDomainPermissionDecision(
        informationPermissionDecision,
      ),
      outcomePayload: ValueReaders.deepCopyMap(outcomePayload),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...metadata,
        'information_permission_decision': informationPermissionDecision
            .toJson(),
        if (upstreamPermissionDecision != null)
          'upstream_permission_decision': upstreamPermissionDecision.toJson(),
      }),
    );
  }

  DomainToolOutcome buildInvalidPayloadOutcome({
    required DomainToolRequest request,
    required String outcomeIdPrefix,
    required String errorCode,
    required String message,
    DomainToolPermissionDecision? permissionDecision,
    JsonMap errorDetails = const <String, Object?>{},
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: invalid payload 统一走结构化错误回执，方便后续 mock 回归和 runtime 审计只消费稳定合同。
    return DomainToolOutcome(
      outcomeId: '${_outcomeIdFor(request, outcomeIdPrefix)}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision:
          permissionDecision ??
          const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
      error: DomainToolError(
        errorCode: errorCode,
        message: message,
        errorDetails: ValueReaders.deepCopyMap(errorDetails),
      ),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  DomainToolPermissionDecision toDomainPermissionDecision(
    InformationPermissionDecision decision,
  ) {
    // 中文注释: 当前 dispatcher 还没接入 information policy，所以这里先把 information 决策桥成可审计的 domain permission 合同。
    return DomainToolPermissionDecision(
      disposition: _permissionDispositionFor(decision.disposition),
      reason: decision.reason,
      policyRef: decision.policyRef,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...decision.metadata,
        'information_disposition': decision.disposition,
      }),
    );
  }

  String _permissionDispositionFor(String informationDisposition) {
    // 中文注释: information 层的 auto_accept / forbidden_auto_apply 需要映射回 domain 工具层已有的四态集合。
    switch (informationDisposition) {
      case InformationPermissionDispositions.autoAccept:
        return DomainToolPermissionDispositions.accepted;
      case InformationPermissionDispositions.proposed:
        return DomainToolPermissionDispositions.proposed;
      case InformationPermissionDispositions.needsUserConfirmation:
        return DomainToolPermissionDispositions.needsUserConfirmation;
      case InformationPermissionDispositions.forbiddenAutoApply:
        return DomainToolPermissionDispositions.rejected;
    }
    return DomainToolPermissionDispositions.proposed;
  }

  String _outcomeStatusFor(String informationDisposition) {
    // 中文注释: PIS-12 只允许 information handlers 落在 accepted / proposed / needs_user_confirmation 三类成功态。
    switch (informationDisposition) {
      case InformationPermissionDispositions.autoAccept:
        return DomainToolOutcomeStatuses.accepted;
      case InformationPermissionDispositions.proposed:
        return DomainToolOutcomeStatuses.proposed;
      case InformationPermissionDispositions.needsUserConfirmation:
        return DomainToolOutcomeStatuses.needsUserConfirmation;
      case InformationPermissionDispositions.forbiddenAutoApply:
        return DomainToolOutcomeStatuses.invalidPayload;
    }
    return DomainToolOutcomeStatuses.proposed;
  }

  String _outcomeIdFor(DomainToolRequest request, String outcomeIdPrefix) {
    // 中文注释: 统一 outcome id 规则，避免不同信息 handler 各自长出不兼容的命名格式。
    return '$outcomeIdPrefix:${request.callId}';
  }
}
