import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/models/loan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartexpense/services/auth_service.dart';
import 'package:smartexpense/services/categorizer_service.dart';

class GoogleDriveService extends ChangeNotifier {
  final AuthService _authService;
  final CategorizerService _categorizerService;

  GoogleDriveService(this._authService, this._categorizerService);

  static const String appName = 'SmartExpense';
  static const String folderMimeType = 'application/vnd.google-apps.folder';
  static const String csvMimeType = 'text/csv';

  Future<String?> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    try {
      // First, try to find existing folder in regular Drive
      const folderQuery = "name = '$appName' and mimeType = '$folderMimeType' and trashed = false";
      final folderList = await driveApi.files.list(
        q: folderQuery,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        debugPrint('Found existing app folder: ${folderList.files!.first.id}');
        return folderList.files!.first.id;
      }

      // Create new folder in regular Drive
      final folderMetadata = drive.File()
        ..name = appName
        ..mimeType = folderMimeType
        ..description = 'SmartExpense app data backup folder';

      final folder = await driveApi.files.create(
        folderMetadata,
        $fields: 'id, name',
      );
      debugPrint('Created new app folder: ${folder.id}');
      return folder.id;
    } catch (e) {
      debugPrint('Error getting/creating app folder: $e');
      if (e.toString().contains('403')) {
        throw Exception('Insufficient permissions to access Google Drive. Please sign out and sign in again to grant proper permissions.');
      }
      throw Exception('Failed to access Google Drive folder: ${e.toString()}');
    }
  }

  // Test Drive connectivity
  Future<bool> testDriveConnection() async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) {
      throw Exception('Google Drive access not available. Please sign in with Google.');
    }

    try {
      await driveApi.about.get($fields: 'user');
      return true;
    } catch (e) {
      debugPrint('Drive connection test failed: $e');
      throw Exception('Cannot connect to Google Drive: ${e.toString()}');
    }
  }

  Future<bool> backupExpenses(List<Expense> expenses) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) {
      throw Exception('Google Drive access not available. Please sign in with Google.');
    }

    try {
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        throw Exception('Failed to create or access backup folder');
      }

      final csvContent = _expensesToCsv(expenses);
      if (csvContent.isEmpty) {
        throw Exception('No expense data to backup');
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/expenses_backup.csv');
      await tempFile.writeAsString(csvContent);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileMetadata = drive.File()
        ..name = 'expenses_backup_$timestamp.csv'
        ..parents = [folderId]
        ..description = 'SmartExpense expenses backup created on ${DateTime.now().toIso8601String()}';

      final media = drive.Media(
        tempFile.openRead(),
        await tempFile.length(),
        contentType: csvMimeType,
      );

      final uploadedFile = await driveApi.files.create(fileMetadata, uploadMedia: media);
      await tempFile.delete();

      debugPrint('Successfully backed up ${expenses.length} expenses to Drive: ${uploadedFile.id}');
      return true;
    } catch (e) {
      debugPrint('Error backing up expenses: $e');
      throw Exception('Failed to backup expenses: ${e.toString()}');
    }
  }

  Future<bool> backupIncomes(List<Income> incomes) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return false;

    try {
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) return false;

      final csvContent = _incomesToCsv(incomes);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/incomes_backup.csv');
      await tempFile.writeAsString(csvContent);

      final fileMetadata = drive.File()
        ..name = 'incomes_backup_${DateTime.now().millisecondsSinceEpoch}.csv'
        ..parents = [folderId];

      final media = drive.Media(
        tempFile.openRead(),
        await tempFile.length(),
        contentType: csvMimeType,
      );

      await driveApi.files.create(fileMetadata, uploadMedia: media);
      await tempFile.delete();

      return true;
    } catch (e) {
      debugPrint('Error backing up incomes: $e');
      return false;
    }
  }

  Future<bool> backupLoans(List<Loan> loans) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return false;

    try {
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) return false;

      final csvContent = _loansToCsv(loans);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/loans_backup.csv');
      await tempFile.writeAsString(csvContent);

      final fileMetadata = drive.File()
        ..name = 'loans_backup_${DateTime.now().millisecondsSinceEpoch}.csv'
        ..parents = [folderId];

      final media = drive.Media(
        tempFile.openRead(),
        await tempFile.length(),
        contentType: csvMimeType,
      );

      await driveApi.files.create(fileMetadata, uploadMedia: media);
      await tempFile.delete();

      return true;
    } catch (e) {
      debugPrint('Error backing up loans: $e');
      return false;
    }
  }

  Future<bool> backupCategories([CategorizerService? categorizerService]) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) {
      throw Exception('Google Drive access not available. Please sign in with Google.');
    }

    try {
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        throw Exception('Failed to create or access backup folder');
      }

      final categoriesToUse = categorizerService?.categories ?? _categorizerService.categories;
      if (categoriesToUse.isEmpty) {
        throw Exception('No categories to backup');
      }

      final csvContent = _categoriesToCsv(categoriesToUse);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/categories_backup.csv');
      await tempFile.writeAsString(csvContent);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileMetadata = drive.File()
        ..name = 'categories_backup_$timestamp.csv'
        ..parents = [folderId]
        ..description = 'SmartExpense categories backup created on ${DateTime.now().toIso8601String()}';

      final media = drive.Media(
        tempFile.openRead(),
        await tempFile.length(),
        contentType: csvMimeType,
      );

      final uploadedFile = await driveApi.files.create(fileMetadata, uploadMedia: media);
      await tempFile.delete();

      debugPrint('Successfully backed up ${categoriesToUse.length} categories to Drive: ${uploadedFile.id}');
      return true;
    } catch (e) {
      debugPrint('Error backing up categories: $e');
      throw Exception('Failed to backup categories: ${e.toString()}');
    }
  }

  Future<bool> backupAllData() async {
    try {
      // Test connection first
      await testDriveConnection();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Starting full backup for user: ${user.uid}');

      // Fetch all data with timeout
      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get()
          .timeout(const Duration(seconds: 30));
      
      final expenses = expenseSnapshot.docs.map((doc) => 
        Expense.fromMap(doc.data()..['id'] = doc.id)).toList();
      
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('incomes')
          .get()
          .timeout(const Duration(seconds: 30));
      
      final incomes = incomeSnapshot.docs.map((doc) => 
        Income.fromMap(doc.data()..['id'] = doc.id)).toList();
      
      final loanSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('loans')
          .get()
          .timeout(const Duration(seconds: 30));
      
      final loans = loanSnapshot.docs.map((doc) => Loan.fromMap(doc.data())).toList();
      
      debugPrint('Data fetched - Expenses: ${expenses.length}, Incomes: ${incomes.length}, Loans: ${loans.length}');

      // Backup each data type
      bool expensesSuccess = true;
      bool incomesSuccess = true;
      bool loansSuccess = true;
      bool categoriesSuccess = true;

      if (expenses.isNotEmpty) {
        expensesSuccess = await backupExpenses(expenses);
      }
      
      if (incomes.isNotEmpty) {
        incomesSuccess = await backupIncomes(incomes);
      }
      
      if (loans.isNotEmpty) {
        loansSuccess = await backupLoans(loans);
      }
      
      categoriesSuccess = await backupCategories(_categorizerService);
      
      final allSuccess = expensesSuccess && incomesSuccess && loansSuccess && categoriesSuccess;
      
      if (allSuccess) {
        debugPrint('Full backup completed successfully');
      } else {
        debugPrint('Some backup operations failed');
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('Error in full backup: $e');
      throw Exception('Full backup failed: ${e.toString()}');
    }
  }

  String _expensesToCsv(List<Expense> expenses) {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('ID,Title,Amount,Date,Category,Notes');
    for (final expense in expenses) {
      csvBuffer.writeln(
        '"${expense.id}","${expense.title}",${expense.amount},"${expense.date.toIso8601String()}","${expense.category}","${expense.notes}"'
      );

    }
    return csvBuffer.toString();
  }

  String _incomesToCsv(List<Income> incomes) {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('ID,Title,Amount,Date,Category,Notes');
    for (final income in incomes) {
      csvBuffer.writeln(
        '"${income.id}","${income.title}",${income.amount},"${income.date.toIso8601String()}","${income.category}","${income.notes}"'
      );

    }
    return csvBuffer.toString();
  }

  String _loansToCsv(List<Loan> loans) {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('ID,Title,Amount,RemainingAmount,Date,Type,Notes');
    for (final loan in loans) {
      csvBuffer.writeln(
        '"${loan.id}","${loan.title}",${loan.amount},${loan.remainingAmount},"${loan.date.toIso8601String()}","${loan.type}","${loan.notes}"'
      );

    }
    return csvBuffer.toString();
  }

  String _categoriesToCsv(Map<String, List<String>> categories) {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Category,Keywords');
    categories.forEach((category, keywords) {
      csvBuffer.writeln('"$category","${keywords.join(",")}"');
    });
    return csvBuffer.toString();
  }

  Future<bool> restoreCategoriesFromDrive() async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) {
      throw Exception('Google Drive access not available. Please sign in with Google.');
    }

    try {
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        throw Exception('Failed to access backup folder');
      }

      // Find the latest categories backup file
      final fileList = await driveApi.files.list(
        q: "name contains 'categories_backup' and '$folderId' in parents and trashed = false",
        orderBy: 'createdTime desc',
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No categories backup files found in Google Drive');
      }

      final latestFile = fileList.files!.first;
      debugPrint('Found categories backup file: ${latestFile.name} (${latestFile.id})');

      final fileId = latestFile.id!;
      final file = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia)
          .timeout(const Duration(seconds: 60));
      
      if (file is drive.Media) {
        final bytesBuilder = BytesBuilder();
        await for (final chunk in file.stream) {
          bytesBuilder.add(chunk);
        }
        final csvContent = String.fromCharCodes(bytesBuilder.takeBytes());
        
        if (csvContent.isEmpty) {
          throw Exception('Downloaded backup file is empty');
        }

        await _csvToCategories(csvContent, _categorizerService);
        debugPrint('Successfully restored categories from Drive');
        return true;
      }

      throw Exception('Failed to download backup file');
    } catch (e) {
      debugPrint('Error restoring categories from drive: $e');
      throw Exception('Failed to restore categories: ${e.toString()}');
    }
  }

  Future<void> _csvToCategories(String csvContent, CategorizerService categorizerService) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length <= 1) {
        throw Exception('CSV file contains no data');
      }

      int categoriesRestored = 0;
      int keywordsRestored = 0;

      // Process each line (skip header)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          // Parse CSV line with better error handling
          if (!line.contains('","')) {
            debugPrint('Skipping malformed line: $line');
            continue;
          }

          final parts = line.split('","');
          if (parts.length < 2) {
            debugPrint('Skipping incomplete line: $line');
            continue;
          }

          final category = parts[0].replaceAll('"', '').trim();
          final keywordsString = parts[1].replaceAll('"', '').trim();
          
          if (category.isEmpty) {
            debugPrint('Skipping empty category name');
            continue;
          }

          final keywords = keywordsString.split(',')
              .map((kw) => kw.trim())
              .where((kw) => kw.isNotEmpty)
              .toList();

          // Add category and keywords to the service
          categorizerService.addCategory(category);
          categoriesRestored++;

          for (final keyword in keywords) {
            categorizerService.addKeywordToCategory(category, keyword);
            keywordsRestored++;
          }

          debugPrint('Restored category: $category with ${keywords.length} keywords');
        } catch (e) {
          debugPrint('Error processing line $i: $e');
          continue;
        }
      }

      debugPrint('Categories restore completed: $categoriesRestored categories, $keywordsRestored keywords');
      
      if (categoriesRestored == 0) {
        throw Exception('No valid categories found in backup file');
      }
    } catch (e) {
      debugPrint('Error parsing CSV categories: $e');
      throw Exception('Failed to parse categories backup: ${e.toString()}');
    }
  }

  Future<bool> restoreFromDrive() async {
    // Restore categories first
    await restoreCategoriesFromDrive();
    // Add other restoration logic here if needed
    return true;
  }
}
