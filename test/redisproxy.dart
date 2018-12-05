import 'dart:async';
import 'dart:io';

void _ignoreErr(Object error) {}

/// Simple proxy that forwards bytes to redis server on localhost and supports
/// breaking the connections.
class RedisProxy {
  final ServerSocket _server;
  final Completer _done = Completer<void>();

  RedisProxy(this._server) {
    _server.forEach(_handle);
  }

  void _handle(Socket client) async {
    final redis = await Socket.connect(InternetAddress.loopbackIPv4, 6379);
    // Set TCP no delay
    client.setOption(SocketOption.tcpNoDelay, true);
    redis.setOption(SocketOption.tcpNoDelay, true);
    // Pipe until, _done then we break the connection
    try {
      await Future.any<void>([
        client.pipe(redis).catchError(_ignoreErr),
        redis.pipe(client).catchError(_ignoreErr),
        _done.future,
      ]);
    } finally {
      client.destroy();
      redis.destroy();
    }
  }

  /// Close server and connections
  Future closeConnectionsAndServer() async {
    _done.complete();
    await _server.close();
  }

  String get connectionString =>
      'redis://${_server.address.address}:${_server.port}';

  static Future<RedisProxy> create() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    return RedisProxy(server);
  }
}
