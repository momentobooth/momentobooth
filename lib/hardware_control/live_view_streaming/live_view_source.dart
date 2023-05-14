abstract class LiveViewSource {

  final String id;
  final String friendlyName;

  LiveViewSource({required this.id, required this.friendlyName});

  Future<void> openStream({required int texturePtr});

  Future<void> dispose() async {
  }

}
