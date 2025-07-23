part of blackblizzard;

// Channel abstract class and StreamChannel implementation

abstract class Channel {
  String get name;
  Stream<String> get stream;
  void send(String message);
}

class StreamChannel extends Channel {
  final String _name;
  final StreamController<String> _controller = StreamController<String>.broadcast();

  StreamChannel(this._name);

  @override
  String get name => _name;

  @override
  Stream<String> get stream => _controller.stream;

  @override
  void send(String message) {
    _controller.add(message);
    print('【$_name频道】$message');
  }
} 