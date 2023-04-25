import 'package:momento_booth/models/hardware/live_view_streaming/live_view_frame.dart';
import 'package:meta/meta.dart';

abstract class LiveViewStreamFactory {

  final String id;
  final String friendlyName;

  LiveViewStreamFactory({required this.id, required this.friendlyName});

  Stream<LiveViewFrame> getStream();

  @mustCallSuper
  Future dispose() async {
  }

}
