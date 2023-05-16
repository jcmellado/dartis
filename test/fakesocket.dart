// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

Stream<Uint8List> _stream(List<List<int>> data, Exception? error) async* {
  for (final b in data) {
    yield Uint8List.fromList(b);
  }
  if (error != null) {
    throw error;
  }
}

class FakeSocket extends Stream<Uint8List> implements IOSink, Socket {
  final List<int> written = [];
  final Stream<Uint8List> _output;
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
    Exception? error, {
    InternetAddress? address,
    InternetAddress? remoteAddress,
    this.port = 0,
    this.remotePort = 0,
  })  : _output = _stream(output, error),
        address = address ?? InternetAddress.anyIPv4,
        remoteAddress = remoteAddress ?? InternetAddress.anyIPv4,
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
  void addError(Object e, [StackTrace? stackTrace]) =>
      _done.completeError(e, stackTrace);

  @override
  Future close() async => _done.isCompleted ? null : _done.complete();

  @override
  Future flush() async => Future<void>.value();

  @override
  bool setOption(SocketOption option, bool enabled) => true;

  @override
  void destroy() => close();

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _output.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  void write(Object? obj) {
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
  void writeln([Object? obj]) {
    obj ??= '';
    write(obj);
    write('\n');
  }

  @override
  Uint8List getRawOption(RawSocketOption option) => option.value;

  @override
  void setRawOption(RawSocketOption option) {}

  @override
  Encoding encoding = utf8;
}
