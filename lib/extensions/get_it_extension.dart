import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/subsystem.dart';

extension GetItExtension on GetIt {

  T registerManager<T extends Object>(T instance) {
    if (instance is Subsystem) {
      if (!isRegistered<ObservableList<Subsystem>>()) {
        registerSingleton(ObservableList<Subsystem>());
      }

      get<ObservableList<Subsystem>>().add(instance);
    }

    return registerSingleton(instance);
  }

}
