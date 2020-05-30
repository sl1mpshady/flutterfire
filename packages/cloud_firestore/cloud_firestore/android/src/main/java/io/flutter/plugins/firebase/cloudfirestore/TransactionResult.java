package io.flutter.plugins.firebase.cloudfirestore;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

class TransactionResult {
  final @Nullable Exception exception;

  private TransactionResult(@NonNull Exception exception) {
    this.exception = exception;
  }

  private TransactionResult() {
    this.exception = null;
  }

  static TransactionResult fromException(@NonNull Exception exception) {
    return new TransactionResult(exception);
  }

  static TransactionResult complete() {
    return new TransactionResult();
  }
}
