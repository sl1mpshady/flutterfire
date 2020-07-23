// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import './register_page.dart';
// import './signin_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

/// App entry point
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Firebase Auth Demo', home: Text("TODO"));
  }
}

// class MyHomePage extends StatefulWidget {
//   MyHomePage({
//     Key key,
//     this.title,
//   }) : super(key: key);

//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   _MyHomePageState();
//   FirebaseAuth user;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           Container(
//             child: RaisedButton(
//               child: const Text('Test registration'),
//               onPressed: () => _pushPage(context, RegisterPage()),
//             ),
//             padding: const EdgeInsets.all(16),
//             alignment: Alignment.center,
//           ),
//           Container(
//             child: RaisedButton(
//               child: const Text('Test SignIn/SignOut'),
//               onPressed: () => _pushPage(context, SignInPage()),
//             ),
//             padding: const EdgeInsets.all(16),
//             alignment: Alignment.center,
//           ),
//         ],
//       ),
//     );
//   }

//   void _pushPage(BuildContext context, Widget page) {
//     Navigator.of(context).push(
//       MaterialPageRoute<void>(builder: (_) => page),
//     );
//   }
// }
