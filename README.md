# SmartExpense - CSV Import Feature

This document explains how to use the CSV import functionality in the SmartExpense app.

## Overview

The SmartExpense app now supports importing expenses from CSV files. This feature allows users to quickly add multiple expenses to their account by importing data from a spreadsheet.

## CSV Format

The app supports two CSV formats:

### Standard Format
A standard format with columns for Title, Amount, Date, Category, and Notes:

```
Title,Amount,Date,Category,Notes
Grocery Shopping,150.50,2024-01-15,Groceries,Weekly shopping
Movie Tickets,25.00,2024-01-14,Entertainment,Weekend movie
```

### Custom Format (Based on User Image)
A custom format where the first column is the category, and subsequent columns represent daily expenses:

```
Category,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
Food,200,150,300,100,180,220,175,250,190,210,180,240,160,200,220,180,190,230,170,210,195,225,185,205,175,195,215,185,200,190,210
Transport,50,75,100,25,60,80,45,70,55,65,50,85,40,60,75,50,55,80,45,65,58,78,52,68,48,58,72,52,60,55,65
```

## How to Use

### Creating a Sample CSV File
1. Open the SmartExpense app
2. Navigate to the Dashboard
3. Click the "Description" icon in the top right corner
4. On the CSV Demo screen, click "Create Sample CSV Template"
5. A sample CSV file will be created and opened automatically

### Importing a CSV File
1. Open the SmartExpense app
2. Navigate to the Dashboard
3. Click the "Upload File" icon in the top right corner
4. Select your CSV file when prompted
5. The app will parse the file and import all expenses
6. You'll see a confirmation message with the number of imported expenses

## Technical Implementation

The CSV import functionality is implemented in the `CsvService` class, which handles:

- File selection using the `file_picker` package
- CSV parsing using the `csv` package
- Data validation and error handling
- Expense creation and categorization

The dashboard has been updated to include:
- An import button in the AppBar
- A demo screen for testing the CSV functionality

## Testing

To test the CSV import functionality:

1. Run the app
2. Navigate to the CSV Demo screen
3. Create a sample CSV template
4. Modify the template as needed
5. Use the import feature to import the expenses
6. Verify that the expenses appear in the dashboard

## Dependencies

The CSV import feature requires the following dependencies:

- `file_picker: ^10.2.0` - For selecting CSV files
- `csv: ^6.0.0` - For parsing CSV data
- `path_provider: ^2.1.5` - For accessing file system directories
- `open_file: ^3.3.2` - For opening generated CSV files

These dependencies are already included in the `pubspec.yaml` file.
