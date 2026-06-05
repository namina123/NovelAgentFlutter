import '../tools/project_tool_path_policy.dart';

class ProjectInformationPathService {
  ProjectInformationPathService({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String knowledgeCardsIndexPath() =>
      '.novel_agent/information/knowledge_cards/index.json';

  String knowledgeCardPath(String cardId) {
    return '.novel_agent/information/knowledge_cards/${_safeId(cardId, fallback: 'knowledge_card')}.json';
  }

  String designElementsIndexPath() =>
      '.novel_agent/information/design_elements/index.json';

  String designElementPath(String designId) {
    return '.novel_agent/information/design_elements/${_safeId(designId, fallback: 'design_element')}.json';
  }

  String researchNotesIndexPath() =>
      '.novel_agent/information/research_notes/index.json';

  String researchNotePath(String researchId) {
    return '.novel_agent/information/research_notes/${_safeId(researchId, fallback: 'research_note')}.json';
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

  String informationLinksLogPath() =>
      '.novel_agent/information/links/links.jsonl';

  String informationEventsLogPath() =>
      '.novel_agent/information/events/events.jsonl';

  String _safeId(String value, {required String fallback}) {
    // 中文注释: 信息层路径继续复用统一文件名清洗规则，避免和 ONS 在同一项目里长出两套命名口径。
    return _toolPathPolicy.safeFileName(value, fallback: fallback);
  }
}
