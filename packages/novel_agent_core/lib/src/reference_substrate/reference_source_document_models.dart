import 'reference_package_models.dart';

class ReferenceSourceDocumentIngestionRequest {
  const ReferenceSourceDocumentIngestionRequest({
    required this.sourceText,
    required this.sourceTitle,
    required this.packageId,
    required this.packageKind,
    required this.displayName,
    required this.packageVersionId,
    required this.versionLabel,
    required this.createdAt,
    this.packageNamespace = '',
    this.sourceRef = '',
    this.createdBy = '',
    this.sourceLanguage = '',
    this.targetLanguage = 'zh-CN',
    this.sourceSummary = '',
    this.licenseSummary = '',
    this.maxChapterEntries = 6,
    this.maxEntityEntries = 6,
  });

  final String sourceText;
  final String sourceTitle;
  final String sourceRef;
  final String packageId;
  final String packageKind;
  final String displayName;
  final String packageNamespace;
  final String packageVersionId;
  final String versionLabel;
  final String createdAt;
  final String createdBy;
  final String sourceLanguage;
  final String targetLanguage;
  final String sourceSummary;
  final String licenseSummary;
  final int maxChapterEntries;
  final int maxEntityEntries;
}

abstract final class ReferenceSourceDocumentStructureKinds {
  static const String explicitChapter = 'explicit_chapter';
  static const String paragraphCluster = 'paragraph_cluster';
}

class ReferenceSourceDocumentSection {
  const ReferenceSourceDocumentSection({
    required this.sectionId,
    required this.sectionIndex,
    required this.heading,
    required this.content,
    required this.keywords,
    required this.startOffset,
    required this.endOffset,
    this.structureKind = ReferenceSourceDocumentStructureKinds.explicitChapter,
    this.synthetic = false,
    this.parentSectionId = '',
  });

  final String sectionId;
  final int sectionIndex;
  final String heading;
  final String content;
  final List<String> keywords;
  final int startOffset;
  final int endOffset;
  final String structureKind;
  final bool synthetic;
  final String parentSectionId;

  int get charCount => content.length;
}

class ReferenceSourceDocumentStructure {
  const ReferenceSourceDocumentStructure({
    required this.sourceTextLength,
    required this.structureKind,
    required this.sections,
  });

  final int sourceTextLength;
  final String structureKind;
  final List<ReferenceSourceDocumentSection> sections;
}

class ReferenceSourceDocumentIngestionResult {
  const ReferenceSourceDocumentIngestionResult({
    required this.packageId,
    required this.packageVersionId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.generatedEntryCount,
    required this.snapshot,
  });

  final String packageId;
  final String packageVersionId;
  final String sourceLanguage;
  final String targetLanguage;
  final int generatedEntryCount;
  final ReferencePackageSnapshot snapshot;
}
