import 'package:flutter_test/flutter_test.dart';
import 'package:smartexpense/services/csv_service.dart';

void main() {
  group('CsvService.parseAmount', () {
    test('parses plain numbers', () {
      expect(CsvService.parseAmount('1500'), 1500.0);
      expect(CsvService.parseAmount('99.99'), 99.99);
    });

    test('keeps the minus sign (was silently flipped to positive)', () {
      expect(CsvService.parseAmount('-50'), -50.0);
      expect(CsvService.parseAmount('- Rs. 1,250.75'), -1250.75);
    });

    test('strips currency symbols, spaces and thousand separators', () {
      expect(CsvService.parseAmount('Rs. 1,250'), 1250.0);
      expect(CsvService.parseAmount('\$100.50'), 100.50);
    });

    test('rejects malformed numbers instead of misparsing', () {
      expect(CsvService.parseAmount('1.2.3'), 0.0);
      expect(CsvService.parseAmount(''), 0.0);
      expect(CsvService.parseAmount('abc'), 0.0);
      expect(CsvService.parseAmount('.'), 0.0);
    });
  });
}
