// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String name = 'foo';
  final FirebaseOptions options = const FirebaseOptions(
    googleAppID: '1:297855924061:ios:c6de2b69b03a5be8',
    gcmSenderID: '297855924061',
    apiKey: 'AIzaSyBq6mcufFXfyqr79uELCiqM_O_1-G72PVU',
  );

  Future<void> _initialize() async {
    FirebaseApp app = await FirebaseCore.instance.initializeApp(
          name: name,
          options: options
      );

    assert(app != null);
    print('Initialized $app');
  }

  Future<void> _apps() async {
    final List<FirebaseApp> apps = await FirebaseCore.instance.apps;
    print('Currently initialized apps: $apps');
  }

  Future<void> _options() async {
    final FirebaseApp app = await FirebaseCore.instance.app(name);
    final FirebaseOptions options = await app?.options;
    print('Current options for app $name: $options');
  }

  Future<void> _delete() async {
    final FirebaseApp app = await FirebaseCore.instance.app(name);
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
              RaisedButton(onPressed: _initialize, child: const Text('Initialize app')),
              RaisedButton(onPressed: _apps, child: const Text('Get apps')),
              RaisedButton(onPressed: _options, child: const Text('List options')),
              RaisedButton(onPressed: _delete, child: const Text('Delete app')),
            ],
          ),
        ),
      ),
    );
  }
}
