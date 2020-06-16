// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      /// Initialize FlutterFire
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirestoreExampleApp.error(snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return FirestoreExampleApp.ready(Firestore.instance);
        }

        return FirestoreExampleApp.loading();
      },
    );
  }
}

class FirestoreExampleApp extends StatelessWidget {
  final bool loading;
  final String error;
  final Firestore firestore;

  FirestoreExampleApp._(
      {this.loading = false, this.error = '', this.firestore});

  factory FirestoreExampleApp.loading() {
    return FirestoreExampleApp._(loading: true);
  }

  factory FirestoreExampleApp.error(String error) {
    return FirestoreExampleApp._(error: error);
  }

  factory FirestoreExampleApp.ready(Firestore firestore) {
    return FirestoreExampleApp._(firestore: firestore);
  }

  MaterialApp withMaterialApp(Widget body) {
    return MaterialApp(
      title: 'Firestore Example App',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return withMaterialApp(Center(child: CircularProgressIndicator()));
    }

    if (error.isNotEmpty) {
      return withMaterialApp(Center(child: Text(error)));
    }

    return withMaterialApp(Center(child: FilmList(firestore)));
  }
}

class FilmList extends StatelessWidget {
  final Firestore firestore;

  FilmList(this.firestore);

  @override
  Widget build(BuildContext context) {
    Query query = firestore.collection('firestore-example-app');

    /// Order by the year. Set [descending] to [false] to reverse the order
    query = query.orderBy('year', descending: true);

    /// Order by the score, and return only those which has one great than 90
    // query = query.orderBy('score').where('score', isGreaterThan: 90);

    /// Return the movies which have the following categories
    // query = query.where('genre', arrayContainsAny: ['Fantasy', 'Sci-Fi']);

    return Scaffold(
        appBar: AppBar(
          title: Text('Firestore Example: Movies'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, stream) {
            if (stream.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (stream.hasError) {
              return Center(child: Text(stream.error.toString()));
            }

            QuerySnapshot querySnapshot = stream.data;

            return ListView.builder(
              itemCount: querySnapshot.size,
              itemBuilder: (context, index) =>
                  Movie(firestore, querySnapshot.docs[index]),
            );
          },
        ));
  }
}

class Movie extends StatelessWidget {
  final Firestore firestore;
  final DocumentSnapshot snapshot;

  Movie(this.firestore, this.snapshot);

  Map<String, dynamic> get movie {
    return snapshot.data();
  }

  Widget get poster {
    return Container(
      width: 100,
      child: Center(child: Image.network(movie['poster'])),
    );
  }

  Widget get details {
    return Padding(
        padding: EdgeInsets.only(left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            metadata,
            genres,
            Likes(
              firestore: firestore,
              reference: snapshot.reference,
              currentLikes: movie['likes'],
            )
          ],
        ));
  }

  Widget get title {
    return Text("${movie['title']} (${movie['year']})",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget get metadata {
    return Padding(
        padding: EdgeInsets.only(top: 8),
        child: Row(children: [
          Padding(
              child: Text('Rated: ${movie['rated']}'),
              padding: EdgeInsets.only(right: 8)),
          Text('Runtime: ${movie['runtime']}'),
        ]));
  }

  Widget get genres {
    return Padding(
        padding: EdgeInsets.only(top: 8),
        child: Wrap(children: <Widget>[
          for (String genre in movie['genre'])
            Padding(
              child: Chip(
                  label: Text(genre, style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.lightBlue),
              padding: EdgeInsets.only(right: 2),
            ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(bottom: 4, top: 4),
        child: Container(
          child: Row(
            children: [poster, Flexible(child: details)],
          ),
        ));
  }
}

class Likes extends StatefulWidget {
  final Firestore firestore;
  final DocumentReference reference;
  final num currentLikes;

  Likes({Key key, this.firestore, this.reference, this.currentLikes})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _Likes();
  }
}

class _Likes extends State<Likes> {
  num _likes;

  _onLike(int current) async {
    // Increment the "like" count straight away to show feedback to the user
    setState(() {
      _likes = current + 1;
    });

    try {
      // Return and set the updated "likes" count from the transaction
      int newLikes =
          await widget.firestore.runTransaction<int>((transaction) async {
        DocumentSnapshot txSnapshot = await transaction.get(widget.reference);

        if (!txSnapshot.exists) {
          throw Exception("Document does not exist!");
        }

        int updatedLikes = (txSnapshot.data()['likes'] ?? 0) + 1;
        transaction.update(widget.reference, {'likes': updatedLikes});
        return updatedLikes;
      });

      // Update the count once the transaction has completed
      setState(() {
        _likes = newLikes;
      });
    } catch (e) {
      print("Failed to update likes for document! $e");

      // If the transaction fails, revert back to the old count
      setState(() {
        _likes = current;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentLikes = _likes ?? widget.currentLikes ?? 0;

    return Row(children: [
      IconButton(
          icon: Icon(Icons.favorite),
          iconSize: 20,
          onPressed: () {
            _onLike(currentLikes);
          }),
      Text("$currentLikes likes"),
    ]);
  }
}
