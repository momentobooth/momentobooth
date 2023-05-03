import 'package:meta/meta.dart';

abstract class LiveViewStreamFactory {

  final String id;
  final String friendlyName;

  LiveViewStreamFactory({required this.id, required this.friendlyName});

  @mustCallSuper
  Future dispose() async {
  }

}
