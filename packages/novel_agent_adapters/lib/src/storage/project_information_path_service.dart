import 'package:novel_agent_core/novel_agent_core.dart';

import '../tools/project_tool_path_policy.dart';

class ProjectInformationPathService {
  ProjectInformationPathService({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy(),
      _sourceOfTruthLocatorService =
          const InformationSourceOfTruthLocatorService();

  final ProjectToolPathPolicy _toolPathPolicy;
  final InformationSourceOfTruthLocatorService _sourceOfTruthLocatorService;

  String knowledgeCardsIndexPath() =>
      '.novel_agent/information/knowledge_cards/index.json';

  String knowledgeCardPath(String cardId) {
    return '.novel_agent/information/knowledge_cards/${_safeId(cardId, fallback: 'knowledge_card')}.json';
  }

  String knowledgeCardLocator(String cardId) {
    return _sourceOfTruthLocatorService.entryLocator(
      InformationSourceOfTruthCollections.knowledgeCards,
      _safeId(cardId, fallback: 'knowledge_card'),
    );
  }

  String designElementsIndexPath() =>
      '.novel_agent/information/design_elements/index.json';

  String designElementPath(String designId) {
    return '.novel_agent/information/design_elements/${_safeId(designId, fallback: 'design_element')}.json';
  }

  String designElementLocator(String designId) {
    return _sourceOfTruthLocatorService.entryLocator(
      InformationSourceOfTruthCollections.designElements,
      _safeId(designId, fallback: 'design_element'),
    );
  }

  String researchNotesIndexPath() =>
      '.novel_agent/information/research_notes/index.json';

  String researchNotePath(String researchId) {
    return '.novel_agent/information/research_notes/${_safeId(researchId, fallback: 'research_note')}.json';
  }

  String researchNoteLocator(String researchId) {
    return _sourceOfTruthLocatorService.entryLocator(
      InformationSourceOfTruthCollections.researchNotes,
      _safeId(researchId, fallback: 'research_note'),
    );
  }

  String researchRequestsIndexPath() =>
      '.novel_agent/information/research_requests/index.json';

  String researchRequestPath(String requestId) {
    return '.novel_agent/information/research_requests/${_safeId(requestId, fallback: 'research_request')}.json';
  }

  String referenceWorksIndexPath() =>
      '.novel_agent/information/reference_works/index.json';

  String referenceWorkPath(String referenceWorkId) {
    return '.novel_agent/information/reference_works/${_safeId(referenceWorkId, fallback: 'reference_work')}.json';
  }

  String referenceWorkLocator(String referenceWorkId) {
    return _sourceOfTruthLocatorService.entryLocator(
      InformationSourceOfTruthCollections.referenceWorks,
      _safeId(referenceWorkId, fallback: 'reference_work'),
    );
  }

  String informationLinksLogPath() =>
      '.novel_agent/information/links/links.jsonl';

  String informationEventsLogPath() =>
      '.novel_agent/information/events/events.jsonl';

  String _safeId(String value, {required String fallback}) {
    // 中文注释: 信息层路径继续复用统一文件名清洗规则，避免和 ONS 在同一项目里长出两套命名口径。
    return _toolPathPolicy.safeFileName(value, fallback: fallback);
  }
}
