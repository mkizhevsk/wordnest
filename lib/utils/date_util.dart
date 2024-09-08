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
}
