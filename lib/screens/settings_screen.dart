import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/categorizer_service.dart';
import 'package:smartexpense/services/csv_service.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/services/google_drive_service.dart';
import 'package:smartexpense/services/auth_service.dart';
import 'package:smartexpense/services/theme_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/utils/stream_extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final categorizer = context.watch<CategorizerService>();
    final currencyService = context.watch<CurrencyService>();
    final themeService = context.watch<ThemeService>();
    final categories = categorizer.categories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildThemeSetting(themeService),
          const SizedBox(height: 16),
          _buildCurrencySetting(currencyService),
          const SizedBox(height: 16),
          _buildCategoryManagement(categories, categorizer),
          const SizedBox(height: 16),
          _buildImportExportSection(),
          const SizedBox(height: 16),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildThemeSetting(ThemeService themeService) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text('Theme Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themeService.availableThemes.entries.map((entry) {
                final isDynamic = entry.key == 'Dynamic';
                final chipColor = isDynamic 
                    ? Theme.of(context).colorScheme.primary 
                    : entry.value;

                return ChoiceChip(
                  label: Text(entry.key),
                  selected: themeService.themeName == entry.key,
                  selectedColor: chipColor.withAlpha(80),
                  onSelected: (selected) {
                    if (selected) {
                      themeService.setTheme(entry.key);
                      _showSnackBar('Theme changed to ${entry.key}', Colors.green);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(themeService.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleDarkMode();
                _showSnackBar(
                  value ? 'Dark mode enabled' : 'Light mode enabled',
                  Colors.green,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySetting(CurrencyService currencyService) {
    final currencies = {
      'USD': '🇺🇸 US Dollar',
      'EUR': '🇪🇺 Euro',
      'PKR': '🇵🇰 Pakistani Rupee',
      'JPY': '🇯🇵 Japanese Yen',
      'GBP': '🇬🇧 British Pound',
      'CAD': '🇨🇦 Canadian Dollar',
      'AUD': '🇦🇺 Australian Dollar',
    };

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monetization_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Currency', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: currencyService.primaryCurrency,
              decoration: const InputDecoration(
                labelText: 'Select Primary Currency',
                border: OutlineInputBorder(),
              ),
              items: currencies.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  currencyService.setPrimaryCurrency(value);
                  _showSnackBar('Primary currency changed to $value', Colors.green);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryManagement(List<String> categories, CategorizerService categorizer) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Categories', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('${categories.length} categories', 
                     style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No categories yet. Add your first category!'),
              )
            else
              SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: categories.map((category) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                        child: Text(
                          category[0].toUpperCase(),
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      title: Text(category),
                      subtitle: Text('${categorizer.categories[category]?.length ?? 0} keywords'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditCategoryDialog(category, categorizer),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteCategoryDialog(category, categorizer),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Add New Category'),
              onTap: () => _showAddCategoryDialog(categorizer),
            ),
            const Divider(),
            _buildActionTile(
              Icons.restart_alt,
              'Reset Categories',
              'Restore default categories and keywords',
              Colors.orange,
              () => _showResetCategoriesDialog(categorizer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportExportSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Data Management', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              Icons.upload_file,
              'Import from CSV',
              'Import expenses from CSV file',
              Colors.green,
              _handleImport,
            ),
            _buildActionTile(
              Icons.file_download,
              'Export Data',
              'Export expenses to a CSV file',
              Colors.blue,
              _showExportDialog,
            ),
            _buildActionTile(
              Icons.description,
              'Download Template',
              'Get sample CSV templates',
              Colors.orange,
              _handleDownloadTemplate,
            ),
            const Divider(),
            _buildActionTile(
              Icons.upload,
              'Import Categories from JSON',
              'Import categories from JSON file',
              Colors.deepPurple,
              _handleImportCategoriesFromJson,
            ),
            _buildActionTile(
              Icons.backup,
              'Backup to Google Drive',
              'Save your data to Google Drive',
              Colors.purple,
              _handleBackupCategories,
            ),
            _buildActionTile(
              Icons.restore,
              'Restore from Google Drive',
              'Restore your data from Google Drive',
              Colors.teal,
              _handleRestoreCategories,
            ),
            _buildActionTile(
              Icons.sync,
              'Full Sync',
              'Complete synchronization with Google Drive',
              Colors.indigo,
              _handleSyncToGoogleDrive,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Export Current Month'),
              onTap: () {
                Navigator.of(context).pop();
                _handleExport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Export Any Month'),
              onTap: () {
                Navigator.of(context).pop();
                _handleExportAnyMonth();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Export Year'),
              onTap: () {
                Navigator.of(context).pop();
                _handleExportYear();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Smart Expense Tracker',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Created by SSQ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLoadingDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please wait...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleImportCategoriesFromJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        if (!mounted) return;
        await _showLoadingDialog();
        
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        if (!mounted) return;
        final categorizer = context.read<CategorizerService>();
        await categorizer.importCategoriesFromJson(jsonString);
        
        if (mounted) {
          _hideLoadingDialog();
          _showSnackBar('Categories imported successfully from JSON!', Colors.green);
          setState(() {}); // Refresh the UI
        }
      } else {
        if (mounted) {
          _showSnackBar('No file selected', Colors.orange);
        }
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Import failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleImport() async {
    try {
      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();
      final categorizer = context.read<CategorizerService>();
      final csvService = CsvService(categorizer);

      await _showLoadingDialog();
      final expenses = await csvService.importFromCsv();
      
      for (final expense in expenses) {
        await expenseService.addExpense(expense);
      }

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Successfully imported ${expenses.length} expenses', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Import failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleExport() async {
    try {
      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();
      final categorizer = context.read<CategorizerService>();
      final csvService = CsvService(categorizer);

      await _showLoadingDialog();
      final now = DateTime.now();
      final expenses = await expenseService.getExpensesStream(TimeRange.monthly, now).firstOrDefault([]);
      await csvService.exportToCsv(expenses);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export completed successfully', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleExportAnyMonth() async {
    try {
      if (!mounted) return;
      
      // Show month picker dialog
      final selectedMonth = await _showMonthPickerDialog();
      if (selectedMonth == null) return;

      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();
      final categorizer = context.read<CategorizerService>();
      final csvService = CsvService(categorizer);

      await _showLoadingDialog();
      final expenses = await expenseService.getExpensesStream(TimeRange.monthly, selectedMonth).firstOrDefault([]);
      
      if (expenses.isEmpty) {
        if (mounted) {
          _hideLoadingDialog();
          _showSnackBar('No expenses found for the selected month', Colors.orange);
        }
        return;
      }

      await csvService.exportMonthlyToCsv(expenses, selectedMonth);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Exported ${expenses.length} expenses successfully', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleExportYear() async {
    try {
      if (!mounted) return;
      
      // Show year picker dialog
      final selectedYear = await _showYearPickerDialog();
      if (selectedYear == null) return;

      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();
      final categorizer = context.read<CategorizerService>();
      final csvService = CsvService(categorizer);

      await _showLoadingDialog();
      final yearDate = DateTime(selectedYear, 1, 1);
      final expenses = await expenseService.getExpensesStream(TimeRange.yearly, yearDate).firstOrDefault([]);
      
      if (expenses.isEmpty) {
        if (mounted) {
          _hideLoadingDialog();
          _showSnackBar('No expenses found for the selected year', Colors.orange);
        }
        return;
      }

      await csvService.exportYearlyToCsv(expenses, selectedYear);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Exported ${expenses.length} expenses for year $selectedYear', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<DateTime?> _showMonthPickerDialog() async {
    if (!mounted) return null;
    
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month);
    
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Month to Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
                      });
                    },
                  ),
                  Text(
                    '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: selectedDate.isBefore(DateTime(now.year, now.month))
                        ? () {
                            setState(() {
                              selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select any month up to ${_getMonthName(now.month)} ${now.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedDate),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
    
    return result;
  }

  Future<int?> _showYearPickerDialog() async {
    if (!mounted) return null;
    
    final now = DateTime.now();
    int selectedYear = now.year;
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Year to Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        selectedYear--;
                      });
                    },
                  ),
                  Text(
                    selectedYear.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: selectedYear < now.year
                        ? () {
                            setState(() {
                              selectedYear++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select any year up to ${now.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (selectedYear == now.year)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Note: This will export all expenses for $selectedYear (including partial year)',
                    style: TextStyle(fontSize: 11, color: Colors.blue[700], fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedYear),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
    
    return result;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _handleDownloadTemplate() async {
    try {
      if (!mounted) return;
      final categorizer = context.read<CategorizerService>();
      final csvService = CsvService(categorizer);

      await _showLoadingDialog();
      await csvService.createCustomFormatTemplate();

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Template downloaded successfully', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Template download failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleBackupCategories() async {
    try {
      if (!mounted) return;
      
      // Check authentication first
      final authService = context.read<AuthService>();
      final isDriveAvailable = await authService.isDriveAccessAvailable();
      
      if (!isDriveAvailable) {
        if (mounted) {
          _showSnackBar('Please sign in with Google to access Drive', Colors.orange);
        }
        return;
      }

      if (!mounted) return;
      final googleDriveService = context.read<GoogleDriveService>();
      final categorizerService = context.read<CategorizerService>();

      await _showLoadingDialog();
      
      // Test connection first
      await googleDriveService.testDriveConnection();
      
      await googleDriveService.backupCategories(categorizerService);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar(
          'Categories backed up successfully to Google Drive!', 
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        final authService = context.read<AuthService>();
        final errorMessage = authService.getSyncErrorMessage(e);
        _showSnackBar(errorMessage, Colors.red);
      }
    }
  }

  Future<void> _handleRestoreCategories() async {
    try {
      if (!mounted) return;
      
      // Check authentication first
      final authService = context.read<AuthService>();
      final isDriveAvailable = await authService.isDriveAccessAvailable();
      
      if (!isDriveAvailable) {
        if (mounted) {
          _showSnackBar('Please sign in with Google to access Drive', Colors.orange);
        }
        return;
      }

      // Show confirmation dialog
      final confirmed = await _showRestoreConfirmationDialog();
      if (!confirmed) return;

      if (!mounted) return;
      final googleDriveService = context.read<GoogleDriveService>();

      await _showLoadingDialog();
      
      // Test connection first
      await googleDriveService.testDriveConnection();
      
      await googleDriveService.restoreCategoriesFromDrive();

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Categories restored successfully from Google Drive!', Colors.green);
        setState(() {}); // Refresh the UI
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        final authService = context.read<AuthService>();
        final errorMessage = authService.getSyncErrorMessage(e);
        _showSnackBar(errorMessage, Colors.red);
      }
    }
  }

  Future<void> _handleSyncToGoogleDrive() async {
    try {
      if (!mounted) return;
      
      // Check authentication first
      final authService = context.read<AuthService>();
      final isDriveAvailable = await authService.isDriveAccessAvailable();
      
      if (!isDriveAvailable) {
        if (mounted) {
          _showSnackBar('Please sign in with Google to access Drive', Colors.orange);
        }
        return;
      }

      if (!mounted) return;
      final googleDriveService = context.read<GoogleDriveService>();

      await _showLoadingDialog();
      
      // Test connection first
      await googleDriveService.testDriveConnection();
      
      await googleDriveService.backupAllData();

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Successfully synced all data to Google Drive!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        final authService = context.read<AuthService>();
        final errorMessage = authService.getSyncErrorMessage(e);
        _showSnackBar(errorMessage, Colors.red);
      }
    }
  }

  Future<bool> _showRestoreConfirmationDialog() async {
    if (!mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Categories'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will restore categories from your latest Google Drive backup.'),
            SizedBox(height: 8),
            Text(
              'New categories will be added to your existing ones.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Do you want to continue?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showAddCategoryDialog(CategorizerService categorizer) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                categorizer.addCategory(name);
                Navigator.of(context).pop();
                _showSnackBar('Category "$name" added successfully', Colors.green);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String category, CategorizerService categorizer) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text('Edit $category')),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showRenameCategoryDialog(category, categorizer),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Add new keyword',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      categorizer.addKeywordToCategory(category, value.trim());
                      controller.clear();
                      setState(() {});
                      _showSnackBar('Keyword added to $category', Colors.green);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Current keywords:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: categorizer.categories[category]!
                          .map((keyword) => Chip(
                                label: Text(keyword),
                                onDeleted: () {
                                  categorizer.removeKeywordFromCategory(category, keyword);
                                  setState(() {});
                                  _showSnackBar('Keyword "$keyword" removed', Colors.orange);
                                },
                                deleteIcon: const Icon(Icons.close, size: 18),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () {
                final keyword = controller.text.trim();
                if (keyword.isNotEmpty) {
                  categorizer.addKeywordToCategory(category, keyword);
                  controller.clear();
                  setState(() {});
                  _showSnackBar('Keyword added to $category', Colors.green);
                }
              },
              child: const Text('Add Keyword'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(String category, CategorizerService categorizer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete "$category"?'),
            const SizedBox(height: 8),
            Text(
              'This will remove the category and all its ${categorizer.categories[category]?.length ?? 0} keywords.',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              categorizer.removeCategory(category);
              Navigator.of(context).pop();
              _showSnackBar('Category "$category" deleted', Colors.orange);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(String category, CategorizerService categorizer) {
    final controller = TextEditingController(text: category);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != category) {
                if (categorizer.categories.containsKey(newName)) {
                  _showSnackBar('Category "$newName" already exists!', Colors.red);
                } else {
                  categorizer.renameCategory(category, newName);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close edit dialog too
                  _showSnackBar('Category renamed to "$newName"', Colors.green);
                  setState(() {});
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showResetCategoriesDialog(CategorizerService categorizer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Categories'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will restore all default categories and keywords.'),
            SizedBox(height: 8),
            Text(
              'All your custom categories and keywords will be lost.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('This action cannot be undone.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              categorizer.resetToDefaults();
              Navigator.of(context).pop();
              _showSnackBar('Categories reset to defaults', Colors.green);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}