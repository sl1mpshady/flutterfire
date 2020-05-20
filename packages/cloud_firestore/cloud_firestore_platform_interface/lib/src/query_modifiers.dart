// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//class QueryModifiers {
//  final int limit;
//  final List<dynamic> filters;
//
//  QueryModifiers({this.limit, this.filters});
//
//  Map<String, dynamic> get asMap {
//    return {
//      'limit': limit,
//      'filters': filters,
//    };
//  }
//
//  factory QueryModifiers._clone(
//    QueryModifiers modifiers, {
//    int limit,
//    List filter,
//  }) {
//    return QueryModifiers(
//      limit: limit ?? modifiers.limit,
//      filters: filter != null ? [] : modifiers.filters,
//    );
//  }
//
//  QueryModifiers withLimit(int limit) {
//    return QueryModifiers._clone(this, limit: limit);
//  }
//
//  QueryModifiers withWhere(
//    dynamic field, {
//    dynamic isEqualTo,
//    dynamic isLessThan,
//    dynamic isLessThanOrEqualTo,
//    dynamic isGreaterThan,
//    dynamic isGreaterThanOrEqualTo,
//    dynamic arrayContains,
//    List<dynamic> arrayContainsAny,
//    List<dynamic> whereIn,
//    bool isNull,
//  }) {
//
//  }
//}
