import 'package:flutter/material.dart';

import '../../application/services/workbench_resource_identity_service.dart';
import '../models/resource_tree_entry_semantic_view_data.dart';

class ResourceTreeEntrySemanticService {
  const ResourceTreeEntrySemanticService({
    WorkbenchResourceIdentityService? resourceIdentityService,
  }) : _resourceIdentityService =
           resourceIdentityService ?? const WorkbenchResourceIdentityService();

  final WorkbenchResourceIdentityService _resourceIdentityService;

  ResourceTreeEntrySemanticViewData resolve({
    required String relativePath,
    required bool isDirectory,
    String projectTypeId = '',
  }) {
    final identity = _resourceIdentityService.classify(
      relativePath: relativePath,
      isDirectory: isDirectory,
      projectTypeId: projectTypeId,
    );
    if (!identity.isKnown) {
      return ResourceTreeEntrySemanticViewData(
        detailLabel: '',
        leadingIcon: isDirectory
            ? Icons.folder_outlined
            : Icons.description_outlined,
      );
    }
    switch (identity.kindId) {
      case 'project_overview':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '概览',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.info_outline_rounded,
          ),
          tone: ResourceTreeSemanticTone.blue,
        );
      case 'sqlite_projection':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '投影',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.account_tree_outlined,
          ),
          tone: ResourceTreeSemanticTone.purple,
        );
      case 'premise_directory':
      case 'formal_premise':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '前提',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.auto_stories_outlined,
          ),
          tone: ResourceTreeSemanticTone.amber,
        );
      case 'outline_directory':
      case 'formal_outline':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '规划',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.route_outlined,
          ),
          tone: ResourceTreeSemanticTone.teal,
        );
      case 'chapter_directory':
      case 'formal_chapter':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '正文',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.menu_book_outlined,
          ),
          tone: ResourceTreeSemanticTone.green,
        );
      case 'sample_directory':
      case 'sample':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '样章',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.history_edu_outlined,
          ),
          tone: ResourceTreeSemanticTone.blue,
        );
      case 'scene_directory':
      case 'scene':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '场景',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.movie_creation_outlined,
          ),
          tone: ResourceTreeSemanticTone.rose,
        );
      case 'asset_directory':
      case 'asset':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '资产',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.inventory_2_outlined,
          ),
          tone: ResourceTreeSemanticTone.purple,
        );
      case 'analysis_directory':
      case 'analysis':
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          badgeLabel: '分析',
          leadingIcon: _leadingIconFor(
            isDirectory: isDirectory,
            fileIcon: Icons.analytics_outlined,
          ),
          tone: ResourceTreeSemanticTone.teal,
        );
      default:
        return ResourceTreeEntrySemanticViewData(
          detailLabel: identity.detailLabel,
          leadingIcon: isDirectory
              ? Icons.folder_outlined
              : Icons.description_outlined,
        );
    }
  }

  IconData _leadingIconFor({
    required bool isDirectory,
    required IconData fileIcon,
  }) {
    // 中文注释: 目录统一回退为朴素文件夹图标，文件再保留语义化图标，避免资源树视觉过杂。
    return isDirectory ? Icons.folder_outlined : fileIcon;
  }
}
