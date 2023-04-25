import 'package:momento_booth/hardware_control/live_view_streaming/live_view_stream_factory.dart';

abstract class LiveViewSource {

  final String id;
  final String friendlyName;

  LiveViewSource({required this.id, required this.friendlyName});

  Future<LiveViewStreamFactory> openStream();

}
