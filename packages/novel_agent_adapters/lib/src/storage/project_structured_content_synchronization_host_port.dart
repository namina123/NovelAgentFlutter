abstract interface class ProjectStructuredContentSynchronizationHostPort {
  Future<T> runWithoutStructuredContentSynchronization<T>(
    Future<T> Function() operation,
  );
}
