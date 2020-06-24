import 'package:flutter/foundation.dart';

class SAMLAuthProvider implements AuthProvider {
  const SAMLAuthProvider({@required this.providerId})
      : assert(providerId != null);

  final String providerId;
}
