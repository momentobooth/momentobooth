import 'dart:typed_data';

import 'package:mobx/mobx.dart';

part 'photo_state.g.dart';

class PhotoState = PhotoStateBase with _$PhotoState;

/// Class containing global state for photos in the app
abstract class PhotoStateBase with Store {
  static final PhotoStateBase instance = PhotoState._internal();
  @observable
  ObservableList<Uint8List> photos = ObservableList<Uint8List>();

  PhotoStateBase._internal();
}