import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartScreenView extends ScreenViewBase<StartScreenViewModel, StartScreenController> {

  const StartScreenView({
    super.key,
    required super.viewModel,
    required super.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    MomentoBoothThemeData themeData = MomentoBoothTheme.dataOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const SampleBackground(),
        Column(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: SizedBox(),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  "Touch to start",
                  style: themeData.titleStyle,
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: SizedBox(
                width: 450,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: SvgPicture.asset(
                    "assets/svg/logo.svg",
                    colorFilter: ColorFilter.mode(themeData.defaultPageBackgroundColor, BlendMode.srcIn),
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

}
