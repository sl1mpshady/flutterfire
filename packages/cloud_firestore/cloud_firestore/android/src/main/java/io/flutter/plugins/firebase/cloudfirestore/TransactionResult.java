package io.flutter.plugins.firebase.cloudfirestore;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

class TransactionResult {
  final @Nullable Exception exception;
  final @Nullable Object result;

  private TransactionResult(@NonNull Exception exception) {
    this.exception = exception;
    this.result = null;
  }

  private TransactionResult(@Nullable Object result) {
    this.exception = null;
    this.result = result;
  }

  static TransactionResult fromException(@NonNull Exception exception) {
    return new TransactionResult(exception);
  }

  static TransactionResult setResult(@Nullable Object result) {
    return new TransactionResult(result);
  }
}
