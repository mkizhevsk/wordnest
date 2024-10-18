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

  int getLocalTimeDifference() {
    // Get current local time
    DateTime localTime = DateTime.now();

    // Get current UTC time
    DateTime utcTime = DateTime.now().toUtc();

    // Calculate the difference
    Duration timeDifference = localTime.difference(utcTime);
    print('Time difference between local time and UTC: ${timeDifference.inHours} hours');

    return timeDifference.inHours;
  }

  
}
