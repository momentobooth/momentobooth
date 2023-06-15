import 'package:mobx/mobx.dart';

part 'native_library_initialization_manager.g.dart';

class HardwareStateManager extends _HardwareStateManagerBase with _$HardwareStateManager {

  static final HardwareStateManager instance = HardwareStateManager._internal();

  HardwareStateManager._internal();

}

/// Class containing global state for photos in the app
abstract class _HardwareStateManagerBase with Store {

  // TODO: make these immutable after they are set

  @observable
  bool nokhwaIsInitialized = false;

  @observable
  String nokhwaInitializationMessage = "";

}
