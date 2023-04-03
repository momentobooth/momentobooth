import 'dart:typed_data';

import 'package:mobx/mobx.dart';

part 'photos_manager.g.dart';

class PhotosManager = PhotosManagerBase with _$PhotosManager;

/// Class containing global state for photos in the app
abstract class PhotosManagerBase with Store {

  static final PhotosManagerBase instance = PhotosManager._internal();

  @observable
  ObservableList<Uint8List> photos = ObservableList<Uint8List>();

  PhotosManagerBase._internal();

}
