// Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
// is governed by a MIT-style license that can be found in the LICENSE file.

import 'package:uuid/uuid.dart' show Uuid;

// UUID generator.
const Uuid _uuid = Uuid();

String uuid() => 'dartis-test-${_uuid.v4()}';
