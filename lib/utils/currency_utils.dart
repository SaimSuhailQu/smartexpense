import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/currency_service.dart';

class CurrencyUtils {
  static String getCurrencySymbol(BuildContext context) {
    return Provider.of<CurrencyService>(context, listen: false).symbol;
  }

  static String formatAmount(BuildContext context, double amount) {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    return currencyService.formatAmount(amount);
  }

  static String formatAmountWithDecimal(BuildContext context, double amount) {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    return currencyService.formatAmountWithDecimal(amount);
  }
}
