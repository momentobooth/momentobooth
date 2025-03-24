import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'not_available_screen_view_model.g.dart';

class NotAvailableScreenViewModel = NotAvailableScreenViewModelBase with _$NotAvailableScreenViewModel;

abstract class NotAvailableScreenViewModelBase extends ScreenViewModelBase with Store {

  NotAvailableScreenViewModelBase({
    required super.contextAccessor,
  });

}
