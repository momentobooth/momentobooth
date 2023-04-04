import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_view_model.dart';

class ShareScreenController extends ScreenControllerBase<ShareScreenViewModel> {

  // Initialization/Deinitialization

  ShareScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onClickNext() {
    router.push("/");
  }

  void onClickGetQR() {
    print("Requesting QR code");
  }

  void onClickPrint() {
    print("Requesting photo print");
  }

}
