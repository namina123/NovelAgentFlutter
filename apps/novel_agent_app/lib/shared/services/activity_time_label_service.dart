class ActivityTimeLabelService {
  const ActivityTimeLabelService();

  String labelForRecentActivity(DateTime? timestamp, {DateTime? now}) {
    if (timestamp == null) {
      return '未记录活动';
    }
    final reference = now ?? DateTime.now();
    final delta = reference.difference(timestamp.toLocal());
    if (delta.inSeconds < 45) {
      return '刚刚活动';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes} 分钟前';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours} 小时前';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays} 天前';
    }
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
