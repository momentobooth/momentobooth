/// Repository for a single serializable and deserializable value.
abstract class SerialiableRepository<TData> {

  const SerialiableRepository();

  Future<bool> hasExistingData();

  Future<void> write(TData dataObject);

  Future<TData> get();

  Future<void> delete();

}
