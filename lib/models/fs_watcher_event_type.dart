enum FsWatcherEventType {

  create(1 << 0),
  modify(1 << 1),
  delete(1 << 2),
  move(1 << 3);

  final int value;

  const FsWatcherEventType(this.value);

}
