/// Date utilities for Sports Academy App
class DateUtilsHelper {
  DateUtilsHelper._();

  /// Safely parses timezone-agnostic SQL date strings (YYYY-MM-DD)
  /// into a local DateTime instance to prevent timezone shifting in UI.
  static DateTime parseSqlDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    // Fallback if formatting doesn't match YYYY-MM-DD
    return DateTime.parse(dateStr).toLocal();
  }
}
