package io.flutter.plugins.firebase.cloudfirestore;

import com.google.firebase.FirebaseApp;
import com.google.firebase.Timestamp;
import com.google.firebase.firestore.Blob;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreSettings;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.Query;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

class CloudFirestoreMessageCodec extends StandardMessageCodec {
  public static final CloudFirestoreMessageCodec INSTANCE = new CloudFirestoreMessageCodec();

  private static final byte DATA_TYPE_DATE_TIME = (byte) 128;
  private static final byte DATA_TYPE_GEO_POINT = (byte) 129;
  private static final byte DATA_TYPE_DOCUMENT_REFERENCE = (byte) 130;
  private static final byte DATA_TYPE_BLOB = (byte) 131;
  private static final byte DATA_TYPE_ARRAY_UNION = (byte) 132;
  private static final byte DATA_TYPE_ARRAY_REMOVE = (byte) 133;
  private static final byte DATA_TYPE_DELETE = (byte) 134;
  private static final byte DATA_TYPE_SERVER_TIMESTAMP = (byte) 135;
  private static final byte DATA_TYPE_TIMESTAMP = (byte) 136;
  private static final byte DATA_TYPE_INCREMENT_DOUBLE = (byte) 137;
  private static final byte DATA_TYPE_INCREMENT_INTEGER = (byte) 138;
  private static final byte DATA_TYPE_DOCUMENT_ID = (byte) 139;
  private static final byte DATA_TYPE_FIELD_PATH = (byte) 140;

  // TODO
  private static final byte DATA_TYPE_NAN = (byte) 141;
  private static final byte DATA_TYPE_INFINITY = (byte) 142;
  private static final byte DATA_TYPE_NEGATIVE_INFINITY = (byte) 143;

  private static final byte DATA_TYPE_FIRESTORE_INSTANCE = (byte) 144;
  private static final byte DATA_TYPE_FIRESTORE_QUERY = (byte) 145;
  private static final byte DATA_TYPE_FIRESTORE_SETTINGS = (byte) 146;

  @Override
  protected void writeValue(ByteArrayOutputStream stream, Object value) {
    if (value instanceof Date) {
      stream.write(DATA_TYPE_DATE_TIME);
      writeLong(stream, ((Date) value).getTime());
    } else if (value instanceof Timestamp) {
      stream.write(DATA_TYPE_TIMESTAMP);
      writeLong(stream, ((Timestamp) value).getSeconds());
      writeInt(stream, ((Timestamp) value).getNanoseconds());
    } else if (value instanceof GeoPoint) {
      stream.write(DATA_TYPE_GEO_POINT);
      writeAlignment(stream, 8);
      writeDouble(stream, ((GeoPoint) value).getLatitude());
      writeDouble(stream, ((GeoPoint) value).getLongitude());
    } else if (value instanceof DocumentReference) {
      stream.write(DATA_TYPE_DOCUMENT_REFERENCE);
      writeValue(stream, ((DocumentReference) value).getFirestore().getApp().getName());
      writeValue(stream, ((DocumentReference) value).getPath());
    } else if (value instanceof Blob) {
      stream.write(DATA_TYPE_BLOB);
      writeBytes(stream, ((Blob) value).toBytes());
    } else if (value instanceof Double) {
      Double doubleValue = (Double) value;
      if (Double.isNaN(doubleValue)) {
        stream.write(DATA_TYPE_NAN);
      } else if (doubleValue.equals(Double.NEGATIVE_INFINITY)) {
        stream.write(DATA_TYPE_NEGATIVE_INFINITY);
      } else if (doubleValue.equals(Double.POSITIVE_INFINITY)) {
        stream.write(DATA_TYPE_INFINITY);
      } else {
        super.writeValue(stream, value);
      }
    } else {
      super.writeValue(stream, value);
    }
  }

  @Override
  protected Object readValueOfType(byte type, ByteBuffer buffer) {
    switch (type) {
      case DATA_TYPE_DATE_TIME:
        return new Date(buffer.getLong());
      case DATA_TYPE_TIMESTAMP:
        return new Timestamp(buffer.getLong(), buffer.getInt());
      case DATA_TYPE_GEO_POINT:
        readAlignment(buffer, 8);
        return new GeoPoint(buffer.getDouble(), buffer.getDouble());
      case DATA_TYPE_DOCUMENT_REFERENCE:
        String appName = (String) readValue(buffer);
        final FirebaseFirestore firestore =
            FirebaseFirestore.getInstance(FirebaseApp.getInstance(appName));
        final String path = (String) readValue(buffer);
        return firestore.document(path);
      case DATA_TYPE_BLOB:
        final byte[] bytes = readBytes(buffer);
        return Blob.fromBytes(bytes);
      case DATA_TYPE_ARRAY_UNION:
        return FieldValue.arrayUnion(toArray(readValue(buffer)));
      case DATA_TYPE_ARRAY_REMOVE:
        return FieldValue.arrayRemove(toArray(readValue(buffer)));
      case DATA_TYPE_DELETE:
        return FieldValue.delete();
      case DATA_TYPE_SERVER_TIMESTAMP:
        return FieldValue.serverTimestamp();
      case DATA_TYPE_INCREMENT_INTEGER:
        final Number integerIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(integerIncrementValue.intValue());
      case DATA_TYPE_INCREMENT_DOUBLE:
        final Number doubleIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(doubleIncrementValue.doubleValue());
      case DATA_TYPE_DOCUMENT_ID:
        return FieldPath.documentId();
      case DATA_TYPE_FIRESTORE_INSTANCE:
        return readFirestoreInstance(buffer);
      case DATA_TYPE_FIRESTORE_QUERY:
        return readFirestoreQuery(buffer);
      case DATA_TYPE_FIRESTORE_SETTINGS:
        return readFirestoreSettings(buffer);
      case DATA_TYPE_NAN:
        return Double.NaN;
      case DATA_TYPE_INFINITY:
        return Double.POSITIVE_INFINITY;
      case DATA_TYPE_NEGATIVE_INFINITY:
        return Double.NEGATIVE_INFINITY;
      case DATA_TYPE_FIELD_PATH:
        final int size = readSize(buffer);
        final List<Object> list = new ArrayList<>(size);
        for (int i = 0; i < size; i++) {
          list.add(readValue(buffer));
        }
        return FieldPath.of((String[]) list.toArray(new String[0]));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  private FirebaseFirestore readFirestoreInstance(ByteBuffer buffer) {
    // TODO
    return null;
  }

  private FirebaseFirestoreSettings readFirestoreSettings(ByteBuffer buffer) {
    // TODO
    return null;
  }

  private Query readFirestoreQuery(ByteBuffer buffer) {
    // TODO
    return null;
  }

  private Object[] toArray(Object source) {
    if (source instanceof List) {
      return ((List<?>) source).toArray();
    }

    if (source == null) {
      return new ArrayList<>().toArray();
    }

    String sourceType = source.getClass().getCanonicalName();
    String message = "java.util.List was expected, unable to convert '%s' to an object array";
    throw new IllegalArgumentException(String.format(message, sourceType));
  }
}
