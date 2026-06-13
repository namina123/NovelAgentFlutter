import 'information_collection_policy_service.dart';
import 'information_collection_request.dart';
import 'information_host_permission_context.dart';
import 'information_host_permission_resolver_service.dart';
import 'information_permission_decision.dart';
import 'information_permission_dispositions.dart';
import 'information_research_execution_decision.dart';

class InformationResearchExecutionDecisionService {
  const InformationResearchExecutionDecisionService({
    InformationCollectionPolicyService? collectionPolicyService,
    HostInformationPermissionResolverService? hostPermissionResolverService,
  }) : _collectionPolicyService =
           collectionPolicyService ?? const InformationCollectionPolicyService(),
       _hostPermissionResolverService =
           hostPermissionResolverService ??
           const HostInformationPermissionResolverService();

  final InformationCollectionPolicyService _collectionPolicyService;
  final HostInformationPermissionResolverService _hostPermissionResolverService;

  InformationResearchExecutionDecision decide({
    required InformationCollectionRequest request,
    required HostInformationPermissionContext hostPermissionContext,
    required InformationPermissionDecision permissionDecision,
  }) {
    // 中文注释: 这里统一把 request / host / permission 三方信号折成“自动执行、等待确认、完全阻断”三类稳定结果。
    final normalizedRequest = _collectionPolicyService.normalize(request);
    final hostResolution = _hostPermissionResolverService.resolve(
      request: normalizedRequest,
      hostContext: hostPermissionContext,
    );
    final effectiveRequest = hostResolution.effectiveRequest;
    final requestsImportCollection = hostResolution.requestsImportCollection;
    final requiresNetwork = hostResolution.requiresNetwork;
    final importAllowed = hostResolution.importCollectionAllowed;
    final networkAllowed = hostResolution.effectiveUserGrantedNetworkAccess;
    final canAwaitUserConfirmation = _canAwaitUserConfirmation(
      hostPermissionContext,
    );
    final permissionDisposition = permissionDecision.disposition.trim();

    var autoExecuteImport = requestsImportCollection && importAllowed;
    var autoExecuteNetwork = false;
    var awaitUserConfirmation = false;
    var blocked = false;
    final reasonParts = <String>[];

    if (permissionDisposition ==
        InformationPermissionDispositions.forbiddenAutoApply) {
      blocked = true;
      autoExecuteImport = false;
      reasonParts.add(
        permissionDecision.reason.trim().isEmpty
            ? '当前研究请求违反信息权限策略，不能进入执行。'
            : permissionDecision.reason.trim(),
      );
    } else {
      if (requestsImportCollection && !importAllowed) {
        if (canAwaitUserConfirmation) {
          awaitUserConfirmation = true;
          reasonParts.add('宿主当前未放行导入收集，需先得到用户确认。');
        } else if (!requiresNetwork) {
          blocked = true;
          reasonParts.add('宿主当前禁止导入收集，且不会进入用户确认流程。');
        } else {
          reasonParts.add('宿主当前禁止导入收集，本轮只可评估联网部分。');
        }
      }

      if (autoExecuteImport) {
        reasonParts.add('导入收集部分可以先执行。');
      }

      if (permissionDisposition ==
          InformationPermissionDispositions.needsUserConfirmation) {
        awaitUserConfirmation = true;
        reasonParts.add(
          permissionDecision.reason.trim().isEmpty
              ? '当前研究请求需要用户确认后才能继续。'
              : permissionDecision.reason.trim(),
        );
      } else if (permissionDisposition ==
          InformationPermissionDispositions.autoAccept) {
        if (requiresNetwork) {
          if (networkAllowed) {
            autoExecuteNetwork = true;
          } else if (canAwaitUserConfirmation) {
            awaitUserConfirmation = true;
            reasonParts.add('联网研究尚未得到宿主授权，需先等待用户确认。');
          } else if (!autoExecuteImport) {
            blocked = true;
            reasonParts.add('宿主当前禁止联网研究，且不会进入用户确认流程。');
          } else {
            reasonParts.add('联网研究当前被宿主阻止，本轮仅能继续导入收集部分。');
          }
        }
      } else {
        if (canAwaitUserConfirmation) {
          awaitUserConfirmation = true;
          reasonParts.add(
            permissionDecision.reason.trim().isEmpty
                ? '当前研究请求还没有得到明确放行。'
                : permissionDecision.reason.trim(),
          );
        } else if (!autoExecuteImport && !autoExecuteNetwork) {
          blocked = true;
          reasonParts.add(
            permissionDecision.reason.trim().isEmpty
                ? '当前研究请求没有可执行的下一步。'
                : permissionDecision.reason.trim(),
          );
        }
      }
    }

    if (!blocked &&
        !awaitUserConfirmation &&
        !autoExecuteImport &&
        !autoExecuteNetwork) {
      blocked = true;
      reasonParts.add('当前研究请求没有可执行的 network 或 import 动作。');
    }

    if (blocked) {
      awaitUserConfirmation = false;
    }

    return InformationResearchExecutionDecision(
      permissionDecision: permissionDecision,
      hostPermissionResolution: hostResolution,
      effectiveRequest: effectiveRequest,
      autoExecuteNetwork: autoExecuteNetwork,
      autoExecuteImport: autoExecuteImport,
      awaitUserConfirmation: awaitUserConfirmation,
      blocked: blocked,
      reason: _joinReasonParts(reasonParts),
      metadata: <String, Object?>{
        'collection_mode': effectiveRequest.collectionMode,
        'information_domain': effectiveRequest.informationDomain,
        'requires_network': requiresNetwork,
        'requests_import_collection': requestsImportCollection,
        'import_collection_allowed': importAllowed,
        'effective_user_granted_network_access': networkAllowed,
        'permission_disposition': permissionDisposition,
        'host_permission_mode': hostPermissionContext.permissionMode,
        'host_confirmation_mode': hostPermissionContext.confirmationMode,
      },
    );
  }

  bool _canAwaitUserConfirmation(
    HostInformationPermissionContext hostPermissionContext,
  ) {
    final normalized = hostPermissionContext.confirmationMode.trim();
    return normalized != HostInformationConfirmationModes.never;
  }

  String _joinReasonParts(List<String> parts) {
    final cleaned = <String>[];
    for (final part in parts) {
      final normalized = part.trim();
      if (normalized.isEmpty || cleaned.contains(normalized)) {
        continue;
      }
      cleaned.add(normalized);
    }
    return cleaned.join('；');
  }
}
