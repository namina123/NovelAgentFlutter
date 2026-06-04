import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_profile.dart';
import 'narrative_profile_audit_event.dart';
import 'narrative_profile_lifecycle_status.dart';
import 'narrative_profile_proposal.dart';
import 'narrative_profile_proposal_validator.dart';

class NarrativeProfileProposalServiceResult {
  const NarrativeProfileProposalServiceResult({
    this.primaryProposal,
    this.primaryProfile,
    this.proposals = const <NarrativeProfileProposal>[],
    this.profiles = const <NarrativeProfile>[],
    this.auditEvents = const <NarrativeProfileAuditEvent>[],
    this.conflictingProposalIds = const <String>[],
  });

  final NarrativeProfileProposal? primaryProposal;
  final NarrativeProfile? primaryProfile;
  final List<NarrativeProfileProposal> proposals;
  final List<NarrativeProfile> profiles;
  final List<NarrativeProfileAuditEvent> auditEvents;
  final List<String> conflictingProposalIds;
}

class NarrativeProfileProposalService {
  const NarrativeProfileProposalService({
    NarrativeProfileProposalValidator? proposalValidator,
  }) : _proposalValidator =
           proposalValidator ?? const NarrativeProfileProposalValidator();

  final NarrativeProfileProposalValidator _proposalValidator;

  NarrativeProfileProposalServiceResult propose({
    required NarrativeProfileProposal proposal,
    List<NarrativeProfileProposal> existingProposals =
        const <NarrativeProfileProposal>[],
    List<NarrativeProfile> existingProfiles = const <NarrativeProfile>[],
  }) {
    _ensureProposalIsValid(proposal);

    final normalizedProposal = proposal.copyWith(
      proposalStatus: NarrativeProfileLifecycleStatus.proposed,
    );
    final conflictingProposals = existingProposals
        .where(
          (entry) =>
              entry.proposalId != normalizedProposal.proposalId &&
              _isOpenProposalStatus(entry.proposalStatus) &&
              _looksConflicting(entry, normalizedProposal),
        )
        .toList(growable: false);
    final supersededConflicts = conflictingProposals
        .map(
          (entry) => entry.copyWith(
            proposalStatus: NarrativeProfileLifecycleStatus.superseded,
            metadata: _mergeMetadata(entry.metadata, <String, Object?>{
              'superseded_by_proposal_id': normalizedProposal.proposalId,
              'superseded_reason': 'conflicting_proposal_replaced',
            }),
          ),
        )
        .toList(growable: false);
    final updatedProposals = _replaceOrAppendProposal(
      proposals: existingProposals,
      proposal: normalizedProposal,
      additionalReplacements: supersededConflicts,
    );
    final auditEvents = <NarrativeProfileAuditEvent>[
      _buildAuditEvent(
        eventType: 'proposal_proposed',
        proposalId: normalizedProposal.proposalId,
        summary: 'profile proposal 已进入 proposed 状态。',
        metadata: <String, Object?>{
          'target_profile_id': normalizedProposal.targetProfileId,
          'base_profile_id': normalizedProposal.baseProfileId,
          'profile_namespace': _namespaceOfProposal(normalizedProposal),
        },
      ),
      ...supersededConflicts.map(
        (entry) => _buildAuditEvent(
          eventType: 'proposal_superseded',
          proposalId: entry.proposalId,
          relatedProposalId: normalizedProposal.proposalId,
          summary: '冲突 proposal 被新的 profile proposal supersede。',
          metadata: <String, Object?>{
            'superseded_reason': 'conflicting_proposal_replaced',
          },
        ),
      ),
    ];

    return NarrativeProfileProposalServiceResult(
      primaryProposal: normalizedProposal,
      proposals: updatedProposals,
      profiles: List<NarrativeProfile>.from(existingProfiles, growable: false),
      auditEvents: auditEvents,
      conflictingProposalIds: conflictingProposals
          .map((entry) => entry.proposalId)
          .toList(growable: false),
    );
  }

  NarrativeProfileProposalServiceResult accept({
    required NarrativeProfileProposal proposal,
    List<NarrativeProfileProposal> existingProposals =
        const <NarrativeProfileProposal>[],
    List<NarrativeProfile> existingProfiles = const <NarrativeProfile>[],
  }) {
    _ensureProposalIsValid(proposal);
    if (proposal.proposalStatus != NarrativeProfileLifecycleStatus.proposed) {
      throw StateError('只有 proposed 状态的 profile proposal 才能被接受。');
    }

    final acceptedProposal = proposal.copyWith(
      proposalStatus: NarrativeProfileLifecycleStatus.accepted,
    );
    final targetProfile = _findTargetProfile(
      proposal: proposal,
      profiles: existingProfiles,
    );
    final acceptedProfile = _buildAcceptedProfile(
      proposal: acceptedProposal,
      baseProfile: targetProfile,
    );
    final conflictingProposals = existingProposals
        .where(
          (entry) =>
              entry.proposalId != acceptedProposal.proposalId &&
              _isOpenProposalStatus(entry.proposalStatus) &&
              _looksConflicting(entry, acceptedProposal),
        )
        .map(
          (entry) => entry.copyWith(
            proposalStatus: NarrativeProfileLifecycleStatus.superseded,
            metadata: _mergeMetadata(entry.metadata, <String, Object?>{
              'superseded_by_proposal_id': acceptedProposal.proposalId,
              'superseded_by_profile_id': acceptedProfile.profileId,
            }),
          ),
        )
        .toList(growable: false);
    final updatedProposals = _replaceOrAppendProposal(
      proposals: existingProposals,
      proposal: acceptedProposal,
      additionalReplacements: conflictingProposals,
    );

    NarrativeProfile? supersededProfile;
    var updatedProfiles = _replaceOrAppendProfile(
      profiles: existingProfiles,
      profile: acceptedProfile,
    );
    if (targetProfile != null &&
        targetProfile.profileId != acceptedProfile.profileId &&
        targetProfile.lifecycleStatus !=
            NarrativeProfileLifecycleStatus.deprecated &&
        targetProfile.lifecycleStatus !=
            NarrativeProfileLifecycleStatus.superseded) {
      supersededProfile = targetProfile.copyWith(
        lifecycleStatus: NarrativeProfileLifecycleStatus.superseded,
        metadata: _mergeMetadata(targetProfile.metadata, <String, Object?>{
          'superseded_by_profile_id': acceptedProfile.profileId,
          'superseded_by_proposal_id': acceptedProposal.proposalId,
        }),
      );
      updatedProfiles = _replaceOrAppendProfile(
        profiles: updatedProfiles,
        profile: supersededProfile,
      );
    }

    final auditEvents = <NarrativeProfileAuditEvent>[
      _buildAuditEvent(
        eventType: 'proposal_accepted',
        proposalId: acceptedProposal.proposalId,
        profileId: acceptedProfile.profileId,
        relatedProfileId: targetProfile?.profileId ?? '',
        summary: 'profile proposal 已接受，并物化为 accepted profile。',
        metadata: <String, Object?>{
          'profile_namespace': acceptedProfile.profileNamespace,
          'accepted_profile_status': acceptedProfile.lifecycleStatus.id,
        },
      ),
      if (supersededProfile != null)
        _buildAuditEvent(
          eventType: 'profile_superseded',
          proposalId: acceptedProposal.proposalId,
          profileId: supersededProfile.profileId,
          relatedProfileId: acceptedProfile.profileId,
          summary: '既有 profile 被新的 accepted profile supersede。',
        ),
      ...conflictingProposals.map(
        (entry) => _buildAuditEvent(
          eventType: 'proposal_superseded',
          proposalId: entry.proposalId,
          relatedProposalId: acceptedProposal.proposalId,
          relatedProfileId: acceptedProfile.profileId,
          summary: '冲突 proposal 在接受新 proposal 时被 supersede。',
        ),
      ),
    ];

    return NarrativeProfileProposalServiceResult(
      primaryProposal: acceptedProposal,
      primaryProfile: acceptedProfile,
      proposals: updatedProposals,
      profiles: updatedProfiles,
      auditEvents: auditEvents,
      conflictingProposalIds: conflictingProposals
          .map((entry) => entry.proposalId)
          .toList(growable: false),
    );
  }

  NarrativeProfileProposalServiceResult reject({
    required NarrativeProfileProposal proposal,
    List<NarrativeProfileProposal> existingProposals =
        const <NarrativeProfileProposal>[],
    List<NarrativeProfile> existingProfiles = const <NarrativeProfile>[],
  }) {
    _ensureProposalIsValid(proposal);
    final rejectedProposal = proposal.copyWith(
      proposalStatus: NarrativeProfileLifecycleStatus.rejected,
    );
    return NarrativeProfileProposalServiceResult(
      primaryProposal: rejectedProposal,
      proposals: _replaceOrAppendProposal(
        proposals: existingProposals,
        proposal: rejectedProposal,
      ),
      profiles: List<NarrativeProfile>.from(existingProfiles, growable: false),
      auditEvents: <NarrativeProfileAuditEvent>[
        _buildAuditEvent(
          eventType: 'proposal_rejected',
          proposalId: rejectedProposal.proposalId,
          summary: 'profile proposal 已被拒绝。',
        ),
      ],
    );
  }

  NarrativeProfileProposalServiceResult supersede({
    required NarrativeProfileProposal proposal,
    required String supersededByProposalId,
    String supersededByProfileId = '',
    List<NarrativeProfileProposal> existingProposals =
        const <NarrativeProfileProposal>[],
    List<NarrativeProfile> existingProfiles = const <NarrativeProfile>[],
  }) {
    _ensureProposalIsValid(proposal);
    if (supersededByProposalId.trim().isEmpty &&
        supersededByProfileId.trim().isEmpty) {
      throw ArgumentError('supersede 必须提供 proposal 或 profile 引用。');
    }
    final supersededProposal = proposal.copyWith(
      proposalStatus: NarrativeProfileLifecycleStatus.superseded,
      metadata: _mergeMetadata(proposal.metadata, <String, Object?>{
        'superseded_by_proposal_id': supersededByProposalId.trim(),
        'superseded_by_profile_id': supersededByProfileId.trim(),
      }),
    );
    return NarrativeProfileProposalServiceResult(
      primaryProposal: supersededProposal,
      proposals: _replaceOrAppendProposal(
        proposals: existingProposals,
        proposal: supersededProposal,
      ),
      profiles: List<NarrativeProfile>.from(existingProfiles, growable: false),
      auditEvents: <NarrativeProfileAuditEvent>[
        _buildAuditEvent(
          eventType: 'proposal_superseded',
          proposalId: supersededProposal.proposalId,
          relatedProposalId: supersededByProposalId.trim(),
          relatedProfileId: supersededByProfileId.trim(),
          summary: 'profile proposal 已被 supersede，并写入清晰引用。',
        ),
      ],
    );
  }

  NarrativeProfileProposalServiceResult deprecate({
    required NarrativeProfile profile,
    List<NarrativeProfileProposal> existingProposals =
        const <NarrativeProfileProposal>[],
    List<NarrativeProfile> existingProfiles = const <NarrativeProfile>[],
  }) {
    final deprecatedProfile = profile.copyWith(
      lifecycleStatus: NarrativeProfileLifecycleStatus.deprecated,
    );
    return NarrativeProfileProposalServiceResult(
      primaryProfile: deprecatedProfile,
      proposals: List<NarrativeProfileProposal>.from(
        existingProposals,
        growable: false,
      ),
      profiles: _replaceOrAppendProfile(
        profiles: existingProfiles,
        profile: deprecatedProfile,
      ),
      auditEvents: <NarrativeProfileAuditEvent>[
        _buildAuditEvent(
          eventType: 'profile_deprecated',
          profileId: deprecatedProfile.profileId,
          summary: 'profile 已进入 deprecated 状态。',
        ),
      ],
    );
  }

  void _ensureProposalIsValid(NarrativeProfileProposal proposal) {
    final validationErrors = _proposalValidator.validate(proposal);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError.value(
        proposal.proposalId,
        'proposal',
        validationErrors.join(', '),
      );
    }
  }

  bool _isOpenProposalStatus(NarrativeProfileLifecycleStatus status) {
    return status == NarrativeProfileLifecycleStatus.draft ||
        status == NarrativeProfileLifecycleStatus.proposed;
  }

  bool _looksConflicting(
    NarrativeProfileProposal left,
    NarrativeProfileProposal right,
  ) {
    final leftNamespace = _namespaceOfProposal(left);
    final rightNamespace = _namespaceOfProposal(right);
    return _sameNonBlank(left.targetProfileId, right.targetProfileId) ||
        _sameNonBlank(left.baseProfileId, right.baseProfileId) ||
        _sameNonBlank(left.targetProfileId, right.baseProfileId) ||
        _sameNonBlank(left.baseProfileId, right.targetProfileId) ||
        _sameNonBlank(leftNamespace, rightNamespace);
  }

  bool _sameNonBlank(String left, String right) {
    return left.trim().isNotEmpty &&
        right.trim().isNotEmpty &&
        left.trim() == right.trim();
  }

  String _namespaceOfProposal(NarrativeProfileProposal proposal) {
    final patchPayload = proposal.profilePatch.patchPayload;
    return _firstNonBlank(<String>[
      ValueReaders.stringValue(patchPayload['profile_namespace']),
      ValueReaders.stringValue(patchPayload['namespace']),
      ValueReaders.stringValue(proposal.metadata['profile_namespace']),
    ]);
  }

  NarrativeProfile? _findTargetProfile({
    required NarrativeProfileProposal proposal,
    required List<NarrativeProfile> profiles,
  }) {
    for (final profile in profiles) {
      if (_sameNonBlank(profile.profileId, proposal.targetProfileId) ||
          _sameNonBlank(profile.profileId, proposal.baseProfileId)) {
        return profile;
      }
    }
    final targetNamespace = _namespaceOfProposal(proposal);
    if (targetNamespace.isEmpty) {
      return null;
    }
    for (final profile in profiles) {
      if (profile.profileNamespace == targetNamespace &&
          profile.lifecycleStatus == NarrativeProfileLifecycleStatus.active) {
        return profile;
      }
    }
    return null;
  }

  NarrativeProfile _buildAcceptedProfile({
    required NarrativeProfileProposal proposal,
    required NarrativeProfile? baseProfile,
  }) {
    final patch = proposal.profilePatch;
    final acceptedProfileId = _firstNonBlank(<String>[
      ValueReaders.stringValue(proposal.metadata['accepted_profile_id']),
      ValueReaders.stringValue(patch.metadata['accepted_profile_id']),
      _defaultAcceptedProfileId(proposal, baseProfile),
    ]);
    final acceptedPayload = _mergeMetadata(
      baseProfile?.profilePayload ?? const <String, Object?>{},
      patch.patchPayload,
    );
    final acceptedExtensions = _mergeMetadata(
      baseProfile?.profileExtensions ?? const <String, Object?>{},
      patch.patchExtensions,
    );
    return NarrativeProfile(
      profileId: acceptedProfileId,
      profileNamespace: _firstNonBlank(<String>[
        ValueReaders.stringValue(acceptedPayload['profile_namespace']),
        ValueReaders.stringValue(acceptedPayload['namespace']),
        baseProfile?.profileNamespace ?? '',
      ]),
      profileLabel: _firstNonBlank(<String>[
        ValueReaders.stringValue(acceptedPayload['profile_label']),
        ValueReaders.stringValue(acceptedPayload['display_name']),
        patch.patchLabel,
        baseProfile?.profileLabel ?? '',
      ]),
      lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
      profilePayload: acceptedPayload,
      profileExtensions: acceptedExtensions,
      source: proposal.source,
      confidence: proposal.confidence,
      reason: proposal.reason,
      schemaVersion: _firstNonBlank(<String>[
        proposal.schemaVersion,
        patch.schemaVersion,
        baseProfile?.schemaVersion ?? '',
      ]),
      metadata: _mergeMetadata(
        baseProfile?.metadata ?? const <String, Object?>{},
        _mergeMetadata(proposal.metadata, <String, Object?>{
          'accepted_from_proposal_id': proposal.proposalId,
          'base_profile_id': proposal.baseProfileId,
          'target_profile_id': proposal.targetProfileId,
        }),
      ),
    );
  }

  String _defaultAcceptedProfileId(
    NarrativeProfileProposal proposal,
    NarrativeProfile? baseProfile,
  ) {
    final seed = _firstNonBlank(<String>[
      proposal.targetProfileId,
      proposal.baseProfileId,
      baseProfile?.profileId ?? '',
      'profile',
    ]);
    return '$seed.accepted.${proposal.proposalId}';
  }

  List<NarrativeProfileProposal> _replaceOrAppendProposal({
    required List<NarrativeProfileProposal> proposals,
    required NarrativeProfileProposal proposal,
    List<NarrativeProfileProposal> additionalReplacements =
        const <NarrativeProfileProposal>[],
  }) {
    final replacements = <String, NarrativeProfileProposal>{
      proposal.proposalId: proposal,
      for (final entry in additionalReplacements) entry.proposalId: entry,
    };
    final result = <NarrativeProfileProposal>[];
    final seen = <String>{};
    for (final current in proposals) {
      final replacement = replacements[current.proposalId];
      if (replacement != null) {
        result.add(replacement);
        seen.add(current.proposalId);
      } else {
        result.add(current);
        seen.add(current.proposalId);
      }
    }
    for (final replacement in replacements.values) {
      if (seen.add(replacement.proposalId)) {
        result.add(replacement);
      }
    }
    return List<NarrativeProfileProposal>.from(result, growable: false);
  }

  List<NarrativeProfile> _replaceOrAppendProfile({
    required List<NarrativeProfile> profiles,
    required NarrativeProfile profile,
  }) {
    final result = <NarrativeProfile>[];
    var replaced = false;
    for (final current in profiles) {
      if (current.profileId == profile.profileId) {
        result.add(profile);
        replaced = true;
      } else {
        result.add(current);
      }
    }
    if (!replaced) {
      result.add(profile);
    }
    return List<NarrativeProfile>.from(result, growable: false);
  }

  NarrativeProfileAuditEvent _buildAuditEvent({
    required String eventType,
    String proposalId = '',
    String profileId = '',
    String relatedProposalId = '',
    String relatedProfileId = '',
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final identitySeed = _firstNonBlank(<String>[
      proposalId,
      profileId,
      relatedProposalId,
      relatedProfileId,
      'profile',
    ]);
    return NarrativeProfileAuditEvent(
      eventId: '$eventType:$identitySeed',
      eventType: eventType,
      proposalId: proposalId,
      profileId: profileId,
      relatedProposalId: relatedProposalId,
      relatedProfileId: relatedProfileId,
      summary: summary,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  JsonMap _mergeMetadata(JsonMap base, JsonMap patch) {
    return ValueReaders.deepCopyMap(<String, Object?>{...base, ...patch});
  }

  String _firstNonBlank(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
}
