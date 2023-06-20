// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data' show BytesBuilder;
import 'codec.dart';
import 'token.dart';

/// A writer that encodes Redis commands to lists of bytes.
class Writer {
  static const List<int> _crlf = <int>[13, 10]; // CR LF

  final BytesBuilder _buffer = BytesBuilder(copy: false);

  /// Encodes a Redis command [line] to a list of bytes.
  List<int> write(Iterable<Object> line, RedisCodec codec) {
    _write(line, codec);

    return _buffer.takeBytes();
  }

  /// Encodes a list of Redis command [lines] to a list of bytes.
  List<int> writeAll(Iterable<Iterable<Object>> lines, RedisCodec codec) {
    for (final line in lines) {
      _write(line, codec);
    }

    return _buffer.takeBytes();
  }

  void _write(Iterable<Object> line, RedisCodec codec) {
    final length = codec.encode<List<int>>(line.length);

    _buffer
      ..addByte(RespToken.array)
      ..add(length)
      ..add(_crlf);

    for (final value in line) {
      final bytes = codec.encode<List<int>>(value);
      final length = codec.encode<List<int>>(bytes.length);

      _buffer
        ..addByte(RespToken.bulk)
        ..add(length)
        ..add(_crlf)
        ..add(bytes)
        ..add(_crlf);
    }
  }
}
