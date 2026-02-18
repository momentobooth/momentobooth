enum TemplateKind {

  front(0, "front"),
  back(1, "back"),
  liveViewOverlay(2, "liveViewOverlay");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const TemplateKind(this.value, this.name);

}
