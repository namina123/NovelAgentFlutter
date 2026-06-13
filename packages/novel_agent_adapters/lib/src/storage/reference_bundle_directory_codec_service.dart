import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class ReferenceBundleDirectoryCodecService {
  const ReferenceBundleDirectoryCodecService();

  ReferenceBundleDocument readDirectory(String bundleRootPath) {
    final manifest = _readJson(
      '$bundleRootPath/${ReferenceBundleConstants.manifestFileName}',
    );
    final packageRecord = _readJson(
      '$bundleRootPath/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.packageFileName}',
    );
    final versionRecord = _readJson(
      '$bundleRootPath/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.versionFileName}',
    );
    final entries = _readJsonList(
      '$bundleRootPath/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.entriesFileName}',
    );
    final dependencies = _readJsonList(
      '$bundleRootPath/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.dependenciesFileName}',
    );
    final promotions = _readJsonList(
      '$bundleRootPath/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.promotionsFileName}',
    );
    final integrity = _readJson(
      '$bundleRootPath/${ReferenceBundleConstants.integrityDirectory}/${ReferenceBundleConstants.integrityFileName}',
    );
    final projectionDirectory = Directory(
      '$bundleRootPath/${ReferenceBundleConstants.projectionsDirectory}',
    );
    final projections = <String, String>{};
    if (projectionDirectory.existsSync()) {
      for (final entity in projectionDirectory.listSync()) {
        if (entity is! File) {
          continue;
        }
        projections[entity.uri.pathSegments.last] = entity.readAsStringSync();
      }
    }
    return ReferenceBundleDocument(
      manifest: ReferenceBundleManifest.fromJson(manifest),
      snapshot: ReferencePackageSnapshot(
        packageRecord: ReferencePackageRecord.fromJson(packageRecord),
        packageVersionRecord: ReferencePackageVersionRecord.fromJson(
          versionRecord,
        ),
        entries: entries
            .map(
              (entry) =>
                  ReferenceEntryRecord.fromJson(ValueReaders.mapValue(entry)),
            )
            .toList(growable: false),
        dependencies: dependencies
            .map(
              (entry) => ReferenceDependencyRecord.fromJson(
                ValueReaders.mapValue(entry),
              ),
            )
            .toList(growable: false),
        promotionRecords: promotions
            .map(
              (entry) => ReferencePromotionRecord.fromJson(
                ValueReaders.mapValue(entry),
              ),
            )
            .toList(growable: false),
      ),
      projections: projections,
      integrity: integrity,
    );
  }

  void writeDirectory(String bundleRootPath, ReferenceBundleDocument document) {
    final rootDirectory = Directory(bundleRootPath)
      ..createSync(recursive: true);
    Directory(
      '${rootDirectory.path}/${ReferenceBundleConstants.payloadDirectory}',
    ).createSync(recursive: true);
    Directory(
      '${rootDirectory.path}/${ReferenceBundleConstants.projectionsDirectory}',
    ).createSync(recursive: true);
    Directory(
      '${rootDirectory.path}/${ReferenceBundleConstants.attachmentsDirectory}',
    ).createSync(recursive: true);
    Directory(
      '${rootDirectory.path}/${ReferenceBundleConstants.integrityDirectory}',
    ).createSync(recursive: true);
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.manifestFileName}',
      document.manifest.toJson(),
    );
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.packageFileName}',
      document.snapshot.packageRecord.toJson(),
    );
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.versionFileName}',
      document.snapshot.packageVersionRecord.toJson(),
    );
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.entriesFileName}',
      document.snapshot.entries
          .map((entry) => entry.toJson())
          .toList(growable: false),
    );
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.dependenciesFileName}',
      document.snapshot.dependencies
          .map((entry) => entry.toJson())
          .toList(growable: false),
    );
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.payloadDirectory}/${ReferenceBundleConstants.promotionsFileName}',
      document.snapshot.promotionRecords
          .map((entry) => entry.toJson())
          .toList(growable: false),
    );
    _writeJson(
      '${rootDirectory.path}/${ReferenceBundleConstants.integrityDirectory}/${ReferenceBundleConstants.integrityFileName}',
      document.integrity,
    );
    File(
      '${rootDirectory.path}/${ReferenceBundleConstants.attachmentsDirectory}/README.md',
    ).writeAsStringSync(_attachmentsReadme(document.manifest.targetLanguage));
    for (final entry in document.projections.entries) {
      File(
        '${rootDirectory.path}/${ReferenceBundleConstants.projectionsDirectory}/${entry.key}',
      ).writeAsStringSync(entry.value);
    }
  }

  Map<String, Object?> _readJson(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return <String, Object?>{};
    }
    return ValueReaders.mapValue(jsonDecode(file.readAsStringSync()));
  }

  List<Object?> _readJsonList(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const <Object?>[];
    }
    return ValueReaders.objectList(jsonDecode(file.readAsStringSync()));
  }

  void _writeJson(String path, Object value) {
    File(
      path,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
  }

  String _attachmentsReadme(String targetLanguage) {
    if (targetLanguage.trim().isEmpty ||
        targetLanguage.trim().startsWith('zh')) {
      return '该目录预留给大文本附件、原始片段、导入原稿和人工审计材料。\n';
    }
    return 'This directory is reserved for large text attachments, source excerpts and raw imported materials.\n';
  }
}
