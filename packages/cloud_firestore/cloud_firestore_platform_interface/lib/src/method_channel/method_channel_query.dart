// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'method_channel_firestore.dart';
import 'method_channel_query_snapshot.dart';
import 'utils/source.dart';

Map<String, dynamic> _initialParameters = Map<String, dynamic>.unmodifiable({
  'where': List<List<dynamic>>.unmodifiable([]),
  'orderBy': List<List<dynamic>>.unmodifiable([]),
  'startAt': null,
  'startAfter': null,
  'endAt': null,
  'endAtDocument': null,
  'endBefore': null,
  'endBeforeDocument': null,
  'limit': null,
  'limitToLast': null,
});

/// Represents a query over the data at a particular location.
class MethodChannelQuery extends QueryPlatform {
  /// Stores the instances query modifier filters.
  Map<String, dynamic> parameters;

  /// Flags whether the current query is for a collection group.
  bool isCollectionGroup;

  /// Create a [MethodChannelQuery] from [pathComponents]
  MethodChannelQuery(
    FirestorePlatform firestore,
    String path, {
    Map<String, dynamic> params,
    this.isCollectionGroup = false,
  }) : super(firestore) {
    _pointer = Pointer(path);
    parameters = params ?? _initialParameters;
  }

  Pointer _pointer;

  /// Creates a new instance of [MethodChannelQuery], however overrides
  /// any existing [parameters].
  ///
  /// This is in place to ensure that changes to a query don't mutate
  /// other queries.
  MethodChannelQuery _copyWithParameters(Map<String, dynamic> parameters) {
    Map<String, dynamic> currentParameters =
        Map<String, dynamic>.from(this.parameters);
    currentParameters.addAll(parameters);

    return MethodChannelQuery(
      firestore,
      _pointer.path,
      isCollectionGroup: isCollectionGroup,
      params: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(this.parameters)..addAll(parameters),
      ),
    );
  }

  /// Returns whether the current query has a "start" cursor query.
  bool _hasStartCursor() {
    return parameters['startAt'] != null ||
        parameters['startAtDocument'] != null ||
        parameters['startAfter'] != null ||
        parameters['startAfterDocument'] != null;
  }

  /// Returns whether the current query has a "end" cursor query.
  bool _hasEndCursor() {
    return parameters['endAt'] != null ||
        parameters['endAtDocument'] != null ||
        parameters['endBefore'] != null ||
        parameters['endBeforeDocument'] != null;
  }

  /// Handles all [DocumentSnapshotPlatform] document cursor queries.
  ///
  /// For a document to be useable, any [orderBy] fields in use must
  /// exist on the snapshot, otherwise the query is invalid.
  Map<String, dynamic> _handleSnapshotCursorQuery(
      DocumentSnapshotPlatform documentSnapshot) {
    assert(documentSnapshot != null);
    assert(documentSnapshot.exists,
        "a document snaphot must exist to be used within a query");

    List<List<dynamic>> orders = List.from(parameters['orderBy']);
    List<dynamic> values = [];

    for (List<dynamic> order in orders) {
      dynamic field = order[0];

      // All order by fields must exist within the snapshot
      if (field != FieldPath.documentId) {
        try {
          values.add(documentSnapshot.get(field));
        } on StateError {
          throw ("You are trying to start or end a query using a document for which the field '$field' (used as the orderBy) does not exist.");
        }
      }
    }

    // Any time you construct a query and don't include 'name' in the orderBys,
    // Firestore will implicitly assume an additional .orderBy('__name__', DIRECTION)
    // where DIRECTION will match the last orderBy direction of your query (or 'asc' if you have no orderBys).
    if (orders.isNotEmpty) {
      List<dynamic> lastOrder = orders.last;

      if (lastOrder[0] != FieldPath.documentId) {
        orders.add([FieldPath.documentId, lastOrder[1]]);
      } else {
        orders.add([FieldPath.documentId, false]);
      }
    }

    return <String, dynamic>{
      'orders': orders,
      'values': values,
    };
  }

  /// Handles all string or FieldPath fields passed to any cursor query.
  Map<String, dynamic> _handleCursorQuery(List<dynamic> fields) {
    assert(fields != null);
    List<List<dynamic>> orders = List.from(parameters['orderBy']);

    assert(
        fields.where((value) => value is String || value is FieldPath).length ==
            fields.length,
        '[fields] must be a [String] or [FieldPath]');
    assert(fields.length <= orders.length,
        "Too many arguments provided. The number of arguments must be less than or equal to the number of orderBy() clauses.");

    return <String, List<FieldPath>>{
      'values': List<FieldPath>.from(fields.map((field) {
        if (field is FieldPath) return field;
        return FieldPath.fromString(field);
      })),
    };
  }

  @override
  QueryPlatform endAtDocument(DocumentSnapshotPlatform documentSnapshot) {
    Map<String, dynamic> result = _handleSnapshotCursorQuery(documentSnapshot);

    return _copyWithParameters(<String, dynamic>{
      'orderBy': result['orders'],
      'endAt': null,
      'endAtDocument': <String, dynamic>{
        'id': documentSnapshot.id,
        'path': documentSnapshot.reference.path,
        'values': result['values'],
      },
      'endBefore': null,
      'endBeforeDocument': null,
    });
  }

  @override
  QueryPlatform endAt(List<dynamic> fields) {
    Map<String, dynamic> result = _handleCursorQuery(fields);

    return _copyWithParameters(<String, dynamic>{
      'endAt': result['values'],
      'endAtDocument': null,
      'endBefore': null,
      'endBeforeDocument': null,
    });
  }

  @override
  QueryPlatform endBeforeDocument(DocumentSnapshotPlatform documentSnapshot) {
    Map<String, dynamic> result = _handleSnapshotCursorQuery(documentSnapshot);

    return _copyWithParameters(<String, dynamic>{
      'orderBy': result['orders'],
      'endAt': null,
      'endAtDocument': null,
      'endBefore': null,
      'endBeforeDocument': <String, dynamic>{
        'id': documentSnapshot.id,
        'path': documentSnapshot.reference.path,
        'values': result['values'],
      },
    });
  }

  @override
  QueryPlatform endBefore(List<dynamic> fields) {
    Map<String, dynamic> result = _handleCursorQuery(fields);

    return _copyWithParameters(<String, dynamic>{
      'endAt': null,
      'endAtDocument': null,
      'endBefore': result['values'],
      'endBeforeDocument': null,
    });
  }

  /// Fetch the documents for this query
  @override
  Future<QuerySnapshotPlatform> get([GetOptions options]) async {
    final Map<dynamic, dynamic> data =
        await MethodChannelFirestore.channel.invokeMapMethod<String, dynamic>(
      'Query#getDocuments',
      <String, dynamic>{
        'appName': firestore.app.name,
        'path': _pointer.path,
        'isCollectionGroup': isCollectionGroup,
        'parameters': parameters,
        'source': getSourceString(options.source),
      },
    );

    return MethodChannelQuerySnapshot(firestore, data);
  }

  @override
  QueryPlatform limit(int limit) {
    assert(limit > 0, "limit must be a positive number greater than 0");
    return _copyWithParameters(<String, dynamic>{
      'limit': limit,
      'limitToLast': null,
    });
  }

  @override
  QueryPlatform limitToLast(int limit) {
    assert(limit > 0, "limit must be a positive number greater than 0");
    return _copyWithParameters(<String, dynamic>{
      'limit': null,
      'limitToLast': limit,
    });
  }

  // TODO(jackson): Reduce code duplication with [DocumentReference]
  @override
  Stream<QuerySnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
  }) {
    assert(includeMetadataChanges != null);
    Future<int> _handle;
    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    StreamController<QuerySnapshotPlatform> controller; // ignore: close_sinks
    controller = StreamController<QuerySnapshotPlatform>.broadcast(
      onListen: () {
        _handle = MethodChannelFirestore.channel.invokeMethod<int>(
          'Query#addSnapshotListener',
          <String, dynamic>{
            'app': firestore.app.name,
            'path': _pointer.path,
            'isCollectionGroup': isCollectionGroup,
            'parameters': parameters,
            'includeMetadataChanges': includeMetadataChanges,
          },
        ).then<int>((dynamic result) => result);
        _handle.then((int handle) {
          MethodChannelFirestore.queryObservers[handle] = controller;
        });
      },
      onCancel: () {
        _handle.then((int handle) async {
          await MethodChannelFirestore.channel.invokeMethod<void>(
            'removeListener',
            <String, dynamic>{'handle': handle},
          );
          MethodChannelFirestore.queryObservers.remove(handle);
        });
      },
    );
    return controller.stream;
  }

  @override
  QueryPlatform orderBy(
    field, {
    bool descending = false,
  }) {
    assert(field != null && descending != null);
    assert(field is String || field is FieldPath,
        'Supported [field] types are [String] and [FieldPath].');
    assert(!_hasStartCursor(),
        "Invalid query. You must not call startAt(), startAtDocument(), startAfter() or startAfterDocument() before calling orderBy()");
    assert(!_hasEndCursor(),
        "Invalid query. You must not call endAt(), endAtDocument(), endBefore() or endBeforeDocument() before calling orderBy()");

    final List<List<dynamic>> orders =
        List<List<dynamic>>.from(parameters['orderBy']);

    assert(orders.where((List<dynamic> item) => field == item[0]).isEmpty,
        "OrderBy field '$field' already exists in this query");

    orders.add([field, descending]);

    final List<List<dynamic>> conditions =
        List<List<dynamic>>.from(parameters['where']);

    if (conditions.isNotEmpty) {
      for (dynamic condition in conditions) {
        dynamic field = condition[0];
        String operator = condition[1];

        // Initial orderBy() parameter has to match every where() fieldPath parameter when
        // inequality operator is invoked
        if (operator == '<' ||
            operator == '<=' ||
            operator == '>' ||
            operator == '>=') {
          assert(field == orders[0][0],
              "The initial orderBy() field '$orders[0][0]' has to be the same as the where() field parameter '$field' when an inequality operator is invoked.");
        }

        for (dynamic order in orders) {
          dynamic orderField = order[0];

          // Any where() fieldPath parameter cannot match any orderBy() parameter when
          // '==' operand is invoked
          if (operator == '==') {
            assert(field != orderField,
                "The '$orderField' cannot be the same as your where() field parameter '$field'.");
          }

          if (field == FieldPath.documentId) {
            assert(orderField == FieldPath.documentId,
                "'[FieldPath.documentId]' cannot be used in conjunction with a different orderBy() parameter.");
          }
        }
      }
    }

    return _copyWithParameters(<String, dynamic>{'orderBy': orders});
  }

  @override
  QueryPlatform startAfterDocument(DocumentSnapshotPlatform documentSnapshot) {
    Map<String, dynamic> result = _handleSnapshotCursorQuery(documentSnapshot);

    return _copyWithParameters(<String, dynamic>{
      'orderBy': result['orders'],
      'startAt': null,
      'startAtDocument': null,
      'startAfter': null,
      'startAfterDocument': <String, dynamic>{
        'id': documentSnapshot.id,
        'path': documentSnapshot.reference.path,
        'values': result['values'],
      },
    });
  }

  @override
  QueryPlatform startAfter(List<dynamic> fields) {
    Map<String, dynamic> result = _handleCursorQuery(fields);

    return _copyWithParameters(<String, dynamic>{
      'startAt': null,
      'startAtDocument': null,
      'startAfter': result['values'],
      'startAfterDocument': null,
    });
  }

  @override
  QueryPlatform startAtDocument(DocumentSnapshotPlatform documentSnapshot) {
    Map<String, dynamic> result = _handleSnapshotCursorQuery(documentSnapshot);

    return _copyWithParameters(<String, dynamic>{
      'orderBy': result['orders'],
      'startAt': null,
      'startAtDocument': <String, dynamic>{
        'id': documentSnapshot.id,
        'path': documentSnapshot.reference.path,
        'values': result['values'],
      },
      'startAfter': null,
      'startAfterDocument': null,
    });
  }

  @override
  QueryPlatform startAt(List<dynamic> fields) {
    Map<String, dynamic> result = _handleCursorQuery(fields);

    return _copyWithParameters(<String, dynamic>{
      'startAt': result['values'],
      'startAtDocument': null,
      'startAfter': null,
      'startAfterDocument': null,
    });
  }

  @override
  QueryPlatform where(
    field, {
    isEqualTo,
    isLessThan,
    isLessThanOrEqualTo,
    isGreaterThan,
    isGreaterThanOrEqualTo,
    arrayContains,
    List arrayContainsAny,
    List whereIn,
    bool isNull,
  }) {
    assert(field is String || field is FieldPath,
        'Supported [field] types are [String] and [FieldPath].');

    final ListEquality<dynamic> equality = const ListEquality<dynamic>();
    final List<List<dynamic>> conditions =
        List<List<dynamic>>.from(parameters['where']);

    void addCondition(dynamic field, String operator, dynamic value) {
      FieldPath fieldPath =
          field is String ? FieldPath.fromString(field) : field as FieldPath;
      final List<dynamic> condition = <dynamic>[fieldPath, operator, value];
      assert(
          conditions
              .where((List<dynamic> item) => equality.equals(condition, item))
              .isEmpty,
          'Condition $condition already exists in this query.');
      conditions.add(condition);
    }

    if (isEqualTo != null) addCondition(field, '==', isEqualTo);
    if (isLessThan != null) addCondition(field, '<', isLessThan);
    if (isLessThanOrEqualTo != null) {
      addCondition(field, '<=', isLessThanOrEqualTo);
    }
    if (isGreaterThan != null) addCondition(field, '>', isGreaterThan);
    if (isGreaterThanOrEqualTo != null) {
      addCondition(field, '>=', isGreaterThanOrEqualTo);
    }
    if (arrayContains != null) {
      addCondition(field, 'array-contains', arrayContains);
    }
    if (arrayContainsAny != null) {
      addCondition(field, 'array-contains-any', arrayContainsAny);
    }
    if (whereIn != null) addCondition(field, 'in', whereIn);
    if (isNull != null) {
      assert(
          isNull,
          'isNull can only be set to true. '
          'Use isEqualTo to filter on non-null values.');
      addCondition(field, '==', null);
    }

    dynamic hasInequality;
    bool hasIn = false;
    bool hasArrayContains = false;
    bool hasArrayContainsAny = false;

    // Once all conditions have been set, we must now check them to ensure the
    // query is valid.
    for (dynamic condition in conditions) {
      FieldPath field = condition[0];
      String operator = condition[1];
      dynamic value = condition[2];

      if (value == null) {
        assert(operator == '==',
            'You can only perform equals comparisons on null.');
      }

      if (operator == 'in' || operator == 'array-contains-any') {
        assert(value is List,
            "A non-empty [List] is required for '$operator' filters.");
        assert((value as List).length <= 10,
            "'$operator' filters support a maximum of 10 elements in the value [List].");
        assert((value as List).isNotEmpty,
            "'$operator' filters require a non-empty [List].");
        assert((value as List).where((value) => value == null).isEmpty,
            "'$operator' filters cannot contain 'null' in the [List].");
      }

      if (operator == 'in') {
        assert(!hasIn, "You cannot use 'in' filters more than once.");
        hasIn = true;
      }

      if (operator == 'array-contains') {
        assert(!hasArrayContains, "You cannot use 'array-contains' filters more than once.");
        hasArrayContains = true;
      }

      if (operator == 'array-contains-any') {
        assert(!hasArrayContainsAny, "You cannot use 'array-contains-any' filters more than once.");
        hasArrayContainsAny = true;
      }

      if (operator == 'array-contains-any' || operator == 'in') {
        assert(!(hasIn && hasArrayContainsAny), "You cannot use 'in' filters with 'array-contains-any' filters.");
      }

      if (operator == 'array-contains' || operator == 'array-contains-any') {
        assert(!(hasArrayContains && hasArrayContainsAny),
            "You cannot use both 'array-contains-any' or 'array-contains' filters together.");
      }

      if (operator == '<' ||
          operator == '<=' ||
          operator == '>' ||
          operator == '>=') {
        if (hasInequality == null) {
          hasInequality = field;
        } else {
          assert(hasInequality == field,
              "All where filters with an inequality (<, <=, >, or >=) must be on the same field. But you have inequality filters on '$hasInequality' and '$field'.");
        }
      }
    }

    return _copyWithParameters(<String, dynamic>{'where': conditions});
  }
}
