import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RAG contracts', () {
    test('exposes model-assisted source and strategy kinds', () {
      expect(RagSourceKinds.txt, 'txt');
      expect(RagSourceKinds.md, 'md');
      expect(RagSourceKinds.epub, 'epub');
      expect(RagSourceKinds.folder, 'folder');
      expect(RagNormalizationStrategyKinds.ruleBased, 'rule_based');
      expect(RagNormalizationStrategyKinds.modelAssisted, 'model_assisted');
      expect(RagNormalizationStrategyKinds.hybrid, 'hybrid');
      expect(RagSegmentationStrategyKinds.ruleChapter, 'rule_chapter');
      expect(RagSegmentationStrategyKinds.modelChapter, 'model_chapter');
      expect(RagSegmentationStrategyKinds.hybridChapter, 'hybrid_chapter');
      expect(RagChunkStrategyKinds.defaultOverlap, 'default_overlap');
      expect(RagChunkStrategyKinds.chapterAligned, 'chapter_aligned');
      expect(RagChunkStrategyKinds.segmentAligned, 'segment_aligned');
      expect(RagBuildModes.basic, 'basic');
      expect(RagBuildModes.modelAssisted, 'model_assisted');
      expect(RagBuildModes.hybrid, 'hybrid');
    });

    test('round-trips corpus, source, chunk and mount metadata', () {
      final corpus = RagCorpusPackage.fromJson(<String, Object?>{
        'corpus_id': 'corpus-001',
        'title': '基础 txt 语料包',
        'description': '第一阶段 txt 模式的最小语料包。',
        'source_kind': 'txt',
        'language': 'zh-CN',
        'build_mode': 'basic',
        'segmentation_strategy': 'rule_chapter',
        'chunk_strategy': 'default_overlap',
        'embedding_backend': 'placeholder-local',
        'index_backend': 'sqlite-meta',
        'version': 'v1',
        'created_at': '2026-06-17T00:00:00Z',
        'updated_at': '2026-06-17T00:00:00Z',
        'source_count': 1,
        'chapter_count': 3,
        'chunk_count': 12,
        'is_model_assisted': false,
        'capability_flags': <Object?>['mountable', 'retrievable'],
        'future_extension': <String, Object?>{'keep': true},
      });
      final source = RagSourceDocument.fromJson(<String, Object?>{
        'source_document_id': 'source-001',
        'corpus_id': 'corpus-001',
        'source_kind': 'txt',
        'display_name': '样本文本',
        'origin_path': 'inputs/sample.txt',
        'origin_format': 'txt',
        'language': 'zh-CN',
        'content_hash': 'hash-001',
      });
      final chunk = RagChunk.fromJson(<String, Object?>{
        'chunk_id': 'chunk-001',
        'corpus_id': 'corpus-001',
        'source_document_id': 'source-001',
        'chapter_index': 1,
        'chapter_title': '第一章',
        'segment_index': 2,
        'text': '第一段原文。',
        'normalized_text': '第一段原文。',
        'token_estimate': 18,
        'range_start': 0,
        'range_end': 18,
      });
      final indexHandle = RagIndexHandle.fromJson(<String, Object?>{
        'index_handle_id': 'index-001',
        'corpus_id': 'corpus-001',
        'backend_kind': 'placeholder-local',
        'backend_location': 'local/index.db',
        'embedding_dimension': 768,
        'status': 'ready',
        'version': 'v1',
        'last_built_at': '2026-06-17T00:00:00Z',
      });
      final binding = RetrievalMountBinding.fromJson(<String, Object?>{
        'binding_id': 'binding-001',
        'project_id': 'project-001',
        'corpus_id': 'corpus-001',
        'mount_scope': 'project',
        'priority': 10,
        'usage_policy': 'reference_only',
        'activation_policy': 'required',
        'created_at': '2026-06-17T00:00:00Z',
      });

      expect(corpus.validateBasics(), isEmpty);
      expect(source.validateBasics(), isEmpty);
      expect(chunk.validateBasics(), isEmpty);
      expect(indexHandle.validateBasics(), isEmpty);
      expect(binding.validateBasics(), isEmpty);
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(corpus.toJson()['future_extension'])['keep'],
        ),
        isTrue,
      );
      expect(corpus.capabilityFlags, containsAll(<String>['mountable', 'retrievable']));
      expect(chunk.chapterTitle, '第一章');
      expect(indexHandle.backendKind, 'placeholder-local');
      expect(binding.projectId, 'project-001');
    });

    test('round-trips normalization, segmentation, chunk build and ingestion results', () {
      final sourceDocument = RagSourceDocument.fromJson(<String, Object?>{
        'source_document_id': 'source-002',
        'corpus_id': 'corpus-002',
        'source_kind': 'epub',
        'display_name': '复杂格式样本',
        'origin_path': 'inputs/book.epub',
        'origin_format': 'epub',
        'language': 'zh-CN',
        'content_hash': 'hash-002',
      });
      final normalizedSource = RagNormalizedSource.fromJson(<String, Object?>{
        'normalized_source_id': 'normalized-001',
        'corpus_id': 'corpus-002',
        'source_document_id': 'source-002',
        'source_kind': 'epub',
        'normalization_strategy': 'model_assisted',
        'used_model': true,
        'normalized_units': <Object?>[
          <String, Object?>{
            'unit_id': 'unit-001',
            'normalized_text': '第一章 正文。',
            'raw_text': '第1章\n第一章 正文。',
            'unit_kind': 'chapter_body',
            'source_offset_start': 0,
            'source_offset_end': 12,
            'confidence': 0.91,
          },
        ],
        'discarded_units': <Object?>[
          <String, Object?>{
            'unit_id': 'discarded-001',
            'raw_text': '版权页',
            'discard_reason': 'front_matter',
            'strategy_id': 'model_assisted',
          },
        ],
        'uncertain_units': <Object?>[
          <String, Object?>{
            'unit_id': 'uncertain-001',
            'raw_text': '目录页',
            'uncertainty_reason': 'possible_table_of_contents',
            'confidence': 0.4,
            'strategy_id': 'model_assisted',
          },
        ],
        'notes': '模型辅助标准化保留了正文单元。',
      });
      final segmentationResult = RagSegmentationResult.fromJson(<String, Object?>{
        'segmentation_result_id': 'segmentation-001',
        'corpus_id': 'corpus-002',
        'source_document_id': 'source-002',
        'source_kind': 'epub',
        'segmentation_strategy': 'model_chapter',
        'used_model': true,
        'segments': <Object?>[
          <String, Object?>{
            'segment_id': 'segment-001',
            'source_document_id': 'source-002',
            'source_kind': 'epub',
            'segment_index': 1,
            'chapter_index': 1,
            'chapter_title': '第一章',
            'start_unit_index': 0,
            'end_unit_index': 0,
            'text': '第一章 正文。',
            'normalized_text': '第一章 正文。',
            'source_unit_ids': <Object?>['unit-001'],
            'has_model_assistance': true,
            'notes': '章节边界由模型辅助确认。',
          },
        ],
        'warnings': <Object?>['章节前言页需要人工复核。'],
      });
      final chunkBuildResult = RagChunkBuildResult.fromJson(<String, Object?>{
        'chunk_build_result_id': 'chunk-build-001',
        'corpus_id': 'corpus-002',
        'source_document_id': 'source-002',
        'chunk_strategy': 'chapter_aligned',
        'chunks': <Object?>[
          <String, Object?>{
            'chunk_id': 'chunk-002',
            'corpus_id': 'corpus-002',
            'source_document_id': 'source-002',
            'chapter_index': 1,
            'chapter_title': '第一章',
            'segment_index': 1,
            'text': '第一章 正文。',
            'normalized_text': '第一章 正文。',
            'token_estimate': 12,
            'range_start': 0,
            'range_end': 12,
          },
        ],
        'warnings': <Object?>['chunk 切分策略与章节边界保持对齐。'],
      });
      final ingestionResult = RagIngestionResult.fromJson(<String, Object?>{
        'ingestion_result_id': 'ingestion-001',
        'corpus_package': <String, Object?>{
          'corpus_id': 'corpus-002',
          'title': '模型辅助语料包',
          'source_kind': 'epub',
          'build_mode': 'model_assisted',
          'is_model_assisted': true,
        },
        'normalized_sources': <Object?>[normalizedSource.toJson()],
        'segmentation_results': <Object?>[segmentationResult.toJson()],
        'chunk_build_results': <Object?>[chunkBuildResult.toJson()],
        'warnings': <Object?>['统一 ingestion 结果需要宿主消费摘要。'],
        'notes': '整条链路可回放。',
      });

      expect(sourceDocument.validateBasics(), isEmpty);
      expect(normalizedSource.validateBasics(), isEmpty);
      expect(segmentationResult.validateBasics(), isEmpty);
      expect(chunkBuildResult.validateBasics(), isEmpty);
      expect(ingestionResult.validateBasics(), isEmpty);
      expect(normalizedSource.usedModel, isTrue);
      expect(normalizedSource.normalizedUnits, hasLength(1));
      expect(normalizedSource.discardedUnits.single.discardReason, 'front_matter');
      expect(segmentationResult.segments.single.hasModelAssistance, isTrue);
      expect(chunkBuildResult.chunks.single.chunkId, 'chunk-002');
      expect(ingestionResult.normalizedUnitCount, 1);
      expect(ingestionResult.discardedUnitCount, 1);
      expect(ingestionResult.uncertainUnitCount, 1);
      expect(ingestionResult.segmentCount, 1);
      expect(ingestionResult.chunkCount, 1);
      expect(ingestionResult.toJson()['corpus_package'], isA<Map<String, Object?>>());
    });

    test('round-trips retrieval query, hit and activation package', () {
      final query = RetrievalQuery.fromJson(<String, Object?>{
        'query_id': 'query-001',
        'query_text': '镜面意象如何影响身份认知',
        'project_id': 'project-001',
        'corpus_filters': <Object?>['corpus-001'],
        'source_filters': <Object?>['source-001'],
        'language': 'zh-CN',
        'top_k': 8,
        'query_mode': 'evidence',
        'rerank_policy': 'basic',
        'evidence_budget': 3,
      });
      final hit = RetrievalHit.fromJson(<String, Object?>{
        'hit_id': 'hit-001',
        'corpus_id': 'corpus-001',
        'source_document_id': 'source-001',
        'score': 0.92,
        'rerank_score': 0.88,
        'excerpt': '镜面总在角色迟疑时映出另一种身份。',
        'range_start': 120,
        'range_end': 156,
        'chapter_title': '第二章',
        'evidence_path': 'chapters/02#L120-L156',
      });
      final activation = RetrievalActivationPackage.fromJson(<String, Object?>{
        'activation_package_id': 'activation-001',
        'query_summary': '身份认知的镜面证据召回',
        'selected_hits': <Object?>[hit.toJson()],
        'source_summaries': <Object?>['source-001: 样本文本'],
        'warning_notes': <Object?>['召回结果需要与结构化知识层复核。'],
        'citation_paths': <Object?>['chapters/02#L120-L156'],
      });

      expect(query.validateBasics(), isEmpty);
      expect(hit.validateBasics(), isEmpty);
      expect(activation.validateBasics(), isEmpty);
      expect(query.topK, 8);
      expect(hit.score, closeTo(0.92, 0.0001));
      expect(activation.selectedHits, hasLength(1));
      expect(activation.citationPaths.single, 'chapters/02#L120-L156');
    });

    test('validator reports missing core identity fields', () {
      final corpus = RagCorpusPackage.fromJson(<String, Object?>{
        'corpus_id': '',
        'title': '',
        'source_kind': '',
        'build_mode': '',
      });
      final source = RagSourceDocument.fromJson(<String, Object?>{
        'source_document_id': '',
        'corpus_id': '',
        'source_kind': '',
        'display_name': '',
        'origin_path': '',
      });
      final chunk = RagChunk.fromJson(<String, Object?>{
        'chunk_id': '',
        'corpus_id': '',
        'source_document_id': '',
        'text': '',
      });
      final indexHandle = RagIndexHandle.fromJson(<String, Object?>{
        'index_handle_id': '',
        'corpus_id': '',
      });
      final binding = RetrievalMountBinding.fromJson(<String, Object?>{
        'binding_id': '',
        'project_id': '',
        'corpus_id': '',
      });
      final query = RetrievalQuery.fromJson(<String, Object?>{
        'query_id': '',
        'query_text': '',
      });
      final hit = RetrievalHit.fromJson(<String, Object?>{
        'hit_id': '',
        'corpus_id': '',
        'source_document_id': '',
      });
      final activation = RetrievalActivationPackage.fromJson(<String, Object?>{
        'activation_package_id': '',
        'query_summary': '',
      });

      expect(
        corpus.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRagCorpusId,
          RagValidationCodes.missingRagCorpusTitle,
          RagValidationCodes.missingRagCorpusSourceKind,
          RagValidationCodes.missingRagCorpusBuildMode,
        ]),
      );
      expect(
        source.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRagSourceDocumentId,
          RagValidationCodes.missingRagSourceDocumentDisplayName,
          RagValidationCodes.missingRagSourceDocumentOriginPath,
        ]),
      );
      expect(
        chunk.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRagChunkId,
          RagValidationCodes.missingRagChunkCorpusId,
          RagValidationCodes.missingRagChunkSourceDocumentId,
        ]),
      );
      expect(
        indexHandle.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRagIndexHandleId,
          RagValidationCodes.missingRagIndexHandleCorpusId,
        ]),
      );
      expect(
        binding.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRetrievalMountBindingId,
          RagValidationCodes.missingRetrievalMountBindingProjectId,
          RagValidationCodes.missingRetrievalMountBindingCorpusId,
        ]),
      );
      expect(
        query.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRetrievalQueryId,
          RagValidationCodes.missingRetrievalQueryText,
        ]),
      );
      expect(
        hit.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRetrievalHitId,
          RagValidationCodes.missingRetrievalHitCorpusId,
          RagValidationCodes.missingRetrievalHitSourceDocumentId,
        ]),
      );
      expect(
        activation.validateBasics(),
        containsAll(<String>[
          RagValidationCodes.missingRetrievalActivationPackageId,
          RagValidationCodes.missingRetrievalActivationPackageQuerySummary,
        ]),
      );
    });
  });
}
