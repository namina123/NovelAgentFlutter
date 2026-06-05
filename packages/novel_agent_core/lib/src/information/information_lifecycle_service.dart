import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_event.dart';
import 'information_lifecycle_status.dart';
import 'information_lifecycle_statuses.dart';
import 'information_link.dart';

class InformationLifecycleServiceResult {
  const InformationLifecycleServiceResult({
    this.primaryStatus,
    this.emittedEvents = const <InformationEvent>[],
    this.emittedLinks = const <InformationLink>[],
  });

  final InformationLifecycleStatus? primaryStatus;
  final List<InformationEvent> emittedEvents;
  final List<InformationLink> emittedLinks;
}

class InformationLifecycleService {
  const InformationLifecycleService();

  InformationLink createLink({required InformationLink link}) {
    final validationErrors = link.validateBasics();
    if (validationErrors.isNotEmpty) {
      throw ArgumentError.value(
        link.linkId,
        'link',
        validationErrors.join(', '),
      );
    }
    return link.copyWith();
  }

  InformationLifecycleServiceResult propose({
    required NarrativeRef subjectRef,
    required NarrativeRef actorRef,
    List<InformationLink> links = const <InformationLink>[],
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    _ensureRefIsValid(subjectRef, 'subjectRef');
    _ensureRefIsValid(actorRef, 'actorRef');
    final validatedLinks = links
        .map((entry) => createLink(link: entry))
        .toList(growable: false);
    final event = _buildEvent(
      eventId: eventId,
      eventType: 'information_proposed',
      subjectRef: subjectRef,
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      actorRef: actorRef,
      relatedRefs: _relatedRefsOfLinks(validatedLinks),
      relatedLinkIds: validatedLinks
          .map((entry) => entry.linkId)
          .toList(growable: false),
      summary: summary.isNotEmpty ? summary : '信息对象已进入 proposed 状态。',
      occurredAt: occurredAt,
      metadata: metadata,
    );
    final status = InformationLifecycleStatus(
      subjectRef: subjectRef,
      lifecycleStatus: InformationLifecycleStatuses.proposed,
      lastEventId: event.eventId,
      relatedLinkIds: event.relatedLinkIds,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
    return InformationLifecycleServiceResult(
      primaryStatus: status,
      emittedEvents: <InformationEvent>[event],
      emittedLinks: validatedLinks,
    );
  }

  InformationLifecycleServiceResult accept({
    required InformationLifecycleStatus status,
    required NarrativeRef actorRef,
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transition(
      status: status,
      actorRef: actorRef,
      targetStatus: InformationLifecycleStatuses.accepted,
      eventType: 'information_accepted',
      eventId: eventId,
      occurredAt: occurredAt,
      summary: summary.isNotEmpty ? summary : '信息对象已被接受。',
      metadata: metadata,
    );
  }

  InformationLifecycleServiceResult question({
    required InformationLifecycleStatus status,
    required NarrativeRef actorRef,
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transition(
      status: status,
      actorRef: actorRef,
      targetStatus: InformationLifecycleStatuses.questioned,
      eventType: 'information_questioned',
      eventId: eventId,
      occurredAt: occurredAt,
      summary: summary.isNotEmpty ? summary : '信息对象被标记为 questioned。',
      metadata: metadata,
    );
  }

  InformationLifecycleServiceResult reject({
    required InformationLifecycleStatus status,
    required NarrativeRef actorRef,
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transition(
      status: status,
      actorRef: actorRef,
      targetStatus: InformationLifecycleStatuses.rejected,
      eventType: 'information_rejected',
      eventId: eventId,
      occurredAt: occurredAt,
      summary: summary.isNotEmpty ? summary : '信息对象已被拒绝。',
      metadata: metadata,
    );
  }

  InformationLifecycleServiceResult supersede({
    required InformationLifecycleStatus status,
    required NarrativeRef actorRef,
    required NarrativeRef supersededByRef,
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    _ensureRefIsValid(supersededByRef, 'supersededByRef');
    _ensureTransitionAllowed(
      current: status.lifecycleStatus,
      target: InformationLifecycleStatuses.superseded,
    );
    final event = _buildEvent(
      eventId: eventId,
      eventType: 'information_superseded',
      subjectRef: status.subjectRef,
      lifecycleStatus: InformationLifecycleStatuses.superseded,
      actorRef: actorRef,
      relatedRefs: <NarrativeRef>[supersededByRef],
      relatedLinkIds: status.relatedLinkIds,
      summary: summary.isNotEmpty ? summary : '信息对象已被 supersede。',
      occurredAt: occurredAt,
      metadata: metadata,
    );
    final updated = status.copyWith(
      lifecycleStatus: InformationLifecycleStatuses.superseded,
      lastEventId: event.eventId,
      supersededByRef: supersededByRef,
      metadata: _mergeMetadata(status.metadata, metadata),
    );
    return InformationLifecycleServiceResult(
      primaryStatus: updated,
      emittedEvents: <InformationEvent>[event],
    );
  }

  InformationLifecycleServiceResult deprecate({
    required InformationLifecycleStatus status,
    required NarrativeRef actorRef,
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transition(
      status: status,
      actorRef: actorRef,
      targetStatus: InformationLifecycleStatuses.deprecated,
      eventType: 'information_deprecated',
      eventId: eventId,
      occurredAt: occurredAt,
      summary: summary.isNotEmpty ? summary : '信息对象已进入 deprecated 状态。',
      metadata: metadata,
    );
  }

  InformationLifecycleServiceResult _transition({
    required InformationLifecycleStatus status,
    required NarrativeRef actorRef,
    required String targetStatus,
    required String eventType,
    String eventId = '',
    String occurredAt = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    _ensureStatusIsValid(status);
    _ensureRefIsValid(actorRef, 'actorRef');
    _ensureTransitionAllowed(
      current: status.lifecycleStatus,
      target: targetStatus,
    );
    final event = _buildEvent(
      eventId: eventId,
      eventType: eventType,
      subjectRef: status.subjectRef,
      lifecycleStatus: targetStatus,
      actorRef: actorRef,
      relatedRefs: const <NarrativeRef>[],
      relatedLinkIds: status.relatedLinkIds,
      summary: summary,
      occurredAt: occurredAt,
      metadata: metadata,
    );
    final updated = status.copyWith(
      lifecycleStatus: targetStatus,
      lastEventId: event.eventId,
      clearSupersededByRef:
          targetStatus != InformationLifecycleStatuses.superseded,
      metadata: _mergeMetadata(status.metadata, metadata),
    );
    return InformationLifecycleServiceResult(
      primaryStatus: updated,
      emittedEvents: <InformationEvent>[event],
    );
  }

  InformationEvent _buildEvent({
    required String eventId,
    required String eventType,
    required NarrativeRef subjectRef,
    required String lifecycleStatus,
    required NarrativeRef actorRef,
    required List<NarrativeRef> relatedRefs,
    required List<String> relatedLinkIds,
    required String summary,
    required String occurredAt,
    required JsonMap metadata,
  }) {
    return InformationEvent(
      eventId: eventId.trim().isNotEmpty
          ? eventId.trim()
          : 'event_${subjectRef.refId}_$eventType',
      eventType: eventType,
      subjectRef: subjectRef,
      lifecycleStatus: lifecycleStatus,
      actorRef: actorRef,
      relatedRefs: relatedRefs,
      relatedLinkIds: relatedLinkIds,
      summary: summary,
      occurredAt: occurredAt,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  List<NarrativeRef> _relatedRefsOfLinks(List<InformationLink> links) {
    final result = <NarrativeRef>[];
    for (final link in links) {
      if (!_containsRef(result, link.sourceRef)) {
        result.add(link.sourceRef);
      }
      if (!_containsRef(result, link.targetRef)) {
        result.add(link.targetRef);
      }
    }
    return result;
  }

  bool _containsRef(List<NarrativeRef> refs, NarrativeRef candidate) {
    return refs.any(
      (entry) =>
          entry.refType == candidate.refType && entry.refId == candidate.refId,
    );
  }

  void _ensureStatusIsValid(InformationLifecycleStatus status) {
    final validationErrors = status.validateBasics();
    if (validationErrors.isNotEmpty) {
      throw ArgumentError.value(
        status.subjectRef.refId,
        'status',
        validationErrors.join(', '),
      );
    }
  }

  void _ensureRefIsValid(NarrativeRef ref, String name) {
    if (ref.refType.trim().isEmpty || ref.refId.trim().isEmpty) {
      throw ArgumentError.value(ref.refId, name, 'ref_type/ref_id 不能为空。');
    }
  }

  void _ensureTransitionAllowed({
    required String current,
    required String target,
  }) {
    final currentStatus = current.trim();
    final targetStatus = target.trim();
    if (currentStatus.isEmpty || targetStatus.isEmpty) {
      throw ArgumentError('生命周期状态不能为空。');
    }
    if (currentStatus == targetStatus) {
      return;
    }
    if (<String>{
      InformationLifecycleStatuses.rejected,
      InformationLifecycleStatuses.superseded,
      InformationLifecycleStatuses.deprecated,
      InformationLifecycleStatuses.archived,
    }.contains(currentStatus)) {
      throw StateError('$currentStatus 状态的信息对象不能再流转到 $targetStatus。');
    }
    final allowedTargets = <String, Set<String>>{
      InformationLifecycleStatuses.proposed: <String>{
        InformationLifecycleStatuses.accepted,
        InformationLifecycleStatuses.questioned,
        InformationLifecycleStatuses.rejected,
        InformationLifecycleStatuses.superseded,
        InformationLifecycleStatuses.deprecated,
      },
      InformationLifecycleStatuses.accepted: <String>{
        InformationLifecycleStatuses.questioned,
        InformationLifecycleStatuses.superseded,
        InformationLifecycleStatuses.deprecated,
      },
      InformationLifecycleStatuses.questioned: <String>{
        InformationLifecycleStatuses.accepted,
        InformationLifecycleStatuses.rejected,
        InformationLifecycleStatuses.superseded,
        InformationLifecycleStatuses.deprecated,
      },
      InformationLifecycleStatuses.active: <String>{
        InformationLifecycleStatuses.questioned,
        InformationLifecycleStatuses.superseded,
        InformationLifecycleStatuses.deprecated,
      },
    };
    final allowed = allowedTargets[currentStatus] ?? const <String>{};
    if (!allowed.contains(targetStatus)) {
      throw StateError('$currentStatus 状态的信息对象不能直接流转到 $targetStatus。');
    }
  }

  JsonMap _mergeMetadata(JsonMap current, JsonMap next) {
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(current),
      ...ValueReaders.deepCopyMap(next),
    };
  }
}
