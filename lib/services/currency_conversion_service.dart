import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConversionService {
  static const String _apiKey = String.fromEnvironment('EXCHANGE_RATE_API_KEY');
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  Future<double> convert(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    if (_apiKey.isEmpty) {
      throw Exception(
        'EXCHANGE_RATE_API_KEY environment variable is not defined. '
        'Please build the app using: flutter run --dart-define=EXCHANGE_RATE_API_KEY=your_key'
      );
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/$_apiKey/pair/$fromCurrency/$toCurrency/$amount'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['conversion_result'];
      } else {
        throw Exception('Failed to load exchange rate');
      }
    } catch (e) {
      throw Exception('Failed to convert currency: $e');
    }
  }
}
