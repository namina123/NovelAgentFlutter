import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_collection_constants.dart';
import 'information_extraction_policy.dart';
import 'information_source_requirements.dart';

const _informationCollectionRequestCodecService =
    OpenJsonContractCodecService();

const _informationCollectionRequestKnownFields = <String>{
  'query',
  'purpose',
  'requested_depth',
  'reference_relationship',
  'collection_mode',
  'information_domain',
  'target_refs',
  'user_granted_network_access',
  'source_requirements',
  'extraction_policy',
  'metadata',
};

class InformationCollectionRequest {
  const InformationCollectionRequest({
    required this.query,
    this.purpose = '',
    this.requestedDepth = '',
    this.referenceRelationship = '',
    this.collectionMode = '',
    this.informationDomain = '',
    this.targetRefs = const <NarrativeRef>[],
    this.userGrantedNetworkAccess = false,
    this.sourceRequirements = const InformationSourceRequirements(),
    this.extractionPolicy = const InformationExtractionPolicy(),
    this.metadata = const <String, Object?>{},
  });

  final String query;
  final String purpose;
  final String requestedDepth;
  final String referenceRelationship;
  final String collectionMode;
  final String informationDomain;
  final List<NarrativeRef> targetRefs;
  final bool userGrantedNetworkAccess;
  final InformationSourceRequirements sourceRequirements;
  final InformationExtractionPolicy extractionPolicy;
  final JsonMap metadata;

  InformationCollectionRequest copyWith({
    String? query,
    String? purpose,
    String? requestedDepth,
    String? referenceRelationship,
    String? collectionMode,
    String? informationDomain,
    List<NarrativeRef>? targetRefs,
    bool? userGrantedNetworkAccess,
    InformationSourceRequirements? sourceRequirements,
    InformationExtractionPolicy? extractionPolicy,
    JsonMap? metadata,
  }) {
    return InformationCollectionRequest(
      query: query ?? this.query,
      purpose: purpose ?? this.purpose,
      requestedDepth: requestedDepth ?? this.requestedDepth,
      referenceRelationship:
          referenceRelationship ?? this.referenceRelationship,
      collectionMode: collectionMode ?? this.collectionMode,
      informationDomain: informationDomain ?? this.informationDomain,
      targetRefs: targetRefs ?? this.targetRefs,
      userGrantedNetworkAccess:
          userGrantedNetworkAccess ?? this.userGrantedNetworkAccess,
      sourceRequirements: sourceRequirements ?? this.sourceRequirements,
      extractionPolicy: extractionPolicy ?? this.extractionPolicy,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationCollectionRequest.fromJson(JsonMap json) {
    return InformationCollectionRequest(
      query: ValueReaders.stringValue(json['query']).trim(),
      purpose: ValueReaders.stringValue(json['purpose']).trim(),
      requestedDepth: ValueReaders.stringValue(json['requested_depth']).trim(),
      referenceRelationship: ValueReaders.stringValue(
        json['reference_relationship'],
      ).trim(),
      collectionMode: ValueReaders.stringValue(json['collection_mode']).trim(),
      informationDomain: ValueReaders.stringValue(
        json['information_domain'],
      ).trim(),
      targetRefs: ValueReaders.mapList(
        json['target_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      userGrantedNetworkAccess: ValueReaders.boolValue(
        json['user_granted_network_access'],
      ),
      sourceRequirements: InformationSourceRequirements.fromJson(
        ValueReaders.mapValue(json['source_requirements']),
      ),
      extractionPolicy: InformationExtractionPolicy.fromJson(
        ValueReaders.mapValue(json['extraction_policy']),
      ),
      metadata: _informationCollectionRequestCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _informationCollectionRequestKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _informationCollectionRequestCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'query': query,
          'purpose': purpose,
          'requested_depth': requestedDepth,
          'reference_relationship': referenceRelationship,
          'collection_mode': collectionMode,
          'information_domain': informationDomain,
          'target_refs': targetRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'user_granted_network_access': userGrantedNetworkAccess,
          'source_requirements': sourceRequirements.toJson(),
          'extraction_policy': extractionPolicy.toJson(),
        }, metadata: metadata);
  }

  bool get rawModelUserGrantedNetworkAccess {
    // 中文注释: 该字段只代表模型或上游 payload 的原始自声明，不应直接视为宿主最终授权结果。
    return userGrantedNetworkAccess;
  }

  bool get requiresNetwork {
    final normalized = collectionMode.trim().toLowerCase();
    if (normalized == InformationCollectionModes.import) {
      return false;
    }
    return normalized == InformationCollectionModes.network ||
        normalized == InformationCollectionModes.hybrid ||
        normalized.isEmpty ||
        normalized == InformationCollectionModes.unknown;
  }
}
