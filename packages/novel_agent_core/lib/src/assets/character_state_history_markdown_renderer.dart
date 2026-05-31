import 'character_stage_state_record.dart';

class CharacterStateHistoryMarkdownRenderer {
  const CharacterStateHistoryMarkdownRenderer();

  String appendEntry({
    required String existingContent,
    required CharacterStageStateRecord record,
  }) {
    // 中文注释: 历史附录只做追加渲染，不承担任何身份归并或字段推断职责。
    final buffer = StringBuffer();
    final normalizedExisting = existingContent.trimRight();
    if (normalizedExisting.isEmpty) {
      buffer.writeln('# ${record.displayName} 状态历史');
      buffer.writeln();
    } else {
      buffer.writeln(normalizedExisting);
      buffer.writeln();
      buffer.writeln();
    }
    final titleParts = <String>[
      if (record.updatedAt.trim().isNotEmpty) record.updatedAt.trim(),
      if (record.stageLabel.trim().isNotEmpty)
        record.stageLabel.trim()
      else
        '阶段更新',
    ];
    buffer.writeln('## ${titleParts.join(' · ')}');
    buffer.writeln();
    if (record.status.trim().isNotEmpty) {
      buffer.writeln('- 状态：${record.status.trim()}');
    }
    if (record.sourcePaths.isNotEmpty) {
      buffer.writeln('- 来源：${record.sourcePaths.join('、')}');
    }
    if (record.relatedTimelineIds.isNotEmpty) {
      buffer.writeln('- 关联时间线：${record.relatedTimelineIds.join('、')}');
    }
    if (record.summary.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(record.summary.trim());
    }
    return '${buffer.toString().trimRight()}\n';
  }
}
