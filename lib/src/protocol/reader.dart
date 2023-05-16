// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:math' show min, max;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import '../exception.dart';
import 'reply.dart';
import 'token.dart';

/// RESP (REdis Serialization Protocol) reply reader.
abstract class Reader {
  /// Creates a [Reader] for reading a reply of the given [type].
  factory Reader(int type) {
    switch (type) {
      case RespToken.string:
        return _StringReplyReader();
      case RespToken.integer:
        return _IntReplyReader();
      case RespToken.bulk:
        return _BulkReplyReader();
      case RespToken.array:
        return _ArrayReplyReader();
      case RespToken.error:
        return _ErrorReplyReader();
    }

    throw RedisException('Unexpected server reply type "$type".');
  }

  /// Whether this reader has been completed and [consume()] could be called.
  bool get done;

  /// Reads [bytes] from [start] and returns the latest read position.
  ///
  /// Bytes are copied to an internal buffer.
  int read(Uint8List bytes, int start);

  /// Consumes the internal buffer and returns the reply.
  Reply consume();
}

/// Base class for implementing [Reader].
abstract class _ReaderBase implements Reader {
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  bool _isNull = false;

  bool _done = false;

  @override
  bool get done => _done;

  List<int> _takeBytes() {
    assert(_done);
    assert(!_isNull);

    return _buffer.takeBytes();
  }
}

/// A reader that reads a RESP simple string.
class _StringReplyReader extends _LineReader {
  @override
  Reply consume() => _isNull ? nullReply : StringReply(_takeBytes());
}

/// A reader that reads a RESP integer.
class _IntReplyReader extends _LineReader {
  @override
  Reply consume() => _isNull ? nullReply : IntReply(_takeBytes());
}

/// A reader that reads a RESP bulk string.
class _BulkReplyReader extends _BulkReader {
  @override
  Reply consume() => _isNull ? nullReply : BulkReply(_takeBytes());
}

/// A reader that reads a RESP array.
class _ArrayReplyReader extends _ArrayReader {
  @override
  Reply consume() {
    assert(_done);

    if (_isNull) {
      return nullReply;
    }
    return ArrayReply(_array);
  }
}

/// A reader that reads a RESP error.
class _ErrorReplyReader extends _LineReader {
  @override
  Reply consume() => ErrorReply(_takeBytes());
}

/// A reader that reads bytes until CR LF.
abstract class _LineReader extends _ReaderBase {
  @override
  int read(Uint8List bytes, int start) {
    var crlf = 0;

    var end = start;
    while (end < bytes.length) {
      final byte = bytes[end++];

      if (byte == 13) {
        crlf++;
      } else if (byte == 10) {
        crlf++;
        _done = true;
        break;
      }
    }

    assert(crlf <= 2);

    if (start < end - crlf) {
      _buffer.add(Uint8List.view(bytes.buffer, start, end - crlf - start));
    }

    return end;
  }
}

/// A reader that reads a length.
abstract class _LengthReader extends _LineReader {
  int? _length;

  @override
  int read(Uint8List bytes, int start) {
    var end = start;

    if (_length == null) {
      end = _readLength(bytes, start);

      if (!_done || _isNull) {
        return end;
      }

      _done = false;
    }

    return _readPayload(bytes, end);
  }

  int _readLength(Uint8List bytes, int start) {
    final end = super.read(bytes, start);

    if (_done) {
      _length = int.parse(String.fromCharCodes(_takeBytes()));

      _isNull = _length == -1;
    }

    return end;
  }

  int _readPayload(Uint8List bytes, int start);
}

/// A reader that reads a length and a payload.
abstract class _BulkReader extends _LengthReader {
  @override
  int _readPayload(Uint8List bytes, int start) {
    final size = min(bytes.length - start, _length! + 2);

    final crlf = min(size, max(0, size - _length!));

    assert(crlf <= 2);

    if (size - crlf > 0) {
      _buffer.add(Uint8List.view(bytes.buffer, start, size - crlf));
    }

    _length = _length! - size;
    _done = _length == -2;

    assert(_length! >= -2);

    return start + size;
  }
}

/// A reader that reads a length and an array.
abstract class _ArrayReader extends _LengthReader {
  final List<Reply> _array = [];

  /// Current reader.
  Reader? _reader;

  @override
  int _readPayload(Uint8List bytes, int start) {
    var end = start;

    while (_length! > 0) {
      if (end == bytes.length) {
        return end;
      }

      // Creates a reader.
      if (_reader == null) {
        final type = bytes[end++];
        _reader = Reader(type);
      }

      // Reads.
      end = _reader!.read(bytes, end);

      if (!_reader!.done) {
        return end;
      }

      // Consumes the reply.
      final reply = _reader!.consume();
      _array.add(reply);
      _reader = null;

      _length = _length! - 1;
    }

    _done = true;

    return end;
  }
}
