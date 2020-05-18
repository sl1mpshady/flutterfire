// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String name = 'foo';
  final FirebaseOptions options = FirebaseOptions(
    appId: '1:448618578101:web:0b650370bb29e29cac3efc',
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    projectId: 'react-native-firebase-testing',
    messagingSenderId: '448618578101',
  );

  Future<void> _initialize() async {
    FirebaseApp app = await FirebaseCore.instance.initializeApp(name: name, options: options);

    assert(app != null);
    print('Initialized $app');
  }

  void _apps() {
    final List<FirebaseApp> apps = FirebaseCore.instance.apps;
    print('Currently initialized apps: $apps');
  }

  void _options() {
    final FirebaseApp app = FirebaseCore.instance.app(name);
    final FirebaseOptions options = app?.options;
    print('Current options for app $name: $options');
  }

  Future<void> _delete() async {
    final FirebaseApp app = FirebaseCore.instance.app(name);
    await app?.delete();
    print('App $name deleted');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Core example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RaisedButton(
                  onPressed: _initialize, child: const Text('Initialize app')),
              RaisedButton(onPressed: _apps, child: const Text('Get apps')),
              RaisedButton(
                  onPressed: _options, child: const Text('List options')),
              RaisedButton(onPressed: _delete, child: const Text('Delete app')),
            ],
          ),
        ),
      ),
    );
  }
}
