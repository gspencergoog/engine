// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

const MethodCodec codec = JSONMethodCodec();

void emptyCallback(ByteData date) {}

TestLocationStrategy _strategy;
TestLocationStrategy get strategy => _strategy;
set strategy(TestLocationStrategy newStrategy) {
  EnginePlatformDispatcher.instance.locationStrategy = _strategy = newStrategy;
}

void main() {
  test('window.initialRouteName should not change', () {
    strategy = TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/initial'));
    expect(window.initialRouteName, '/initial');

    // Changing the URL in the address bar later shouldn't affect [window.initialRouteName].
    strategy.replaceState(null, null, '/newpath');
    expect(window.initialRouteName, '/initial');
  });

  test('window.initialRouteName should reset after navigation platform message', () {
    strategy = TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/initial'));
    // Reading it multiple times should return the same value.
    expect(window.initialRouteName, '/initial');
    expect(window.initialRouteName, '/initial');

    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routePushed',
        <String, dynamic>{'previousRouteName': '/foo', 'routeName': '/bar'},
      )),
      emptyCallback,
    );
    // After a navigation platform message, [window.initialRouteName] should
    // reset to "/".
    expect(window.initialRouteName, '/');
  });
}
