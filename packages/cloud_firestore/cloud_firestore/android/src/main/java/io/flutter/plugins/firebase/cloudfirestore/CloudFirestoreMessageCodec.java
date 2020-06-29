package io.flutter.plugins.firebase.cloudfirestore;

import com.google.firebase.FirebaseApp;
import com.google.firebase.Timestamp;
import com.google.firebase.firestore.Blob;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldPath;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.GeoPoint;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

class CloudFirestoreMessageCodec extends StandardMessageCodec {
  public static final CloudFirestoreMessageCodec INSTANCE = new CloudFirestoreMessageCodec();

  private static final Charset UTF8 = Charset.forName("UTF8");
  private static final byte DATE_TIME = (byte) 128;
  private static final byte GEO_POINT = (byte) 129;
  private static final byte DOCUMENT_REFERENCE = (byte) 130;
  private static final byte BLOB = (byte) 131;
  private static final byte ARRAY_UNION = (byte) 132;
  private static final byte ARRAY_REMOVE = (byte) 133;
  private static final byte DELETE = (byte) 134;
  private static final byte SERVER_TIMESTAMP = (byte) 135;
  private static final byte TIMESTAMP = (byte) 136;
  private static final byte INCREMENT_DOUBLE = (byte) 137;
  private static final byte INCREMENT_INTEGER = (byte) 138;
  private static final byte DOCUMENT_ID = (byte) 139;
  private static final byte FIELD_PATH = (byte) 140;

  @Override
  protected void writeValue(ByteArrayOutputStream stream, Object value) {
    if (value instanceof Date) {
      stream.write(DATE_TIME);
      writeLong(stream, ((Date) value).getTime());
    } else if (value instanceof Timestamp) {
      stream.write(TIMESTAMP);
      writeLong(stream, ((Timestamp) value).getSeconds());
      writeInt(stream, ((Timestamp) value).getNanoseconds());
    } else if (value instanceof GeoPoint) {
      stream.write(GEO_POINT);
      writeAlignment(stream, 8);
      writeDouble(stream, ((GeoPoint) value).getLatitude());
      writeDouble(stream, ((GeoPoint) value).getLongitude());
    } else if (value instanceof DocumentReference) {
      stream.write(DOCUMENT_REFERENCE);
      writeBytes(
          stream, ((DocumentReference) value).getFirestore().getApp().getName().getBytes(UTF8));
      writeBytes(stream, ((DocumentReference) value).getPath().getBytes(UTF8));
    } else if (value instanceof Blob) {
      stream.write(BLOB);
      writeBytes(stream, ((Blob) value).toBytes());
    } else {
      super.writeValue(stream, value);
    }
  }

  @Override
  protected Object readValueOfType(byte type, ByteBuffer buffer) {
    switch (type) {
      case DATE_TIME:
        return new Date(buffer.getLong());
      case TIMESTAMP:
        return new Timestamp(buffer.getLong(), buffer.getInt());
      case GEO_POINT:
        readAlignment(buffer, 8);
        return new GeoPoint(buffer.getDouble(), buffer.getDouble());
      case DOCUMENT_REFERENCE:
        String appName = (String) readValue(buffer);
        final FirebaseFirestore firestore =
            FirebaseFirestore.getInstance(FirebaseApp.getInstance(appName));
        final String path = (String) readValue(buffer);
        return firestore.document(path);
      case BLOB:
        final byte[] bytes = readBytes(buffer);
        return Blob.fromBytes(bytes);
      case ARRAY_UNION:
        return FieldValue.arrayUnion(toArray(readValue(buffer)));
      case ARRAY_REMOVE:
        return FieldValue.arrayRemove(toArray(readValue(buffer)));
      case DELETE:
        return FieldValue.delete();
      case SERVER_TIMESTAMP:
        return FieldValue.serverTimestamp();
      case INCREMENT_INTEGER:
        final Number integerIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(integerIncrementValue.intValue());
      case INCREMENT_DOUBLE:
        final Number doubleIncrementValue = (Number) readValue(buffer);
        return FieldValue.increment(doubleIncrementValue.doubleValue());
      case DOCUMENT_ID:
        return FieldPath.documentId();
      case FIELD_PATH:
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

  private Object[] toArray(Object source) {
    if (source instanceof List) {
      return ((List<?>) source).toArray();
    }

    if (source == null) {
      return new Object[0];
    }

    String sourceType = source.getClass().getCanonicalName();
    String message = "java.util.List was expected, unable to convert '%s' to an object array";
    throw new IllegalArgumentException(String.format(message, sourceType));
  }
}
