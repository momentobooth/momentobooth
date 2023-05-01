import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen_controller.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen_view_model.dart';

class PhotoDetailsScreenView extends ScreenViewBase<PhotoDetailsScreenViewModel, PhotoDetailsScreenController> {

  const PhotoDetailsScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Center(child: Text("Showing ${viewModel.photoId}", style: theme.titleStyle, textAlign: TextAlign.center,));
  }

}
