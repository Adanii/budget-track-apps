import 'package:flutter/material.dart';
import 'package:fin_track/core/theme.dart';

class PaymentUtils {
  static Widget getPaymentIcon(String method, BuildContext context, {double size = 20}) {
    final color = getPaymentColor(method, context);

    // Generic methods use standard icons
    if (method == 'Cash') {
      return Icon(Icons.payments_rounded, color: color, size: size);
    } else if (method == 'QR') {
      return Icon(Icons.qr_code_2_rounded, color: color, size: size);
    } else if (method == 'Debit') {
      return Icon(Icons.credit_card_rounded, color: color, size: size);
    }

    // Banks use custom typography monograms
    String initial = method.isNotEmpty ? method[0] : '?';
    if (method == 'BCA') {
      initial = 'BCA';
    } else if (method == 'Mandiri') {
      initial = 'Mandiri';
    } else if (method == 'GoPay') {
      initial = 'GoPay';
    } else if (method == 'SeaBank') {
      initial = 'SeaBank';
    } else if (method == 'Bank Jago') {
      initial = 'Bank\nJago';
    } else if (method == 'Superbank') {
      initial = 'Superbank';
    }

    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Outfit', // Uses the GoogleFont loaded globally
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: initial.length > 2 ? size * 0.45 : size * 0.8,
          height: 1.0,
          letterSpacing: initial.length > 2 ? -0.5 : 0,
        ),
        textAlign: TextAlign.center,
        maxLines: initial.contains('\n') ? 2 : 1,
      ),
    );
  }

  static Color getPaymentColor(String method, BuildContext context) {
    switch (method) {
      case 'Mandiri':
        return Colors.amber;
      case 'BCA':
        return Colors.blueAccent;
      case 'GoPay':
        return Colors.greenAccent;
      case 'SeaBank':
        return Colors.orangeAccent;
      case 'Superbank':
        return Colors.purpleAccent;
      case 'Bank Jago':
        return Colors.tealAccent;
      case 'Cash':
        return context.colors.warning;
      case 'QR':
        return context.colors.info;
      case 'Debit':
        return Colors.purpleAccent;
      default:
        return const Color(0xFF8B9597);
    }
  }
}
