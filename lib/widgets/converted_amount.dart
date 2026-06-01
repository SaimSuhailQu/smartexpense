import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/currency_conversion_service.dart';
import 'package:smartexpense/services/currency_service.dart';

class ConvertedAmount extends StatelessWidget {
  final double amount;
  final String fromCurrency;
  final TextStyle? style;

  const ConvertedAmount(
      {super.key,
      required this.amount,
      required this.fromCurrency,
      this.style});

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyService>();
    final conversionService = context.read<CurrencyConversionService>();
    final toCurrency = currencyService.primaryCurrency;

    if (fromCurrency == toCurrency) {
      return Text(
        currencyService.formatAmountWithDecimal(amount),
        style: style,
      );
    }

    return FutureBuilder<double>(
      future: conversionService.convert(amount, fromCurrency, toCurrency),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Tooltip(
            message: snapshot.error.toString(),
            child: const Icon(Icons.error, color: Colors.red),
          );
        }
        final convertedAmount = snapshot.data ?? 0.0;
        return Text(
          currencyService.formatAmountWithDecimal(convertedAmount),
          style: style,
        );
      },
    );
  }
}
