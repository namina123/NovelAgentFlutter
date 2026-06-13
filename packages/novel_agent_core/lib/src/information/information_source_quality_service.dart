import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'information_collection_constants.dart';
import 'information_source_requirements.dart';

class InformationSourceQualityAssessment {
  const InformationSourceQualityAssessment({
    required this.sourceKind,
    required this.rigorLevel,
    required this.isRigorous,
    this.normalizedHost = '',
    this.reasons = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String sourceKind;
  final String rigorLevel;
  final bool isRigorous;
  final String normalizedHost;
  final List<String> reasons;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'source_kind': sourceKind,
      'rigor_level': rigorLevel,
      'is_rigorous': isRigorous,
      'normalized_host': normalizedHost,
      'reasons': reasons,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}

class InformationSourceQualityService {
  const InformationSourceQualityService();

  InformationSourceQualityAssessment assessSearchCandidate(
    JsonMap candidate, {
    InformationSourceRequirements requirements =
        const InformationSourceRequirements(),
    String informationDomain = '',
  }) {
    final url = ValueReaders.stringValue(candidate['url']).trim();
    final title = ValueReaders.stringValue(candidate['title']).trim();
    final snippet = ValueReaders.stringValue(candidate['snippet']).trim();
    final host = _hostFromUrl(url);
    final sourceKind = _sourceKindForHost(host, title: title, snippet: snippet);
    return _assessmentFor(
      sourceKind: sourceKind,
      host: host,
      requirements: requirements,
      informationDomain: informationDomain,
      metadata: <String, Object?>{'url': url, 'title': title},
    );
  }

  InformationSourceQualityAssessment assessImportedSource({
    required String sourceKind,
    String sourceRef = '',
    InformationSourceRequirements requirements =
        const InformationSourceRequirements(),
    String informationDomain = '',
  }) {
    return _assessmentFor(
      sourceKind: sourceKind.trim().isEmpty ? 'imported_source' : sourceKind,
      host: _hostFromUrl(sourceRef),
      requirements: requirements,
      informationDomain: informationDomain,
      metadata: <String, Object?>{'source_ref': sourceRef},
    );
  }

  InformationSourceQualityAssessment _assessmentFor({
    required String sourceKind,
    required String host,
    required InformationSourceRequirements requirements,
    required String informationDomain,
    required JsonMap metadata,
  }) {
    final reasons = <String>[];
    final preferredDomainMatched = _matchesPreferredDomain(
      host,
      requirements.preferredDomains,
    );
    if (preferredDomainMatched) {
      reasons.add('preferred_domain_matched');
    }
    var rigorLevel = _rigorLevelFor(sourceKind, host);
    if (preferredDomainMatched &&
        rigorLevel == InformationSourceRigorLevels.medium) {
      rigorLevel = InformationSourceRigorLevels.high;
    }
    final isRigorous =
        rigorLevel == InformationSourceRigorLevels.high ||
        rigorLevel == InformationSourceRigorLevels.authoritative;
    if (requirements.requiresRigorousSources && !isRigorous) {
      reasons.add('does_not_satisfy_rigorous_source_requirement');
    }
    if (_isObjectiveDomain(informationDomain) && !isRigorous) {
      reasons.add('objective_domain_needs_cross_check');
    }
    if (reasons.isEmpty) {
      reasons.add(isRigorous ? 'rigorous_source_candidate' : 'reference_only');
    }
    return InformationSourceQualityAssessment(
      sourceKind: sourceKind,
      rigorLevel: rigorLevel,
      isRigorous: isRigorous,
      normalizedHost: host,
      reasons: reasons,
      metadata: metadata,
    );
  }

  String _rigorLevelFor(String sourceKind, String host) {
    final kind = sourceKind.trim().toLowerCase();
    if (<String>{
      'government',
      'academic',
      'peer_reviewed_paper',
      'official_document',
      'official_organization',
      'primary_source',
    }.contains(kind)) {
      return InformationSourceRigorLevels.authoritative;
    }
    if (host.endsWith('.gov') ||
        host.endsWith('.gov.cn') ||
        host.endsWith('.edu') ||
        host.endsWith('.edu.cn') ||
        host.contains('.ac.') ||
        host == 'doi.org' ||
        host == 'arxiv.org' ||
        host.endsWith('.nih.gov') ||
        host == 'pubmed.ncbi.nlm.nih.gov' ||
        host == 'who.int' ||
        host == 'un.org' ||
        host.endsWith('.un.org') ||
        host == 'worldbank.org' ||
        host.endsWith('.worldbank.org') ||
        host == 'oecd.org' ||
        host.endsWith('.oecd.org')) {
      return InformationSourceRigorLevels.high;
    }
    if (kind == 'imported_document' ||
        kind == 'source_document' ||
        host == 'wikipedia.org' ||
        host.endsWith('.wikipedia.org') ||
        host.endsWith('.org')) {
      return InformationSourceRigorLevels.medium;
    }
    if (host.contains('zhihu') ||
        host.contains('baidu') ||
        host.contains('csdn') ||
        host.contains('blog') ||
        host.contains('fandom') ||
        host.contains('wiki')) {
      return InformationSourceRigorLevels.low;
    }
    return host.isEmpty
        ? InformationSourceRigorLevels.unknown
        : InformationSourceRigorLevels.medium;
  }

  String _sourceKindForHost(
    String host, {
    required String title,
    required String snippet,
  }) {
    if (host.endsWith('.gov') || host.endsWith('.gov.cn')) {
      return 'government';
    }
    if (host.endsWith('.edu') ||
        host.endsWith('.edu.cn') ||
        host.contains('.ac.')) {
      return 'academic';
    }
    if (host == 'doi.org' || host == 'arxiv.org' || host.contains('pubmed')) {
      return 'academic';
    }
    if (host.endsWith('.org')) {
      return 'official_organization';
    }
    final joined = '$title $snippet'.toLowerCase();
    if (joined.contains('journal') ||
        joined.contains('paper') ||
        joined.contains('论文')) {
      return 'academic';
    }
    return 'web_page';
  }

  bool _matchesPreferredDomain(String host, List<String> preferredDomains) {
    if (host.isEmpty || preferredDomains.isEmpty) {
      return false;
    }
    return preferredDomains.any((entry) {
      final normalized = entry.trim().toLowerCase();
      return normalized.isNotEmpty &&
          (host == normalized || host.endsWith('.$normalized'));
    });
  }

  bool _isObjectiveDomain(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == InformationDomains.objective ||
        normalized == InformationDomains.history ||
        normalized == InformationDomains.science ||
        normalized == InformationDomains.technology ||
        normalized == InformationDomains.legal ||
        normalized == InformationDomains.medical ||
        normalized.contains('factual') ||
        normalized.contains('objective');
  }

  String _hostFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.trim().isEmpty) {
      return '';
    }
    var host = uri.host.trim().toLowerCase();
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    return host;
  }
}
