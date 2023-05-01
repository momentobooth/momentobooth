import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:mobx/mobx.dart';

part 'photo_details_screen_view_model.g.dart';

class PhotoDetailsScreenViewModel = PhotoDetailsScreenViewModelBase with _$PhotoDetailsScreenViewModel;

abstract class PhotoDetailsScreenViewModelBase extends ScreenViewModelBase with Store {

  final String photoId;

  PhotoDetailsScreenViewModelBase({
    required super.contextAccessor,
    required this.photoId,
  });

}
