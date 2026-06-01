import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/csv_service.dart';
import 'package:smartexpense/services/categorizer_service.dart';

class CsvDemoScreen extends StatefulWidget {
  const CsvDemoScreen({super.key});

  @override
  State<CsvDemoScreen> createState() => _CsvDemoScreenState();
}

class _CsvDemoScreenState extends State<CsvDemoScreen> {
  String _status = 'Ready';
  int _importedCount = 0;

  Future<void> _createSampleTemplate() async {
    setState(() {
      _status = 'Creating sample template...';
    });

    try {
      final categorizerService = Provider.of<CategorizerService>(context, listen: false);
      final csvService = CsvService(categorizerService);
      
      await csvService.createSampleFromUserImage();
      
      setState(() {
        _status = 'Sample template created and opened!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _importCsv() async {
    setState(() {
      _status = 'Importing CSV...';
    });

    try {
      final categorizerService = Provider.of<CategorizerService>(context, listen: false);
      final csvService = CsvService(categorizerService);
      
      final importedExpenses = await csvService.importFromCsv();
      
      setState(() {
        _status = 'Import completed!';
        _importedCount = importedExpenses.length;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${importedExpenses.length} expenses!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Import Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV Import Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This demo shows the CSV import functionality for the SmartExpense app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createSampleTemplate,
              child: const Text('Create Sample CSV Template'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _importCsv,
              child: const Text('Import CSV File'),
            ),
            const SizedBox(height: 32),
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16),
            ),
            if (_importedCount > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Imported $_importedCount expenses',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Click "Create Sample CSV Template" to generate a sample CSV file\n'
              '2. The file will be saved to your downloads folder\n'
              '3. Click "Import CSV File" to import expenses from a CSV file\n'
              '4. Select the CSV file when prompted\n'
              '5. The app will parse the file and import the expenses',
            ),
          ],
        ),
      ),
    );
  }
}
