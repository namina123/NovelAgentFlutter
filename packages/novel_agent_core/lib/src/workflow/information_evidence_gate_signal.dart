import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class InformationEvidenceGateSeverities {
  static const String none = 'none';
  static const String info = 'info';
  static const String warning = 'warning';
  static const String blocking = 'blocking';

  static const List<String> knownValues = <String>[
    none,
    info,
    warning,
    blocking,
  ];
}

abstract final class InformationEvidenceRecommendedDispositions {
  static const String accept = 'accept';
  static const String checkpointUser = 'checkpoint_user';
  static const String repair = 'repair';
  static const String manualAttention = 'manual_attention';

  static const List<String> knownValues = <String>[
    accept,
    checkpointUser,
    repair,
    manualAttention,
  ];
}

class InformationEvidenceGateSignal {
  const InformationEvidenceGateSignal({
    this.present = false,
    this.severity = InformationEvidenceGateSeverities.none,
    this.recommendedDisposition =
        InformationEvidenceRecommendedDispositions.accept,
    this.reason = '',
    this.summary = '',
    this.changedPaths = const <String>[],
    this.pendingResearchCount = 0,
    this.awaitingConfirmationCount = 0,
    this.gatewayFailureCount = 0,
    this.rigorousSourceInsufficientCount = 0,
    this.requiredInformationOmittedCount = 0,
    this.externalFactUnverifiedCount = 0,
    this.waitingUser = false,
    this.requiresRepair = false,
    this.manualAttentionRequired = false,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String severity;
  final String recommendedDisposition;
  final String reason;
  final String summary;
  final List<String> changedPaths;
  final int pendingResearchCount;
  final int awaitingConfirmationCount;
  final int gatewayFailureCount;
  final int rigorousSourceInsufficientCount;
  final int requiredInformationOmittedCount;
  final int externalFactUnverifiedCount;
  final bool waitingUser;
  final bool requiresRepair;
  final bool manualAttentionRequired;
  final JsonMap metadata;

  bool get contentEvidenceGap =>
      rigorousSourceInsufficientCount > 0 ||
      requiredInformationOmittedCount > 0 ||
      externalFactUnverifiedCount > 0;

  bool get pendingResearchOnly =>
      pendingResearchCount > 0 &&
      awaitingConfirmationCount == 0 &&
      gatewayFailureCount == 0 &&
      !contentEvidenceGap &&
      !waitingUser &&
      !requiresRepair &&
      !manualAttentionRequired;

  factory InformationEvidenceGateSignal.fromJson(JsonMap json) {
    final pendingResearchCount = ValueReaders.intValue(
      json['pending_research_count'],
    );
    final awaitingConfirmationCount = ValueReaders.intValue(
      json['awaiting_confirmation_count'],
    );
    final gatewayFailureCount = ValueReaders.intValue(
      json['gateway_failure_count'],
    );
    final rigorousSourceInsufficientCount = ValueReaders.intValue(
      json['rigorous_source_insufficient_count'],
    );
    final requiredInformationOmittedCount = ValueReaders.intValue(
      json['required_information_omitted_count'],
      ValueReaders.intValue(json['required_omitted_count']),
    );
    final externalFactUnverifiedCount = ValueReaders.intValue(
      json['external_fact_unverified_count'],
    );
    final waitingUser = ValueReaders.boolValue(json['waiting_user']);
    final requiresRepair = ValueReaders.boolValue(json['requires_repair']);
    final manualAttentionRequired = ValueReaders.boolValue(
      json['manual_attention_required'],
    );
    final recommendedDisposition = _normalizeDisposition(
      ValueReaders.stringValue(
        json['recommended_disposition'],
        ValueReaders.stringValue(json['category']),
      ).trim(),
      awaitingConfirmationCount: awaitingConfirmationCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      waitingUser: waitingUser,
      requiresRepair: requiresRepair,
      manualAttentionRequired: manualAttentionRequired,
    );
    final severity = _normalizeSeverity(
      ValueReaders.stringValue(json['severity']).trim(),
      recommendedDisposition: recommendedDisposition,
      pendingResearchCount: pendingResearchCount,
      awaitingConfirmationCount: awaitingConfirmationCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      changedPathCount: ValueReaders.stringList(json['changed_paths']).length,
    );
    final warningOnlySourceQualityGap = _warningOnlySourceQualityGap(
      awaitingConfirmationCount: awaitingConfirmationCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      waitingUser: waitingUser,
      manualAttentionRequired: manualAttentionRequired,
    );
    return InformationEvidenceGateSignal(
      present:
          ValueReaders.boolValue(json['present']) ||
          pendingResearchCount > 0 ||
          awaitingConfirmationCount > 0 ||
          gatewayFailureCount > 0 ||
          rigorousSourceInsufficientCount > 0 ||
          requiredInformationOmittedCount > 0 ||
          externalFactUnverifiedCount > 0 ||
          ValueReaders.stringList(json['changed_paths']).isNotEmpty ||
          ValueReaders.stringValue(json['summary']).trim().isNotEmpty,
      severity: severity,
      recommendedDisposition: recommendedDisposition,
      reason: ValueReaders.stringValue(json['reason']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      changedPaths: List<String>.unmodifiable(
        ValueReaders.stringList(json['changed_paths']),
      ),
      pendingResearchCount: pendingResearchCount,
      awaitingConfirmationCount: awaitingConfirmationCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      waitingUser:
          waitingUser ||
          recommendedDisposition ==
              InformationEvidenceRecommendedDispositions.checkpointUser,
      requiresRepair:
          !warningOnlySourceQualityGap &&
          (recommendedDisposition ==
                  InformationEvidenceRecommendedDispositions.repair ||
              requiresRepair ||
              gatewayFailureCount > 0 ||
              requiredInformationOmittedCount > 0 ||
              externalFactUnverifiedCount > 0),
      manualAttentionRequired:
          manualAttentionRequired ||
          recommendedDisposition ==
              InformationEvidenceRecommendedDispositions.manualAttention,
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'present': present,
      'severity': severity,
      'recommended_disposition': recommendedDisposition,
      'category': recommendedDisposition,
      'reason': reason,
      'summary': summary,
      'changed_paths': changedPaths,
      'changed_path_count': changedPaths.length,
      'pending_research_count': pendingResearchCount,
      'awaiting_confirmation_count': awaitingConfirmationCount,
      'gateway_failure_count': gatewayFailureCount,
      'rigorous_source_insufficient_count': rigorousSourceInsufficientCount,
      'required_information_omitted_count': requiredInformationOmittedCount,
      'required_omitted_count': requiredInformationOmittedCount,
      'external_fact_unverified_count': externalFactUnverifiedCount,
      'waiting_user': waitingUser,
      'requires_repair': requiresRepair,
      'manual_attention_required': manualAttentionRequired,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (!InformationEvidenceGateSeverities.knownValues.contains(severity)) {
      result.add('invalid_information_evidence_gate_severity');
    }
    if (!InformationEvidenceRecommendedDispositions.knownValues.contains(
      recommendedDisposition,
    )) {
      result.add('invalid_information_evidence_gate_disposition');
    }
    if (pendingResearchCount < 0 ||
        awaitingConfirmationCount < 0 ||
        gatewayFailureCount < 0 ||
        rigorousSourceInsufficientCount < 0 ||
        requiredInformationOmittedCount < 0 ||
        externalFactUnverifiedCount < 0) {
      result.add('invalid_information_evidence_gate_counts');
    }
    return result;
  }

  static String _normalizeDisposition(
    String value, {
    required int awaitingConfirmationCount,
    required int gatewayFailureCount,
    required int rigorousSourceInsufficientCount,
    required int requiredInformationOmittedCount,
    required int externalFactUnverifiedCount,
    required bool waitingUser,
    required bool requiresRepair,
    required bool manualAttentionRequired,
  }) {
    final warningOnlySourceQualityGap = _warningOnlySourceQualityGap(
      awaitingConfirmationCount: awaitingConfirmationCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      waitingUser: waitingUser,
      manualAttentionRequired: manualAttentionRequired,
    );
    final explicitRepairRequested =
        requiresRepair && !warningOnlySourceQualityGap;
    final hasRepairSignals =
        explicitRepairRequested ||
        gatewayFailureCount > 0 ||
        requiredInformationOmittedCount > 0 ||
        externalFactUnverifiedCount > 0;
    final hasWaitingSignals = waitingUser || awaitingConfirmationCount > 0;
    if (value == InformationEvidenceRecommendedDispositions.manualAttention) {
      return value;
    }
    if (value == InformationEvidenceRecommendedDispositions.checkpointUser) {
      return value;
    }
    if (value == InformationEvidenceRecommendedDispositions.repair) {
      if (warningOnlySourceQualityGap) {
        return InformationEvidenceRecommendedDispositions.accept;
      }
      return value;
    }
    if (value == InformationEvidenceRecommendedDispositions.accept &&
        !manualAttentionRequired &&
        !hasWaitingSignals &&
        !hasRepairSignals) {
      return value;
    }
    if (manualAttentionRequired) {
      return InformationEvidenceRecommendedDispositions.manualAttention;
    }
    if (hasWaitingSignals) {
      return InformationEvidenceRecommendedDispositions.checkpointUser;
    }
    if (hasRepairSignals) {
      return InformationEvidenceRecommendedDispositions.repair;
    }
    return InformationEvidenceRecommendedDispositions.accept;
  }

  static bool _warningOnlySourceQualityGap({
    required int awaitingConfirmationCount,
    required int gatewayFailureCount,
    required int rigorousSourceInsufficientCount,
    required int requiredInformationOmittedCount,
    required int externalFactUnverifiedCount,
    required bool waitingUser,
    required bool manualAttentionRequired,
  }) {
    return rigorousSourceInsufficientCount > 0 &&
        awaitingConfirmationCount == 0 &&
        gatewayFailureCount == 0 &&
        requiredInformationOmittedCount == 0 &&
        externalFactUnverifiedCount == 0 &&
        !waitingUser &&
        !manualAttentionRequired;
  }

  static String _normalizeSeverity(
    String value, {
    required String recommendedDisposition,
    required int pendingResearchCount,
    required int awaitingConfirmationCount,
    required int gatewayFailureCount,
    required int rigorousSourceInsufficientCount,
    required int requiredInformationOmittedCount,
    required int externalFactUnverifiedCount,
    required int changedPathCount,
  }) {
    if (InformationEvidenceGateSeverities.knownValues.contains(value)) {
      return value;
    }
    if (recommendedDisposition ==
            InformationEvidenceRecommendedDispositions.manualAttention ||
        recommendedDisposition ==
            InformationEvidenceRecommendedDispositions.checkpointUser ||
        gatewayFailureCount > 0) {
      return InformationEvidenceGateSeverities.blocking;
    }
    if (rigorousSourceInsufficientCount > 0 ||
        requiredInformationOmittedCount > 0 ||
        externalFactUnverifiedCount > 0 ||
        pendingResearchCount > 0) {
      return InformationEvidenceGateSeverities.warning;
    }
    if (awaitingConfirmationCount > 0 || changedPathCount > 0) {
      return InformationEvidenceGateSeverities.info;
    }
    return InformationEvidenceGateSeverities.none;
  }
}
