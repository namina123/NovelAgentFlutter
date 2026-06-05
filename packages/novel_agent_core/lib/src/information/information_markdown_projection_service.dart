import 'dart:convert';

import '../packages/frontmatter_yaml_writer_service.dart';
import 'design_element_card.dart';
import 'information_projection_document.dart';
import 'information_projection_source.dart';
import 'project_knowledge_card.dart';
import 'reference_work_record.dart';
import 'research_note.dart';

class InformationMarkdownProjectionService {
  InformationMarkdownProjectionService({
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  static const String knowledgeReferenceBlockId =
      'project_knowledge_references';
  static const String knowledgeDraftBlockId = 'project_knowledge_drafts';
  static const String designReferenceBlockId = 'design_element_references';
  static const String designDraftBlockId = 'design_element_drafts';
  static const String researchReferenceBlockId = 'research_note_references';
  static const String researchDraftBlockId = 'research_note_drafts';
  static const String referenceWorkReferenceBlockId =
      'reference_work_references';
  static const String referenceWorkDraftBlockId = 'reference_work_drafts';

  final FrontmatterYamlWriterService _yamlWriterService;

  List<InformationProjectionDocument> buildDocuments(
    InformationProjectionSource source,
  ) {
    return <InformationProjectionDocument>[
      _buildKnowledgeDocument(source),
      _buildDesignDocument(source),
      _buildResearchDocument(source),
      _buildReferenceDocument(source),
    ];
  }

  InformationProjectionDocument _buildKnowledgeDocument(
    InformationProjectionSource source,
  ) {
    final cards = [...source.knowledgeCards]..sort(_compareKnowledgeCards);
    final lines = <String>[
      _frontmatter(
        projectionId:
            InformationProjectionDocument.knowledgeSummaryProjectionId,
        title: '项目知识摘要',
        sourceOfTruthPaths: <String>[
          '.novel_agent/information/knowledge_cards/*.json',
        ],
        editableDraftBlocks: <String>[knowledgeDraftBlockId],
      ),
      '# 项目知识摘要',
      '',
      '> 这份 Markdown 只是结构化信息事实源的可读投影，不是运行时真相。',
      '> 用户编辑只能通过文末 knowledge draft block 回流为结构化 proposal draft，不能直接覆盖隐藏 JSON 事实源。',
      '',
      '## 当前摘要概览',
      '',
      '- 当前知识卡数：${cards.length}',
      '- 事实源位置：`.novel_agent/information/knowledge_cards/*.json`',
      '- 删除这份投影不会删除底层结构化事实源。',
      '',
      '## 当前知识卡明细',
      '',
    ];
    if (cards.isEmpty) {
      lines.add('- 暂无已记录知识卡。');
    } else {
      for (final card in cards) {
        lines.addAll(_knowledgeSummary(card));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          knowledgeReferenceBlockId,
          cards.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Knowledge Proposal Draft')
      ..add('')
      ..add(_jsonBlock(knowledgeDraftBlockId, const <Object?>[]));
    return InformationProjectionDocument(
      projectionId: InformationProjectionDocument.knowledgeSummaryProjectionId,
      relativePath: InformationProjectionDocument.knowledgeSummaryRelativePath,
      title: '项目知识摘要',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  InformationProjectionDocument _buildDesignDocument(
    InformationProjectionSource source,
  ) {
    final cards = [...source.designElements]..sort(_compareDesignElements);
    final lines = <String>[
      _frontmatter(
        projectionId: InformationProjectionDocument.designSummaryProjectionId,
        title: '设计元素摘要',
        sourceOfTruthPaths: <String>[
          '.novel_agent/information/design_elements/*.json',
        ],
        editableDraftBlocks: <String>[designDraftBlockId],
      ),
      '# 设计元素摘要',
      '',
      '> 这份 Markdown 只投影当前设计元素卡，方便人工浏览、对照和补充草案。',
      '> 如需修订，请在文末 design draft block 中提交结构化 proposal draft，不要把 Markdown 当成事实源。',
      '',
      '## 当前摘要概览',
      '',
      '- 当前设计元素数：${cards.length}',
      '- 事实源位置：`.novel_agent/information/design_elements/*.json`',
      '- 删除这份投影不会删除底层结构化事实源。',
      '',
      '## 当前设计元素明细',
      '',
    ];
    if (cards.isEmpty) {
      lines.add('- 暂无已记录设计元素。');
    } else {
      for (final card in cards) {
        lines.addAll(_designSummary(card));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          designReferenceBlockId,
          cards.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Design Proposal Draft')
      ..add('')
      ..add(_jsonBlock(designDraftBlockId, const <Object?>[]));
    return InformationProjectionDocument(
      projectionId: InformationProjectionDocument.designSummaryProjectionId,
      relativePath: InformationProjectionDocument.designSummaryRelativePath,
      title: '设计元素摘要',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  InformationProjectionDocument _buildResearchDocument(
    InformationProjectionSource source,
  ) {
    final notes = [...source.researchNotes]..sort(_compareResearchNotes);
    final lines = <String>[
      _frontmatter(
        projectionId: InformationProjectionDocument.researchSummaryProjectionId,
        title: '资料研究摘要',
        sourceOfTruthPaths: <String>[
          '.novel_agent/information/research_notes/*.json',
        ],
        editableDraftBlocks: <String>[researchDraftBlockId],
      ),
      '# 资料研究摘要',
      '',
      '> 这份 Markdown 只用于浏览当前研究笔记，不会替代底层研究记录。',
      '> 如需人工补充，请在文末 research draft block 中提交结构化草案，不能直接改写隐藏事实源。',
      '',
      '## 当前摘要概览',
      '',
      '- 当前研究笔记数：${notes.length}',
      '- 事实源位置：`.novel_agent/information/research_notes/*.json`',
      '- 删除这份投影不会删除底层结构化事实源。',
      '',
      '## 当前研究笔记明细',
      '',
    ];
    if (notes.isEmpty) {
      lines.add('- 暂无已记录研究笔记。');
    } else {
      for (final note in notes) {
        lines.addAll(_researchSummary(note));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          researchReferenceBlockId,
          notes.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Research Proposal Draft')
      ..add('')
      ..add(_jsonBlock(researchDraftBlockId, const <Object?>[]));
    return InformationProjectionDocument(
      projectionId: InformationProjectionDocument.researchSummaryProjectionId,
      relativePath: InformationProjectionDocument.researchSummaryRelativePath,
      title: '资料研究摘要',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  InformationProjectionDocument _buildReferenceDocument(
    InformationProjectionSource source,
  ) {
    final works = [...source.referenceWorks]..sort(_compareReferenceWorks);
    final lines = <String>[
      _frontmatter(
        projectionId:
            InformationProjectionDocument.referenceBoundaryProjectionId,
        title: '引用作品边界',
        sourceOfTruthPaths: <String>[
          '.novel_agent/information/reference_works/*.json',
        ],
        editableDraftBlocks: <String>[referenceWorkDraftBlockId],
      ),
      '# 引用作品边界',
      '',
      '> 这份 Markdown 只投影当前引用作品边界与使用意图，方便人工核对风险。',
      '> 若要修订边界，请在文末 reference work draft block 中提交结构化草案，不能直接改写隐藏事实源。',
      '',
      '## 当前摘要概览',
      '',
      '- 当前引用作品记录数：${works.length}',
      '- 事实源位置：`.novel_agent/information/reference_works/*.json`',
      '- 删除这份投影不会删除底层结构化事实源。',
      '',
      '## 当前引用作品明细',
      '',
    ];
    if (works.isEmpty) {
      lines.add('- 暂无已记录引用作品边界。');
    } else {
      for (final work in works) {
        lines.addAll(_referenceSummary(work));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          referenceWorkReferenceBlockId,
          works.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Reference Work Proposal Draft')
      ..add('')
      ..add(_jsonBlock(referenceWorkDraftBlockId, const <Object?>[]));
    return InformationProjectionDocument(
      projectionId: InformationProjectionDocument.referenceBoundaryProjectionId,
      relativePath: InformationProjectionDocument.referenceBoundaryRelativePath,
      title: '引用作品边界',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  List<String> _knowledgeSummary(ProjectKnowledgeCard card) {
    return <String>[
      '### ${card.title.trim().isEmpty ? card.cardId : card.title}',
      '',
      '- Card ID：`${card.cardId}`',
      '- Namespace：`${card.cardNamespace}`',
      '- Card Type：`${card.cardType}`',
      '- 生命周期：`${card.lifecycleStatus}`',
      '- 置信度：${card.confidence}',
      '- 激活优先级：`${card.activationPolicy.activationPriority}`',
      '- 使用模式：`${card.usagePolicy.usageMode}`',
      '- 来源：${_joinedSourceLabels(card.sourceRefs)}',
      '- 摘要：${card.summary.trim().isEmpty ? '无' : card.summary}',
      '- Payload：`${jsonEncode(card.contentPayload)}`',
      '',
    ];
  }

  List<String> _designSummary(DesignElementCard card) {
    return <String>[
      '### ${card.designLabel.trim().isEmpty ? card.designId : card.designLabel}',
      '',
      '- Design ID：`${card.designId}`',
      '- Namespace：`${card.designNamespace}`',
      '- 生命周期：`${card.lifecycleStatus}`',
      '- 置信度：${card.confidence}',
      '- 不确定性：${card.uncertainty.trim().isEmpty ? '无' : card.uncertainty}',
      '- 激活优先级：`${card.activationPolicy.activationPriority}`',
      '- 使用模式：`${card.usagePolicy.usageMode}`',
      '- 来源：${_joinedSourceLabels(card.sourceRefs)}',
      '- Linked Refs：${card.linkedRefs.length}',
      '- Payload：`${jsonEncode(card.designPayload)}`',
      '',
    ];
  }

  List<String> _researchSummary(ResearchNote note) {
    return <String>[
      '### ${note.query.trim().isEmpty ? note.researchId : note.query}',
      '',
      '- Research ID：`${note.researchId}`',
      '- Source Kind：`${note.sourceKind}`',
      '- Source Ref：`${note.sourceUrlOrRef}`',
      '- Citation：${note.citation.trim().isEmpty ? '无' : note.citation}',
      '- 使用模式：`${note.usagePolicy.usageMode}`',
      '- 可用事实数：${note.usableFacts.length}',
      '- 创作建议数：${note.creativeSuggestions.length}',
      '- 创建者：`${note.createdBy}`',
      '- 不确定性：${note.uncertainty.trim().isEmpty ? '无' : note.uncertainty}',
      '- 摘要：${note.summary.trim().isEmpty ? '无' : note.summary}',
      '',
    ];
  }

  List<String> _referenceSummary(ReferenceWorkRecord record) {
    return <String>[
      '### ${record.title.trim().isEmpty ? record.referenceWorkId : record.title}',
      '',
      '- Reference Work ID：`${record.referenceWorkId}`',
      '- Creator：${record.creator.trim().isEmpty ? '未记录' : record.creator}',
      '- Version：${record.version.trim().isEmpty ? '未记录' : record.version}',
      '- Relationship：`${record.relationshipToProject}`',
      '- Declared Usage Intent：${record.declaredUsageIntent}',
      '- Allowed Usage Summary：${record.allowedUsageSummary.trim().isEmpty ? '无' : record.allowedUsageSummary}',
      '- Requires Confirmation：${record.requiresConfirmation}',
      '- 风险记录数：${record.riskNotes.length}',
      '- 来源：${_joinedSourceLabels(record.sourceRefs)}',
      '',
    ];
  }

  String _joinedSourceLabels(Iterable<dynamic> sourceRefs) {
    final labels = sourceRefs
        .map((entry) {
          final dynamic ref = entry;
          final sourceRef = ref.sourceRef;
          return '`${sourceRef.sourceType}` / `${sourceRef.sourceId}`';
        })
        .toList(growable: false);
    return labels.isEmpty ? '无' : labels.join('；');
  }

  String _frontmatter({
    required String projectionId,
    required String title,
    required List<String> sourceOfTruthPaths,
    required List<String> editableDraftBlocks,
  }) {
    return '---\n${_yamlWriterService.write(<String, Object?>{'projection_id': projectionId, 'title': title, 'projection_only': true, 'source_of_truth_paths': sourceOfTruthPaths, 'editable_draft_blocks': editableDraftBlocks})}\n---\n';
  }

  String _jsonBlock(String blockId, Object value) {
    return '```json $blockId\n${const JsonEncoder.withIndent('  ').convert(value)}\n```';
  }

  int _compareKnowledgeCards(
    ProjectKnowledgeCard left,
    ProjectKnowledgeCard right,
  ) {
    final namespaceCompare = left.cardNamespace.compareTo(right.cardNamespace);
    if (namespaceCompare != 0) {
      return namespaceCompare;
    }
    return left.cardId.compareTo(right.cardId);
  }

  int _compareDesignElements(DesignElementCard left, DesignElementCard right) {
    final namespaceCompare = left.designNamespace.compareTo(
      right.designNamespace,
    );
    if (namespaceCompare != 0) {
      return namespaceCompare;
    }
    return left.designId.compareTo(right.designId);
  }

  int _compareResearchNotes(ResearchNote left, ResearchNote right) {
    final sourceCompare = left.sourceKind.compareTo(right.sourceKind);
    if (sourceCompare != 0) {
      return sourceCompare;
    }
    return left.researchId.compareTo(right.researchId);
  }

  int _compareReferenceWorks(
    ReferenceWorkRecord left,
    ReferenceWorkRecord right,
  ) {
    final relationCompare = left.relationshipToProject.compareTo(
      right.relationshipToProject,
    );
    if (relationCompare != 0) {
      return relationCompare;
    }
    return left.referenceWorkId.compareTo(right.referenceWorkId);
  }
}
