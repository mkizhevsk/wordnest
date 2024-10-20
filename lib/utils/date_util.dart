import 'package:intl/intl.dart';

class DateUtil {
  static DateTime stringToDateTime(String dateTimeString) {
    final DateFormat format = DateFormat('yyyy-MM-ddTHH:mm:ss');
    return format.parse(dateTimeString);
  }

  static String dateTimeToString(DateTime dateTime) {
    final DateFormat format = DateFormat('yyyy-MM-ddTHH:mm:ss');
    return format.format(dateTime);
  }

  static DateTime trimAndConvertToDateTime(
      DateTime dateTimeToTrim, DateTime referenceDateTime) {
    // Step 1: Format both DateTimes to strings
    DateFormat formatterWithMicroseconds =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS');
    DateFormat formatterWithMilliseconds =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    // Convert reference DateTime to String (this has 3 decimal places for milliseconds)
    String referenceDateTimeStr =
        formatterWithMilliseconds.format(referenceDateTime);

    // Convert the second DateTime (with Z) to String, and remove the "Z"
    String dateTimeToTrimStr =
        formatterWithMicroseconds.format(dateTimeToTrim).replaceAll('Z', '');

    // Step 2: Trim the second string to match the length of the first one
    String trimmedDateTimeStr =
        dateTimeToTrimStr.substring(0, referenceDateTimeStr.length);

    // Step 3: Parse the trimmed string back into a DateTime object
    return formatterWithMilliseconds.parse(trimmedDateTimeStr);
  }
}
