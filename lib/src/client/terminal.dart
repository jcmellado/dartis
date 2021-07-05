// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream, StreamController;

import 'connection.dart';
import 'dispatcher.dart';

/// A Redis client in Terminal mode.
///
/// In this mode the commands are sent to the server using the
/// "inline command" format. Ideal to use in interactive sessions, like
/// a Telnet session.
///
/// ```dart
/// final terminal = await Terminal.connect('redis://localhost:6379');
///
/// terminal.run(<int>[80, 73, 78, 71, 13, 10]); // Run PING command
///
/// terminal.stream.listen(print); // Listen for server replies
/// ```
///
/// Please note that the commands must have a trailing `\r\n` (13, 10).
///
/// See `terminal.dart` in the `example` folder.
class Terminal {
  final _TerminalDispatcher _dispatcher;

  /// Creates a [Terminal] instance with the given [connection].
  ///
  /// [connect()] provides a more convenient way for creating instances of
  /// this class.
  Terminal(Connection connection)
      : _dispatcher = _TerminalDispatcher(connection);

  /// Creates a new connection according to the host and port specified
  /// in the [connectionString].
  ///
  /// Connection string must follow the pattern "redis://{host}:{port}".
  ///
  /// Example: redis://localhost:6379
  ///
  /// Returns a [Future] that will complete with either a [Terminal] once
  /// connected or an error if the connection failed.
  static Future<Terminal> connect(String connectionString) async {
    final connection = await Connection.connect(connectionString);

    return Terminal(connection);
  }

  /// Returns the stream where all server replies will be published.
  Stream<List<int>> get stream => _dispatcher.stream;

  /// Runs a Redis command [line].
  void run(List<int> line) {
    _dispatcher.send(line);
  }

  /// Closes the connection.
  Future<void> disconnect() => _dispatcher.disconnect();
}

/// A dispatcher for a client in Terminal mode.
class _TerminalDispatcher extends DispatcherBase {
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();

  _TerminalDispatcher(Connection connection) : super(connection);

  Stream<List<int>> get stream => _controller.stream;

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
