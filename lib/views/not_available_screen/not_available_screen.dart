import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_controller.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_view.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_view_model.dart';

class NotAvailableScreen extends ScreenBase<NotAvailableScreenViewModel, NotAvailableScreenController, NotAvailableScreenView> {

  static const String defaultRoute = "/not-available";

  const NotAvailableScreen({super.key});

  @override
  NotAvailableScreenController createController({required NotAvailableScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return NotAvailableScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  NotAvailableScreenView createView({required NotAvailableScreenController controller, required NotAvailableScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return NotAvailableScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  NotAvailableScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return NotAvailableScreenViewModel(contextAccessor: contextAccessor);
  }

}
