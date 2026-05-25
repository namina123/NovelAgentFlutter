import 'run_instance.dart';

abstract class LongTaskRunRegistry {
  Future<void> save(RunInstance instance);

  Future<RunInstance?> findById(String runId);

  Future<List<RunInstance>> listAll();

  Future<List<RunInstance>> listByProject(String projectKey);

  Future<List<RunInstance>> listActive();

  Future<void> delete(String runId);
}
