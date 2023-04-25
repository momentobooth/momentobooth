import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/nokhwa_camera_stream_factory.dart';
import 'package:momento_booth/models/hardware/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class NokhwaCamera extends LiveViewSource {

  NokhwaCamera({required super.id, required super.friendlyName});

  static Future<List<NokhwaCamera>> getAllCameras() async {
    List<NokhwaCameraInfo> cameras = await rustLibraryApi.nokhwaGetCameras();
    return cameras.map((camera) => NokhwaCamera(
      id: camera.friendlyName,
      friendlyName: camera.friendlyName,
    )).toList();
  }

  @override
  Future<NokhwaCameraStreamFactory> openStream() => NokhwaCameraStreamFactory.createAndOpen(id: id, friendlyName: friendlyName);

  ComboBoxItem<String> toComboBoxItem() => ComboBoxItem(value: friendlyName, child: Text(friendlyName));

  static Future<List<ComboBoxItem<String>>> asComboBoxItems() async =>
      (await getAllCameras()).map((value) => value.toComboBoxItem()).toList();

}
