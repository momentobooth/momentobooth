import 'package:mobx/mobx.dart';

part 'native_library_initialization_manager.g.dart';

class HardwareStateManager = HardwareStateManagerBase with _$HardwareStateManager;

/// Class containing global state for photos in the app
abstract class HardwareStateManagerBase with Store {

  static final HardwareStateManagerBase instance = HardwareStateManager._internal();

  // TODO: make these immutable after they are set

  @observable
  bool nokhwaIsInitialized = false;

  @observable
  String nokhwaInitializationMessage = "";

  HardwareStateManagerBase._internal();

}
