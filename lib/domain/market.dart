class Market {
  const Market({required this.id, required this.name, required this.eventName});

  final String id;
  final String name;
  final String eventName;

  Market renamed({required String name, required String eventName}) {
    return Market(id: id, name: name, eventName: eventName);
  }
}
