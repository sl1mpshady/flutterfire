// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Returns a [List] containing detailed output of each line in a stack trace.
List<Map<String, String>> getStackTraceElements(List<String> lines) {
  final List<Map<String, String>> elements = <Map<String, String>>[];

  for (String line in lines) {
    final List<String> lineParts = line.split(RegExp('\\s+'));

    try {
      final String fileName = lineParts[0];
      final String lineNumber = lineParts[1].contains(":")
          ? lineParts[1].substring(0, lineParts[1].indexOf(":")).trim()
          : lineParts[1];

      final Map<String, String> element = <String, String>{
        'file': fileName,
        'line': lineNumber,
      };

      // The next section would throw an exception in some cases if there was no stop here.
      if (lineParts.length < 3) {
        elements.add(element);
        continue;
      }

      if (lineParts[2].contains(".")) {
        final String className =
            lineParts[2].substring(0, lineParts[2].indexOf(".")).trim();
        final String methodName =
            lineParts[2].substring(lineParts[2].indexOf(".") + 1).trim();

        element['class'] = className;
        element['method'] = methodName;
      } else {
        element['method'] = lineParts[2];
      }

      elements.add(element);
    } catch (e) {
      print(e.toString());
    }
  }

  return elements;
}
