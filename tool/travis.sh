#!/bin/bash

# Copyright (c) 2018, Juan Mellado. All rights reserved. Use of this source
# is governed by a MIT-style license that can be found in the LICENSE file.

# Exit as soon as one command returns a non-zero exit code.
set -ev

# Resolves dependencies.
pub get

# Runs dartfmt.
if [[ $(dartfmt -n --set-exit-if-changed lib/ test/) ]]; then
  exit 1
fi

# Runs dartanalyzer.
dartanalyzer --fatal-warnings --fatal-infos lib/ test/

# Runs the tests.
pub run test:test --reporter expanded

# Gathers coverage data.
dart \
  --enable-vm-service=8888 \
  --pause-isolates-on-exit \
  test/dartis_tests.dart &

pub global activate coverage

pub global run coverage:collect_coverage \
  --port=8888 \
  --out=var/coverage.json \
  --wait-paused \
  --resume-isolates

pub global run coverage:format_coverage \
  --lcov \
  --in=var/coverage.json \
  --out=var/lcov.info \
  --packages=.packages \
  --report-on=lib
