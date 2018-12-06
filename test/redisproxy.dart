// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

void _ignoreError(Object error) {}

/// Simple proxy that forwards bytes to redis server on localhost and supports
/// breaking the connections.
class RedisProxy {
  final ServerSocket _server;
  final Completer _done = Completer<void>();

  RedisProxy(this._server) {
    _server.forEach(_handle);
  }

  static Future<RedisProxy> create() async {
    final server = await ServerSocket.bind('localhost', 0);
    return RedisProxy(server);
  }

  String get connectionString => 'redis://localhost:${_server.port}';

  /// Close server and connections.
  Future closeConnectionsAndServer() async {
    _done.complete();
    await _server.close();
  }

  void _handle(Socket client) async {
    final redis = await Socket.connect('localhost', 6379);
    // Set TCP no delay.
    client.setOption(SocketOption.tcpNoDelay, true);
    redis.setOption(SocketOption.tcpNoDelay, true);
    // Pipe until, _done then we break the connection.
    try {
      await Future.any<void>([
        client.pipe(redis).catchError(_ignoreError),
        redis.pipe(client).catchError(_ignoreError),
        _done.future,
      ]);
    } finally {
      client.destroy();
      redis.destroy();
    }
  }
}
