import 'package:intl/intl.dart';

class UnitConverter {
  UnitConverter._();

  /// Converts inches to feet (e.g. 48" -> 4.00 ft)
  static double inchesToFeet(double inches) {
    if (inches <= 0) return 0.0;
    return inches / 12.0;
  }

  /// Calculates square feet from width and height in inches:
  /// (widthInches * heightInches) / 144.0
  static double calculateSqFt({
    required double widthInches,
    required double heightInches,
    int quantity = 1,
  }) {
    if (widthInches <= 0 || heightInches <= 0 || quantity <= 0) return 0.0;
    final singleWindowSqFt = (widthInches * heightInches) / 144.0;
    return singleWindowSqFt * quantity;
  }

  /// Calculates perimeter in running feet (e.g. for channel frames)
  /// 2 * (widthFt + heightFt) * quantity
  static double calculatePerimeterRunningFeet({
    required double widthInches,
    required double heightInches,
    int quantity = 1,
  }) {
    if (widthInches <= 0 || heightInches <= 0 || quantity <= 0) return 0.0;
    final wFt = inchesToFeet(widthInches);
    final hFt = inchesToFeet(heightInches);
    return 2 * (wFt + hFt) * quantity;
  }

  /// Format inches with clean notation (e.g., 48" or 48.5")
  static String formatInches(double inches) {
    if (inches == inches.roundToDouble()) {
      return '${inches.toInt()}"';
    }
    return '${inches.toStringAsFixed(1)}"';
  }

  /// Format feet (e.g., 4.00 ft)
  static String formatFeet(double feet) {
    return '${feet.toStringAsFixed(2)} ft';
  }

  /// Format square feet (e.g., 20.00 sq.ft)
  static String formatSqFt(double sqFt) {
    return '${sqFt.toStringAsFixed(2)} sq.ft';
  }

  /// Format Indian Rupee Currency (e.g., ₹12,450.00 or ₹12,450)
  static String formatCurrency(double amount, {bool showDecimals = false}) {
    try {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return formatter.format(amount);
    } catch (_) {
      return '₹${amount.toStringAsFixed(showDecimals ? 2 : 0)}';
    }
  }

  /// Neutralize leading formula-injection characters (=, +, -, @)
  static String sanitizeFormulaInjection(String input) {
    if (input.isEmpty) return input;
    final trimmed = input.trim();
    if (trimmed.startsWith('=') ||
        trimmed.startsWith('+') ||
        trimmed.startsWith('-') ||
        trimmed.startsWith('@')) {
      return "'$trimmed";
    }
    return trimmed;
  }
}
