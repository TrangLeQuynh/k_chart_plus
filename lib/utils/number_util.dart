import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class NumberUtil {
  static String formatCompact(double n, [ int precision  = 2 ]) {
    try {
      if (n >= 1e9) {
        n /= 1e9;
        return "${n.toStringAsFixed(precision)}B";
      } else if (n >= 1e6) {
        n /= 1e6;
        return "${n.toStringAsFixed(precision)}M";
      } else if (n >= 1e4) {
        n /= 1e3;
        return "${n.toStringAsFixed(precision)}K";
      } else {
        return n.toStringAsFixed(precision);
      }
    } catch(e) {
      return n.toString();
    }
  }

  // static int getDecimalLength(double b) {
  //   String s = b.toString();
  //   int dotIndex = s.indexOf(".");
  //   if (dotIndex < 0) {
  //     return 0;
  //   } else {
  //     return s.length - dotIndex - 1;
  //   }
  // }
  //
  // static int getMaxDecimalLength(double a, double b, double c, double d) {
  //   int result = max(getDecimalLength(a), getDecimalLength(b));
  //   result = max(result, getDecimalLength(c));
  //   result = max(result, getDecimalLength(d));
  //   return result;
  // }

  static bool checkNotNullOrZero(double? a) {
    if (a == null || a == 0) {
      return false;
    } else if (a.abs().toStringAsFixed(4) == "0.0000") {
      return false;
    } else {
      return true;
    }
  }

  static String? formatFixed(dynamic value, int precision, [String pattern = '#,##0']) {
    try {
      String number = Decimal.parse(value.toString()).toString(); // avoid scientific notation format e-10
      List<String> parts = number.split('.');
      String integerPart = NumberFormat(pattern, 'en_US').format(num.parse(parts.first));
      if (precision == 0) {
        return integerPart;
      }
      String fractionalPart = (parts.length <= 1 ? '' : parts.last).padRight(precision, '0');
      fractionalPart = fractionalPart.substring(0, precision);
      return '$integerPart.$fractionalPart';
    } catch(e) {
      return null;
    }
  }

  static String? format(dynamic value, int precision, [String pattern = '#,##0']) {
    try {
      // avoid scientific notation format e-10
      String number = Decimal.parse(value.toString()).floor(scale: precision).toString();
      List<String> parts = number.split('.');
      String integerPart = NumberFormat(pattern, 'en_US').format(num.parse(parts.first));
      if (precision == 0 && parts.length == 1) {
        return integerPart;
      }
      String fractionalPart = parts.last;
      return '$integerPart.$fractionalPart';
    } catch(e) {
      return null;
    }
  }
}
