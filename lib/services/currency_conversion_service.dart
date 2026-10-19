import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConversionService {
  static const String _apiKey = String.fromEnvironment('EXCHANGE_RATE_API_KEY');
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  /// In-memory rate cache: one HTTP call per currency pair per [cacheTtl],
  /// instead of one call per converted row on every rebuild.
  final Map<String, double> _rateCache = {};
  final Map<String, DateTime> _rateCacheTime = {};
  static const Duration cacheTtl = Duration(hours: 12);

  Future<double> convert(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }
    final rate = await getRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  /// Exchange rate for 1 unit of [fromCurrency] in [toCurrency], cached.
  Future<double> getRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    if (_apiKey.isEmpty) {
      throw Exception(
        'EXCHANGE_RATE_API_KEY environment variable is not defined. '
        'Please build the app using: flutter run --dart-define=EXCHANGE_RATE_API_KEY=your_key'
      );
    }

    final key = '$fromCurrency->$toCurrency';
    final cachedAt = _rateCacheTime[key];
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheTtl &&
        _rateCache.containsKey(key)) {
      return _rateCache[key]!;
    }

    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/$_apiKey/pair/$fromCurrency/$toCurrency/1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['conversion_rate'] as num).toDouble();
        _rateCache[key] = rate;
        _rateCacheTime[key] = DateTime.now();
        return rate;
      } else {
        throw Exception('Failed to load exchange rate');
      }
    } catch (e) {
      throw Exception('Failed to convert currency: $e');
    }
  }

  /// Clears cached rates (e.g. after the user changes primary currency).
  void clearCache() {
    _rateCache.clear();
    _rateCacheTime.clear();
  }
}
