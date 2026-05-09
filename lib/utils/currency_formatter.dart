import 'package:flutter/services.dart';

/// Formats integer input with thousand-separator dots (Indonesian style)
/// e.g. typing 1000000 → displays 1.000.000
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits
    final digits = newValue.text.replaceAll('.', '').replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove leading zeros
    final clean = digits.replaceFirst(RegExp(r'^0+'), '');
    if (clean.isEmpty) return newValue.copyWith(text: '0');

    // Insert dots every 3 digits from right
    final formatted = _insertDots(clean);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _insertDots(String s) {
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  /// Strip formatting dots to get raw integer string for parsing
  static String toRaw(String formatted) => formatted.replaceAll('.', '');
}
