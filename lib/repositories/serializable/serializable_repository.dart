abstract class SerialiablesRepository<TData> {

  const SerialiablesRepository();

  Future<bool> hasExistingData();

  Future<void> write(TData dataObject);

  Future<TData> get();

  Future<void> delete();

}
