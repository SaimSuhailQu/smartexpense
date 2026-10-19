import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService with ChangeNotifier {
  String _currency = 'PKR';
  String _symbol = 'Rs.';
  String _primaryCurrency = 'PKR';

  String get currency => _currency;
  String get symbol => _symbol;
  String get primaryCurrency => _primaryCurrency;

  CurrencyService() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'PKR';
    _primaryCurrency = prefs.getString('primaryCurrency') ?? 'PKR';
    _updateSymbol();
    notifyListeners();
  }

  Future<void> _saveCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _currency);
    await prefs.setString('primaryCurrency', _primaryCurrency);
  }

  void setCurrency(String currency) {
    _currency = currency;
    _updateSymbol();
    _saveCurrency();
    notifyListeners();
  }

  void setPrimaryCurrency(String currency) {
    _primaryCurrency = currency;
    _saveCurrency();
    notifyListeners();
  }

  void _updateSymbol() {
    switch (_currency) {
      case 'PKR':
        _symbol = 'Rs.';
        break;
      case 'USD':
        _symbol = '\$';
        break;
      case 'EUR':
        _symbol = '€';
        break;
      case 'JPY':
        _symbol = '¥';
        break;
      default:
        _symbol = 'Rs.';
    }
  }

  /// Decimals shown for the active currency: PKR/JPY have no minor unit
  /// in practice, USD/EUR show cents.
  int get decimals => (_currency == 'USD' || _currency == 'EUR') ? 2 : 0;

  String formatAmount(double amount) {
    return '$symbol ${amount.toStringAsFixed(decimals)}';
  }

  String formatAmountWithDecimal(double amount) {
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Returns null when the string is not a valid amount, so callers can
  /// distinguish "invalid input" from a real zero.
  double? parseAmount(String amountString) {
    // Remove currency symbol and any spaces
    final cleanedString = amountString.replaceAll(_symbol, '').trim();
    // Remove any commas (for thousand separators)
    final normalizedString = cleanedString.replaceAll(',', '');

    try {
      return double.parse(normalizedString);
    } catch (e) {
      return null;
    }
  }

  String get currencySymbol => _symbol;
}
