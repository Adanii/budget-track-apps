import 'package:flutter/material.dart';
import 'package:fin_track/core/theme.dart';

class PaymentUtils {
  static Widget getPaymentIcon(String method, {double size = 20}) {
    switch (method) {
      case 'Mandiri':
        return Icon(Icons.account_balance_rounded, color: Colors.amber, size: size);
      case 'BCA':
        return Icon(Icons.credit_card_rounded, color: Colors.blueAccent, size: size);
      case 'GoPay':
        return Icon(Icons.electric_moped_rounded, color: Colors.greenAccent, size: size);
      case 'SeaBank':
        return Icon(Icons.savings_rounded, color: Colors.orangeAccent, size: size);
      case 'Superbank':
        return Icon(Icons.rocket_launch_rounded, color: Colors.purpleAccent, size: size);
      case 'Bank Jago':
        return Icon(Icons.pets_rounded, color: Colors.tealAccent, size: size);
      case 'Cash':
        return Icon(Icons.payments_rounded, color: AppColors.warning, size: size);
      case 'QR':
        return Icon(Icons.qr_code_2_rounded, color: AppColors.info, size: size);
      case 'Debit':
        return Icon(Icons.account_balance_rounded, color: Colors.purpleAccent, size: size);
      default:
        return Icon(Icons.account_balance_wallet_rounded, color: AppColors.textMuted, size: size);
    }
  }

  static Color getPaymentColor(String method) {
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
        return AppColors.warning;
      case 'QR':
        return AppColors.info;
      case 'Debit':
        return Colors.purpleAccent;
      default:
        return AppColors.textMuted;
    }
  }
}
