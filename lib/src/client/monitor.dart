// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream, StreamController;

import 'connection.dart';
import 'dispatcher.dart';

/// A Redis client in Monitor mode.
///
/// In this mode the client receives all the commands procesed by the
/// Redis server. Useful for debugging.
///
/// ```dart
/// final monitor = await Monitor.connect('redis://localhost:6379');
///
/// monitor.start(); // Start the monitor mode
///
/// monitor.stream.listen(print); // Listen for server replies
/// ```
///
/// In this mode the client can not run any command.
///
/// See `monitor.dart` in the `example` folder.
class Monitor {
  final _MonitorDispatcher _dispatcher;

  /// Creates a [Monitor] instance with the given [connection].
  ///
  /// [connect()] provides a more convenient way for creating instances
  /// of this class.
  Monitor(Connection connection) : _dispatcher = _MonitorDispatcher(connection);

  /// Creates a new connection according to the host and port specified
  /// in the [connectionString].
  ///
  /// Connection string must follow the pattern "redis://{host}:{port}".
  ///
  /// Example: redis://localhost:6379
  ///
  /// Returns a [Future] that will complete with either a [Monitor] once
  /// connected or an error if the connection failed.
  static Future<Monitor> connect(String connectionString) async {
    final connection = await Connection.connect(connectionString);

    return Monitor(connection);
  }

  /// Returns the stream where all data will be published.
  Stream<List<int>> get stream => _dispatcher.stream;

  /// Starts the monitor mode.
  ///
  /// See https://redis.io/commands/monitor
  void start() {
    _dispatcher.dispatch(const <Object>[r'MONITOR']);
  }

  /// Closes the connection.
  Future<void> disconnect() => _dispatcher.disconnect();
}

/// A dispatcher for a client in Monitor mode.
class _MonitorDispatcher extends DispatcherBase {
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();

  _MonitorDispatcher(Connection connection) : super(connection);

  Stream<List<int>> get stream => _controller.stream;

  /// Sends a Redis command [line] to the server.
  void dispatch(Iterable<Object> line) {
    final bytes = writer.write(line, codec);
    send(bytes);
  }

  @override
  void onData(List<int> data) {
    _controller.add(data);
  }

  @override
  void onError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  void onDone() {
    _controller.close();
  }
}
