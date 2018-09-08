// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

/// RESP (REdis Serialization Protocol) tokens.
abstract class RespToken {
  /// RESP simple string.
  static const int string = 43; // +

  /// RESP integer.
  static const int integer = 58; // :

  /// RESP bulk string.
  static const int bulk = 36; // $

  /// RESP array.
  static const int array = 42; // *

  /// RESP error.
  static const int error = 45; // -
}
