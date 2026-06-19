import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('rag parallel branch regression suite', () {
    test(
      'covers txt ingestion, mount summary, retrieval hits and retrieval activation package using production truth contracts',
      () async {
        final report = await _runRagParallelBranchRegressionSuite();
        final summary = ValueReaders.mapValue(report['summary']);
        final scenarios = ValueReaders.mapList(report['scenarios'])
            .map(ValueReaders.mapValue)
            .toList(growable: false);

        expect(ValueReaders.intValue(summary['total_scenarios']), 4);
        expect(ValueReaders.intValue(summary['passed_scenarios']), 4);
        expect(ValueReaders.boolValue(summary['all_required_coverage_passed']), isTrue);
        expect(
          scenarios.map((scenario) => ValueReaders.stringValue(scenario['id'])),
          containsAll(const <String>[
            'txt_ingestion',
            'mount_summary',
            'retrieval_hits',
            'retrieval_activation_package',
          ]),
        );
      },
    );
  });
}

Future<JsonMap> _runRagParallelBranchRegressionSuite() async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'rag_parallel_branch_regression_suite_',
  );
  final project = ProjectDescriptor(
    id: 'project-rag-regression-1',
    name: 'RAG regression 项目',
    rootPath: tempDirectory.path,
    storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
  );
  final repository = SqliteRagMetadataRepository();
  final ingestionService = RagTxtCorpusIngestionService(
    metadataRepository: repository,
  );
  final mountSummaryService = RagProjectMountSummaryService(
    metadataRepository: repository,
  );
  final retrievalExecutor = ProjectRagRetrievalToolExecutor(
    metadataRepository: repository,
    mountSummaryService: mountSummaryService,
  );
  final activationBridge = ProjectRagRetrievalActivationBridgeService();

  try {
    final sourceFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}sample.txt',
    );
    await sourceFile.writeAsString('''
第一章
镜潮回扣在这一章里反复出现。

第二章
钟声把回声压回墙壁，人物开始意识到循环。
''');

    final corpus = await ingestionService.ingestFile(
      project: project,
      sourceFilePath: sourceFile.path,
      corpusPackage: const RagCorpusPackage(
        corpusId: 'corpus-rag-regression-1',
        title: 'RAG regression 语料',
        sourceKind: 'txt',
        buildMode: 'basic',
        language: 'zh-CN',
        version: 'v1',
      ),
      ingestedAt: '2026-06-18T08:00:00Z',
    );
    await repository.upsertMountBinding(
      project,
      RetrievalMountBinding(
        bindingId: 'binding-rag-regression-1',
        projectId: project.id,
        corpusId: corpus.corpusId,
        mountScope: 'project',
        priority: 100,
        usagePolicy: 'reference_only',
        activationPolicy: 'required',
        createdAt: '2026-06-18T08:00:00Z',
      ),
    );

    final mountSummary = await mountSummaryService.summarize(project);
    final retrieval = await retrievalExecutor.retrievePassages(
      project,
      <String, Object?>{
        'query_id': 'query-rag-regression-1',
        'query_text': '镜潮回扣',
        'project_id': project.id,
        'corpus_filters': <Object?>[corpus.corpusId],
        'top_k': 5,
      },
    );
    final activationPackage = activationBridge.buildPackage(project, retrieval);

    final scenarios = <JsonMap>[
      _scenario(
        id: 'txt_ingestion',
        passed: corpus.corpusId == 'corpus-rag-regression-1' &&
            corpus.chunkCount > 0,
        coveredRequirements: const <String>[
          'txt_ingestion',
        ],
        details: <String, Object?>{
          'corpus_id': corpus.corpusId,
          'chunk_count': corpus.chunkCount,
        },
      ),
      _scenario(
        id: 'mount_summary',
        passed: mountSummary.bindingCount == 1 &&
            mountSummary.corpusIds.contains(corpus.corpusId),
        coveredRequirements: const <String>[
          'mount_summary',
        ],
        details: mountSummary.toJson(),
      ),
      _scenario(
        id: 'retrieval_hits',
        passed: ValueReaders.boolValue(retrieval['ok']) &&
            ValueReaders.mapList(retrieval['retrieval_hits']).isNotEmpty,
        coveredRequirements: const <String>[
          'retrieval_hits',
        ],
        details: <String, Object?>{
          'retrieval_hits': ValueReaders.mapList(retrieval['retrieval_hits']),
          'citation_paths': ValueReaders.stringList(retrieval['citation_paths']),
        },
      ),
      _scenario(
        id: 'retrieval_activation_package',
        passed: activationPackage.selectedHits.isNotEmpty &&
            activationPackage.activationPackageId ==
                'rag_activation:project-rag-regression-1:query-rag-regression-1' &&
            activationPackage.citationPaths.isNotEmpty,
        coveredRequirements: const <String>[
          'retrieval_activation_package',
        ],
        details: activationPackage.toJson(),
      ),
    ];

    final requirements = <String, bool>{
      'txt_ingestion': false,
      'mount_summary': false,
      'retrieval_hits': false,
      'retrieval_activation_package': false,
    };
    for (final scenario in scenarios) {
      if (!ValueReaders.boolValue(scenario['passed'])) {
        continue;
      }
      for (final requirement in ValueReaders.stringList(
        scenario['covered_requirements'],
      )) {
        if (requirements.containsKey(requirement)) {
          requirements[requirement] = true;
        }
      }
    }

    return <String, Object?>{
      'summary': <String, Object?>{
        'total_scenarios': scenarios.length,
        'passed_scenarios': scenarios.where(
          (scenario) => ValueReaders.boolValue(scenario['passed']),
        ).length,
        'all_required_coverage_passed': requirements.values.every(
          (value) => value,
        ),
        'required_coverage': requirements.entries
            .map(
              (entry) => <String, Object?>{
                'requirement': entry.key,
                'passed': entry.value,
              },
            )
            .toList(growable: false),
      },
      'scenarios': scenarios,
    };
  } finally {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

JsonMap _scenario({
  required String id,
  required bool passed,
  required List<String> coveredRequirements,
  required JsonMap details,
}) {
  return <String, Object?>{
    'id': id,
    'passed': passed,
    'covered_requirements': coveredRequirements,
    'details': details,
  };
}
