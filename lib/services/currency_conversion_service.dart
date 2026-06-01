import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConversionService {
  final String _apiKey = '223dce21a2d7a47552501740'; 
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  Future<double> convert(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return amount;
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
