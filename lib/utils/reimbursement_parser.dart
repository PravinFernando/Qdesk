class ReimbursementParser {

  // Extract amount
  static double extractAmount(String text) {
    final regex = RegExp(r'(\d+\.\d+|\d+)');

    final matches = regex.allMatches(text);

    double highest = 0;

    for (final match in matches) {
      final value = double.tryParse(match.group(0)!);

      if (value != null && value > highest) {
        highest = value;
      }
    }

    return highest;
  }

  // Extract date
  static String extractDate(String text) {
    final regex = RegExp(r'(\d{2}/\d{2}/\d{4})');

    final match = regex.firstMatch(text);

    if (match != null) {
      return match.group(0)!;
    }

    return DateTime.now().toString().substring(0, 10);
  }

  // Extract merchant
  static String extractMerchant(String text) {
    final lines = text.split('\n');

    for (final line in lines) {
      if (line.trim().length > 3) {
        return line.trim();
      }
    }

    return "Unknown";
  }

  // Future date validation
  static bool isFutureDate(String date) {
    try {
      final parts = date.split('/');

      final parsedDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      return parsedDate.isAfter(DateTime.now());

    } catch (e) {
      return false;
    }
  }
}