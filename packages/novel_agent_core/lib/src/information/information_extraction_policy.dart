import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';

const _informationExtractionPolicyCodecService = OpenJsonContractCodecService();

const _informationExtractionPolicyKnownFields = <String>{
  'collect_broadly',
  'max_candidate_count',
  'max_fetch_count',
  'preserve_rejected_candidates',
  'preserve_uncertain_findings',
  'extract_usable_facts',
  'extract_creative_suggestions',
  'metadata',
};

class InformationExtractionPolicy {
  const InformationExtractionPolicy({
    this.collectBroadly = true,
    this.maxCandidateCount = 0,
    this.maxFetchCount = 0,
    this.preserveRejectedCandidates = true,
    this.preserveUncertainFindings = true,
    this.extractUsableFacts = true,
    this.extractCreativeSuggestions = true,
    this.metadata = const <String, Object?>{},
  });

  final bool collectBroadly;
  final int maxCandidateCount;
  final int maxFetchCount;
  final bool preserveRejectedCandidates;
  final bool preserveUncertainFindings;
  final bool extractUsableFacts;
  final bool extractCreativeSuggestions;
  final JsonMap metadata;

  InformationExtractionPolicy copyWith({
    bool? collectBroadly,
    int? maxCandidateCount,
    int? maxFetchCount,
    bool? preserveRejectedCandidates,
    bool? preserveUncertainFindings,
    bool? extractUsableFacts,
    bool? extractCreativeSuggestions,
    JsonMap? metadata,
  }) {
    return InformationExtractionPolicy(
      collectBroadly: collectBroadly ?? this.collectBroadly,
      maxCandidateCount: maxCandidateCount ?? this.maxCandidateCount,
      maxFetchCount: maxFetchCount ?? this.maxFetchCount,
      preserveRejectedCandidates:
          preserveRejectedCandidates ?? this.preserveRejectedCandidates,
      preserveUncertainFindings:
          preserveUncertainFindings ?? this.preserveUncertainFindings,
      extractUsableFacts: extractUsableFacts ?? this.extractUsableFacts,
      extractCreativeSuggestions:
          extractCreativeSuggestions ?? this.extractCreativeSuggestions,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationExtractionPolicy.fromJson(JsonMap json) {
    return InformationExtractionPolicy(
      collectBroadly: ValueReaders.boolValue(json['collect_broadly'], true),
      maxCandidateCount: ValueReaders.intValue(json['max_candidate_count']),
      maxFetchCount: ValueReaders.intValue(json['max_fetch_count']),
      preserveRejectedCandidates: ValueReaders.boolValue(
        json['preserve_rejected_candidates'],
        true,
      ),
      preserveUncertainFindings: ValueReaders.boolValue(
        json['preserve_uncertain_findings'],
        true,
      ),
      extractUsableFacts: ValueReaders.boolValue(
        json['extract_usable_facts'],
        true,
      ),
      extractCreativeSuggestions: ValueReaders.boolValue(
        json['extract_creative_suggestions'],
        true,
      ),
      metadata: _informationExtractionPolicyCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _informationExtractionPolicyKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _informationExtractionPolicyCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'collect_broadly': collectBroadly,
          'max_candidate_count': maxCandidateCount,
          'max_fetch_count': maxFetchCount,
          'preserve_rejected_candidates': preserveRejectedCandidates,
          'preserve_uncertain_findings': preserveUncertainFindings,
          'extract_usable_facts': extractUsableFacts,
          'extract_creative_suggestions': extractCreativeSuggestions,
        }, metadata: metadata);
  }
}
