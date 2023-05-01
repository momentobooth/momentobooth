import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'gallery_screen_view_model.g.dart';

class GalleryScreenViewModel = GalleryScreenViewModelBase with _$GalleryScreenViewModel;

abstract class GalleryScreenViewModelBase extends ScreenViewModelBase with Store {

  GalleryScreenViewModelBase({
    required super.contextAccessor,
  });

}
