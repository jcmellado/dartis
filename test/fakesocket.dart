// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

Stream<List<int>> _stream(List<List<int>> data, Exception error) async* {
  for (final b in data) {
    yield b;
  }
  if (error != null) {
    throw error;
  }
}

class FakeSocket extends Stream<List<int>> with IOSink implements Socket {
  final List<int> written = [];
  final Stream<List<int>> _output;
  final Completer<void> _done = Completer();

  @override
  InternetAddress address;

  @override
  InternetAddress remoteAddress;

  @override
  int remotePort;

  @override
  int port;

  FakeSocket(
    List<List<int>> output,
    Exception error, {
    this.address,
    this.port = 0,
    this.remoteAddress,
    this.remotePort = 0,
  })  : _output = _stream(output, error),
        super();

  @override
  Future get done => _done.future;

  @override
  void add(List<int> data) {
    if (_done.isCompleted) {
      throw const SocketException('FakeSocket is closed.');
    }
    written.addAll(data);
  }

  @override
  Future addStream(Stream<List<int>> stream) async => stream.forEach(add);

  @override
  void addError(Object e, [StackTrace st]) => _done.completeError(e);

  @override
  Future close() async => _done.isCompleted ? null : _done.complete();

  @override
  Future flush() async => Future<void>.value();

  @override
  bool setOption(SocketOption option, bool enabled) => true;

  @override
  void destroy() => close();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      _output.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  void write(Object obj) {
    add(encoding.encode(obj.toString()));
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    var first = true;
    for (final obj in objects) {
      if (first) {
        write(separator);
        first = false;
      }
      write(obj);
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object obj = '']) {
    write(obj);
    write('\n');
  }
}
