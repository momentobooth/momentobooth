import 'package:flutter_rust_bridge_example/models/hardware/live_view_streaming/live_view_frame.dart';
import 'package:meta/meta.dart';

abstract class LiveViewStream {

  final String id;
  final String friendlyName;

  LiveViewStream({required this.id, required this.friendlyName});

  Stream<LiveViewFrame> getStream();

  @mustCallSuper
  Future dispose() async {
  }

}
