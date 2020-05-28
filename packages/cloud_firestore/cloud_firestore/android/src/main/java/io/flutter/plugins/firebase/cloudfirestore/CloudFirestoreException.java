package io.flutter.plugins.firebase.cloudfirestore;

import com.google.firebase.firestore.FirebaseFirestoreException;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

class CloudFirestoreException extends Exception {

  private static String kABORTED =
      "The operation was aborted, typically due to a concurrency issue like transaction aborts, etc.";
  private static String kALREADY_EXISTS =
      "Some document that we attempted to create already exists.";
  private static String kCANCELLED = "The operation was cancelled (typically by the caller).";
  private static String kDATA_LOSS = "Unrecoverable data loss or corruption.";
  private static String kDEADLINE_EXCEEDED =
      "Deadline expired before operation could complete. For operations that change the state of the system, this error may be returned even if the operation has completed successfully. For example, a successful response from a server could have been delayed long enough for the deadline to expire.";
  private static String kFAILED_PRECONDITION =
      "Operation was rejected because the system is not in a state required for the operation's execution. Ensure your query has been indexed via the Firebase console.";
  private static String kINTERNAL =
      "Internal errors. Means some invariants expected by underlying system has been broken. If you see one of these errors, something is very broken.";
  private static String kINVALID_ARGUMENT =
      "Client specified an invalid argument. Note that this differs from failed-precondition. invalid-argument indicates arguments that are problematic regardless of the state of the system (e.g., an invalid field name).";
  private static String kNOT_FOUND = "Some requested document was not found.";
  private static String kOUT_OF_RANGE = "Operation was attempted past the valid range.";
  private static String kPERMISSION_DENIED =
      "The caller does not have permission to execute the specified operation.";
  private static String kRESOURCE_EXHAUSTED =
      "Some resource has been exhausted, perhaps a per-user quota, or perhaps the entire file system is out of space.";
  private static String kUNAUTHENTICATED =
      "The request does not have valid authentication credentials for the operation.";
  private static String kUNAVAILABLE =
      "The service is currently unavailable. This is a most likely a transient condition and may be corrected by retrying with a backoff.";
  private static String kUNIMPLEMENTED = "Operation is not implemented or not supported/enabled.";
  private static String kUNKNOWN = "Operation is not implemented or not supported/enabled.";

  private final String code;
  private final String message;

  CloudFirestoreException(FirebaseFirestoreException nativeException, Throwable cause) {
    super(nativeException != null ? nativeException.getMessage() : "", cause);

    String code = null;
    String message = null;

    if (cause != null && cause.getMessage() != null && cause.getMessage().contains(":")) {
      String causeMessage = cause.getMessage();
      Matcher matcher = Pattern.compile("([A-Z_]{3,25}):\\s(.*)").matcher(causeMessage);

      if (matcher.find()) {
        String foundCode = matcher.group(1).trim();
        String foundMessage = matcher.group(2).trim();
        switch (foundCode) {
          case "ABORTED":
            code = "aborted";
            message = kABORTED;
            break;
          case "ALREADY_EXISTS":
            code = "already-exists";
            message = kALREADY_EXISTS;
            break;
          case "CANCELLED":
            code = "cancelled";
            message = kCANCELLED;
            break;
          case "DATA_LOSS":
            code = "data-loss";
            message = kDATA_LOSS;
            break;
          case "DEADLINE_EXCEEDED":
            code = "deadline-exceeded";
            message = kDEADLINE_EXCEEDED;
            break;
          case "FAILED_PRECONDITION":
            code = "failed-precondition";
            if (foundMessage.contains("query requires an index")) {
              message = foundMessage;
            } else {
              message = kFAILED_PRECONDITION;
            }
            break;
          case "INTERNAL":
            code = "internal";
            message = kINTERNAL;
            break;
          case "INVALID_ARGUMENT":
            code = "invalid-argument";
            message = kINVALID_ARGUMENT;
            break;
          case "NOT_FOUND":
            code = "not-found";
            message = kNOT_FOUND;
            break;
          case "OUT_OF_RANGE":
            code = "out-of-range";
            message = kOUT_OF_RANGE;
            break;
          case "PERMISSION_DENIED":
            code = "permission-denied";
            message = kPERMISSION_DENIED;
            break;
          case "RESOURCE_EXHAUSTED":
            code = "resource-exhausted";
            message = kRESOURCE_EXHAUSTED;
            break;
          case "UNAUTHENTICATED":
            code = "unauthenticated";
            message = kUNAUTHENTICATED;
            break;
          case "UNAVAILABLE":
            code = "unavailable";
            message = kUNAVAILABLE;
            break;
          case "UNIMPLEMENTED":
            code = "unimplemented";
            message = kUNIMPLEMENTED;
            break;
          case "UNKNOWN":
            code = "unknown";
            message = kUNKNOWN;
            break;
        }
      }
    }

    if (code == null && nativeException != null) {
      switch (nativeException.getCode()) {
        case ABORTED:
          code = "aborted";
          message = kABORTED;
          break;
        case ALREADY_EXISTS:
          code = "already-exists";
          message = kALREADY_EXISTS;
          break;
        case CANCELLED:
          code = "cancelled";
          message = kCANCELLED;
          break;
        case DATA_LOSS:
          code = "data-loss";
          message = kDATA_LOSS;
          break;
        case DEADLINE_EXCEEDED:
          code = "deadline-exceeded";
          message = kDEADLINE_EXCEEDED;
          break;
        case FAILED_PRECONDITION:
          code = "failed-precondition";
          if (nativeException.getMessage() != null
              && nativeException.getMessage().contains("query requires an index")) {
            message = nativeException.getMessage();
          } else {
            message = kFAILED_PRECONDITION;
          }
          break;
        case INTERNAL:
          code = "internal";
          message = kINTERNAL;
          break;
        case INVALID_ARGUMENT:
          code = "invalid-argument";
          message = kINVALID_ARGUMENT;
          break;
        case NOT_FOUND:
          code = "not-found";
          message = kNOT_FOUND;
          break;
        case OUT_OF_RANGE:
          code = "out-of-range";
          message = kOUT_OF_RANGE;
          break;
        case PERMISSION_DENIED:
          code = "permission-denied";
          message = kPERMISSION_DENIED;
          break;
        case RESOURCE_EXHAUSTED:
          code = "resource-exhausted";
          message = kRESOURCE_EXHAUSTED;
          break;
        case UNAUTHENTICATED:
          code = "unauthenticated";
          message = kUNAUTHENTICATED;
          break;
        case UNAVAILABLE:
          code = "unavailable";
          message = kUNAVAILABLE;
          break;
        case UNIMPLEMENTED:
          code = "unimplemented";
          message = kUNIMPLEMENTED;
          break;
        case UNKNOWN:
          code = "unknown";
          message = "Unknown error or an error from a different error domain.";
          break;
        default:
          // Even though UNKNOWN exists, this is a fallback
          code = "unknown";
          message = "An unknown error occurred";
      }
    }

    this.code = code;
    this.message = message;
  }

  public String getCode() {
    return code;
  }

  @Override
  public String getMessage() {
    return message;
  }
}
