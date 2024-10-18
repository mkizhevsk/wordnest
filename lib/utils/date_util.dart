import 'package:intl/intl.dart';
import 'package:wordnest/assets/constants.dart' as constants;

class DateUtil {
  static DateTime stringToDateTime(String dateTimeString) {
    final DateFormat format = DateFormat('yyyy-MM-ddTHH:mm:ss');
    return format.parse(dateTimeString);
  }

  static String dateTimeToString(DateTime dateTime) {
    final DateFormat format = DateFormat('yyyy-MM-ddTHH:mm:ss');
    return format.format(dateTime);
  }

  static getMobileToServerTimeDifference() {
    // Get current local time
    DateTime localTime = DateTime.now();

    // Get current UTC time
    DateTime utcTime = DateTime.now().toUtc();

    // Calculate the difference
    Duration timeDifference = localTime.difference(utcTime);
    print(
        'Time difference between local time and UTC: ${timeDifference.inHours} hours');

    return timeDifference.inHours -
        constants.serverTimeDifferenceHours; // 4 - 3 = 1
  }

  static DateTime getMobileTimeConvertedToServer(DateTime mobileDateTime) {
    // Subtract the time difference between local and UTC from the mobile time
    int mobileTimeDifference = getMobileToServerTimeDifference();
    return mobileDateTime
        .subtract(Duration(hours: mobileTimeDifference)); // 4 - 1 = 3
  }
}
