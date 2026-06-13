import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import 'information_collection_constants.dart';

const _informationSourceRequirementsCodecService =
    OpenJsonContractCodecService();

const _informationSourceRequirementsKnownFields = <String>{
  'requires_rigorous_sources',
  'min_source_count',
  'preferred_source_kinds',
  'preferred_domains',
  'preferred_languages',
  'network_region_hint',
  'allow_low_confidence_notes',
  'metadata',
};

class InformationSourceRequirements {
  const InformationSourceRequirements({
    this.requiresRigorousSources = false,
    this.minSourceCount = 0,
    this.preferredSourceKinds = const <String>[],
    this.preferredDomains = const <String>[],
    this.preferredLanguages = const <String>[],
    this.networkRegionHint = '',
    this.allowLowConfidenceNotes = true,
    this.metadata = const <String, Object?>{},
  });

  final bool requiresRigorousSources;
  final int minSourceCount;
  final List<String> preferredSourceKinds;
  final List<String> preferredDomains;
  final List<String> preferredLanguages;
  final String networkRegionHint;
  final bool allowLowConfidenceNotes;
  final JsonMap metadata;

  InformationSourceRequirements copyWith({
    bool? requiresRigorousSources,
    int? minSourceCount,
    List<String>? preferredSourceKinds,
    List<String>? preferredDomains,
    List<String>? preferredLanguages,
    String? networkRegionHint,
    bool? allowLowConfidenceNotes,
    JsonMap? metadata,
  }) {
    return InformationSourceRequirements(
      requiresRigorousSources:
          requiresRigorousSources ?? this.requiresRigorousSources,
      minSourceCount: minSourceCount ?? this.minSourceCount,
      preferredSourceKinds: preferredSourceKinds ?? this.preferredSourceKinds,
      preferredDomains: preferredDomains ?? this.preferredDomains,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      networkRegionHint: networkRegionHint ?? this.networkRegionHint,
      allowLowConfidenceNotes:
          allowLowConfidenceNotes ?? this.allowLowConfidenceNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationSourceRequirements.fromJson(JsonMap json) {
    return InformationSourceRequirements(
      requiresRigorousSources: ValueReaders.boolValue(
        json['requires_rigorous_sources'],
      ),
      minSourceCount: ValueReaders.intValue(json['min_source_count']),
      preferredSourceKinds: ValueReaders.stringList(
        json['preferred_source_kinds'],
      ),
      preferredDomains: ValueReaders.stringList(json['preferred_domains']),
      preferredLanguages: ValueReaders.stringList(json['preferred_languages']),
      networkRegionHint: ValueReaders.stringValue(
        json['network_region_hint'],
      ).trim(),
      allowLowConfidenceNotes: ValueReaders.boolValue(
        json['allow_low_confidence_notes'],
        true,
      ),
      metadata: _informationSourceRequirementsCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _informationSourceRequirementsKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _informationSourceRequirementsCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'requires_rigorous_sources': requiresRigorousSources,
          'min_source_count': minSourceCount,
          'preferred_source_kinds': preferredSourceKinds,
          'preferred_domains': preferredDomains,
          'preferred_languages': preferredLanguages,
          'network_region_hint': networkRegionHint,
          'allow_low_confidence_notes': allowLowConfidenceNotes,
        }, metadata: metadata);
  }

  static InformationSourceRequirements empty() {
    return const InformationSourceRequirements(
      networkRegionHint: InformationNetworkRegionHints.auto,
    );
  }
}
