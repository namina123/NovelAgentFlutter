import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_profile.dart';
import 'narrative_profile_interpretation.dart';
import 'narrative_profile_lifecycle_status.dart';

class NarrativeProfileInterpreterService {
  const NarrativeProfileInterpreterService();

  NarrativeProfileInterpretation interpretClaimNamespace({
    required NarrativeProfile activeProfile,
    required String claimNamespace,
    JsonMap claimPayload = const <String, Object?>{},
  }) {
    final normalizedNamespace = claimNamespace.trim();
    final namespaceMeanings = _findRuleMap(activeProfile, const <String>[
      'claim_namespace_meanings',
      'namespace_meanings',
    ]);
    final schemaHints = _findRuleMap(activeProfile, const <String>[
      'claim_schema_hints',
      'schema_hints',
    ]);
    final riskHints = _findRuleMap(activeProfile, const <String>[
      'risk_policy_hints',
      'claim_risk_policy_hints',
    ]);

    final matchedMeaningKey = _matchRuleKey(
      namespaceMeanings.keys.toList(growable: false),
      normalizedNamespace,
    );
    final matchedSchemaKey = _matchRuleKey(
      schemaHints.keys.toList(growable: false),
      normalizedNamespace,
    );
    final matchedRiskKey = _matchRuleKey(
      riskHints.keys.toList(growable: false),
      normalizedNamespace,
    );

    final matchedMeaningEntry = matchedMeaningKey.isEmpty
        ? null
        : namespaceMeanings[matchedMeaningKey];
    final matchedSchemaEntry = matchedSchemaKey.isEmpty
        ? <String, Object?>{}
        : ValueReaders.mapValue(schemaHints[matchedSchemaKey]);
    final matchedRiskEntry = matchedRiskKey.isEmpty
        ? <String, Object?>{}
        : ValueReaders.mapValue(riskHints[matchedRiskKey]);
    final requiredFields = _readRequiredFields(matchedSchemaEntry);
    final claimFields = claimPayload.keys
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final missingRequiredFields = requiredFields
        .where((field) => !claimFields.contains(field))
        .toList(growable: false);

    return NarrativeProfileInterpretation(
      claimNamespace: normalizedNamespace,
      profileId: activeProfile.profileId,
      profileNamespace: activeProfile.profileNamespace,
      matchedRuleKey: _firstNonBlank(<String>[
        matchedMeaningKey,
        matchedSchemaKey,
        matchedRiskKey,
      ]),
      namespaceMeaning: _readNamespaceMeaning(
        matchedMeaningEntry,
        claimNamespace: normalizedNamespace,
        activeProfile: activeProfile,
      ),
      minimalFieldRequirements: requiredFields,
      missingRequiredFields: missingRequiredFields,
      riskEscalationSuggestions: _readStringListByKeys(
        matchedRiskEntry,
        const <String>['escalate_when', 'raise_when', 'needs_review_when'],
      ),
      riskDeEscalationSuggestions: _readStringListByKeys(
        matchedRiskEntry,
        const <String>['deescalate_when', 'lower_when', 'auto_accept_when'],
      ),
      unknownPayloadPreservationExplanation: _readUnknownPayloadExplanation(
        activeProfile: activeProfile,
        matchedMeaningEntry: matchedMeaningEntry,
        matchedSchemaEntry: matchedSchemaEntry,
      ),
      interpreterMetadata: <String, Object?>{
        'profile_lifecycle_status': activeProfile.lifecycleStatus.id,
        'active_profile_required':
            activeProfile.lifecycleStatus ==
            NarrativeProfileLifecycleStatus.active,
        'matched_meaning_key': matchedMeaningKey,
        'matched_schema_key': matchedSchemaKey,
        'matched_risk_key': matchedRiskKey,
      },
    );
  }

  JsonMap _findRuleMap(NarrativeProfile profile, List<String> keys) {
    for (final key in keys) {
      final directPayload = ValueReaders.mapValue(profile.profilePayload[key]);
      if (directPayload.isNotEmpty) {
        return directPayload;
      }
      final directExtensions = ValueReaders.mapValue(
        profile.profileExtensions[key],
      );
      if (directExtensions.isNotEmpty) {
        return directExtensions;
      }
      final payloadInterpreter = ValueReaders.mapValue(
        profile.profilePayload['project_interpreter'],
      );
      final nestedPayload = ValueReaders.mapValue(payloadInterpreter[key]);
      if (nestedPayload.isNotEmpty) {
        return nestedPayload;
      }
      final extensionInterpreter = ValueReaders.mapValue(
        profile.profileExtensions['project_interpreter'],
      );
      final nestedExtensions = ValueReaders.mapValue(extensionInterpreter[key]);
      if (nestedExtensions.isNotEmpty) {
        return nestedExtensions;
      }
    }
    return const <String, Object?>{};
  }

  String _matchRuleKey(List<String> keys, String claimNamespace) {
    var exactMatch = '';
    var wildcardMatch = '';
    for (final rawKey in keys) {
      final key = rawKey.trim();
      if (key.isEmpty) {
        continue;
      }
      if (key == claimNamespace) {
        if (key.length > exactMatch.length) {
          exactMatch = key;
        }
        continue;
      }
      if (key == '*') {
        if (wildcardMatch.isEmpty) {
          wildcardMatch = key;
        }
        continue;
      }
      if (!key.endsWith('.*')) {
        continue;
      }
      final prefix = key.substring(0, key.length - 1);
      if (claimNamespace.startsWith(prefix) &&
          key.length > wildcardMatch.length) {
        wildcardMatch = key;
      }
    }
    return exactMatch.isNotEmpty ? exactMatch : wildcardMatch;
  }

  List<String> _readRequiredFields(JsonMap entry) {
    return _readStringListByKeys(entry, const <String>[
      'required_fields',
      'minimum_fields',
      'required',
    ]);
  }

  List<String> _readStringListByKeys(JsonMap entry, List<String> keys) {
    for (final key in keys) {
      final list = ValueReaders.stringList(entry[key]);
      if (list.isNotEmpty) {
        return list;
      }
      final nested = ValueReaders.mapValue(entry[key]);
      final nestedList = ValueReaders.stringList(
        nested['fields'] ?? nested['items'] ?? nested['values'],
      );
      if (nestedList.isNotEmpty) {
        return nestedList;
      }
    }
    return const <String>[];
  }

  String _readNamespaceMeaning(
    Object? matchedMeaningEntry, {
    required String claimNamespace,
    required NarrativeProfile activeProfile,
  }) {
    final entryMap = ValueReaders.mapValue(matchedMeaningEntry);
    final mappedMeaning = ValueReaders.stringValue(
      entryMap['meaning'],
      ValueReaders.stringValue(entryMap['description']),
    ).trim();
    if (mappedMeaning.isNotEmpty) {
      return mappedMeaning;
    }
    final directMeaning = ValueReaders.stringValue(matchedMeaningEntry).trim();
    if (directMeaning.isNotEmpty) {
      return directMeaning;
    }
    return '项目 profile `${activeProfile.profileId}` 将 `$claimNamespace` 视为需要保留的开放 claim namespace。';
  }

  String _readUnknownPayloadExplanation({
    required NarrativeProfile activeProfile,
    required Object? matchedMeaningEntry,
    required JsonMap matchedSchemaEntry,
  }) {
    final meaningMap = ValueReaders.mapValue(matchedMeaningEntry);
    final explanation = _firstNonBlank(<String>[
      ValueReaders.stringValue(meaningMap['unknown_payload_preservation']),
      ValueReaders.stringValue(
        matchedSchemaEntry['unknown_payload_preservation'],
      ),
      ValueReaders.stringValue(
        activeProfile.profilePayload['unknown_payload_preservation'],
      ),
      ValueReaders.stringValue(
        activeProfile.profileExtensions['unknown_payload_preservation'],
      ),
      ValueReaders.stringValue(
        ValueReaders.mapValue(
          activeProfile.profilePayload['project_interpreter'],
        )['unknown_payload_preservation'],
      ),
    ]);
    if (explanation.isNotEmpty) {
      return explanation;
    }
    return '未被当前项目解释器识别的 payload 字段也要原样保留，后续再由 proposal/review 决定是否赋义。';
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
