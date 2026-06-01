import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategorizerService with ChangeNotifier {
  final Map<String, List<String>> _categories = {};
  final List<String> _personNames = [];
  
  static const String _categoriesKey = 'categories_data';
  static const String _personNamesKey = 'person_names_data';
  
  CategorizerService() {
    _loadData();
  }

  // Load data from SharedPreferences
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load categories
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson != null) {
        final categoriesData = json.decode(categoriesJson) as Map<String, dynamic>;
        _categories.clear();
        for (var entry in categoriesData.entries) {
          _categories[entry.key] = List<String>.from(entry.value);
        }
      } else {
        // Set default categories if none exist
        _setDefaultCategories();
      }
      
      // Load person names
      final personNamesJson = prefs.getString(_personNamesKey);
      if (personNamesJson != null) {
        final personNamesData = json.decode(personNamesJson) as List<dynamic>;
        _personNames.clear();
        _personNames.addAll(List<String>.from(personNamesData));
      } else {
        // Set default person names if none exist
        _setDefaultPersonNames();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories data: $e');
      // Set defaults on error
      _setDefaultCategories();
      _setDefaultPersonNames();
      notifyListeners();
    }
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save categories
      final categoriesJson = json.encode(_categories);
      await prefs.setString(_categoriesKey, categoriesJson);
      
      // Save person names
      final personNamesJson = json.encode(_personNames);
      await prefs.setString(_personNamesKey, personNamesJson);
    } catch (e) {
      debugPrint('Error saving categories data: $e');
    }
  }

  void _setDefaultCategories() {
    _categories.clear();
    _categories.addAll({
      'Groceries': ['milk', 'bread', 'eggs', 'cheese', 'butter', 'yogurt', 'fruit', 'vegetables'],
      'Transport': ['gas', 'fuel', 'taxi', 'uber', 'lyft', 'bus', 'train', 'parking'],
      'Entertainment': ['movie', 'concert', 'game', 'netflix', 'spotify', 'hulu'],
      'Utilities': ['electricity', 'water', 'gas', 'internet', 'phone'],
      'Shopping': ['clothes', 'shoes', 'electronics', 'books', 'gifts'],
      'Food': ['restaurant', 'cafe', 'fast food', 'delivery'],
      'Other': [],
    });
  }

  void _setDefaultPersonNames() {
    _personNames.clear();
    _personNames.addAll([
      'saim', 'shamikh', 'suhail', 'shoaib', 'mother', 'sister', 'baji', 'father', 'brother', 'mom', 'dad', 'uncle', 'aunt'
    ]);
  }

  String categorizeExpense(String description) {
    final descLower = description.toLowerCase();
    
    // First, check if any person name is mentioned
    for (var personName in _personNames) {
      if (descLower.contains(personName)) {
        // Capitalize first letter for consistency
        return personName[0].toUpperCase() + personName.substring(1);
      }
    }
    
    // Check if description contains any existing category name
    for (var categoryName in _categories.keys) {
      if (descLower.contains(categoryName.toLowerCase())) {
        return categoryName;
      }
    }
    
    // If no person name found, use regular categorization
    for (var category in _categories.entries) {
      for (var keyword in category.value) {
        if (descLower.contains(keyword)) {
          return category.key;
        }
      }
    }
    
    return 'Uncategorized';
  }

  // Check if description suggests a new category should be created
  bool shouldCreateNewCategory(String description) {
    final descLower = description.toLowerCase();
    
    // Check if description contains a person name that's not yet a category
    for (var personName in _personNames) {
      if (descLower.contains(personName) && 
          !_categories.containsKey(personName[0].toUpperCase() + personName.substring(1))) {
        return true;
      }
    }
    
    return false;
  }

  // Get suggested category name from description
  String getSuggestedCategoryName(String description) {
    final descLower = description.toLowerCase();
    
    // Check for person names
    for (var personName in _personNames) {
      if (descLower.contains(personName)) {
        return personName[0].toUpperCase() + personName.substring(1);
      }
    }
    
    return 'New Category';
  }

  // Method to add new person names
  void addPersonName(String personName) {
    final normalizedName = personName.toLowerCase().trim();
    if (!_personNames.contains(normalizedName)) {
      _personNames.add(normalizedName);
      notifyListeners();
    }
  }

  // Method to remove person names
  void removePersonName(String personName) {
    final normalizedName = personName.toLowerCase().trim();
    if (_personNames.remove(normalizedName)) {
      notifyListeners();
    }
  }

  List<String> get personNames => _personNames.map((name) => 
    name[0].toUpperCase() + name.substring(1)).toList();

  void addCategory(String category) {
    if (!_categories.containsKey(category)) {
      _categories[category] = [];
      _saveData();
      notifyListeners();
    }
  }

  // NEW: Method to remove a category
  void removeCategory(String category) {
    if (_categories.remove(category) != null) {
      _saveData();
      notifyListeners();
    }
  }

  // NEW: Method to rename a category
  void renameCategory(String oldName, String newName) {
    if (_categories.containsKey(oldName) && !_categories.containsKey(newName)) {
      final keywords = _categories[oldName]!;
      _categories.remove(oldName);
      _categories[newName] = keywords;
      _saveData();
      notifyListeners();
    }
  }

  void addKeywordToCategory(String category, String keyword) {
    if (_categories.containsKey(category)) {
      final normalizedKeyword = keyword.toLowerCase().trim();
      if (!_categories[category]!.contains(normalizedKeyword)) {
        _categories[category]!.add(normalizedKeyword);
        _saveData();
        notifyListeners();
      }
    }
  }

  // NEW: Method to remove a keyword from a category
  void removeKeywordFromCategory(String category, String keyword) {
    if (_categories.containsKey(category)) {
      final normalizedKeyword = keyword.toLowerCase().trim();
      if (_categories[category]!.remove(normalizedKeyword)) {
        _saveData();
        notifyListeners();
      }
    }
  }

  // NEW: Method to get category statistics
  Map<String, int> getCategoryStats() {
    return _categories.map((key, value) => MapEntry(key, value.length));
  }

  // NEW: Method to check if category has keywords
  bool categoryHasKeywords(String category) {
    return _categories[category]?.isNotEmpty ?? false;
  }

  // NEW: Method to get all keywords across categories
  List<String> getAllKeywords() {
    final allKeywords = <String>[];
    for (var keywords in _categories.values) {
      allKeywords.addAll(keywords);
    }
    return allKeywords;
  }

  // NEW: Method to find categories containing a specific keyword
  List<String> findCategoriesWithKeyword(String keyword) {
    final normalizedKeyword = keyword.toLowerCase().trim();
    final categoriesWithKeyword = <String>[];
    
    for (var entry in _categories.entries) {
      if (entry.value.contains(normalizedKeyword)) {
        categoriesWithKeyword.add(entry.key);
      }
    }
    
    return categoriesWithKeyword;
  }

  // NEW: Method to export categories for backup
  Map<String, dynamic> exportCategories() {
    return {
      'categories': Map<String, List<String>>.from(_categories),
      'personNames': List<String>.from(_personNames),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // NEW: Method to import categories from backup
  void importCategories(Map<String, dynamic> data) {
    try {
      if (data.containsKey('categories')) {
        _categories.clear();
        final importedCategories = data['categories'] as Map<String, dynamic>;
        for (var entry in importedCategories.entries) {
          _categories[entry.key] = List<String>.from(entry.value);
        }
      }
      
      if (data.containsKey('personNames')) {
        _personNames.clear();
        _personNames.addAll(List<String>.from(data['personNames']));
      }
      
      _saveData();
      notifyListeners();
    } catch (e) {
      // Handle import error gracefully
      debugPrint('Error importing categories: $e');
    }
  }

  // NEW: Method to import categories from JSON file
  Future<void> importCategoriesFromJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      importCategories(data);
    } catch (e) {
      debugPrint('Error importing categories from JSON: $e');
      throw Exception('Invalid JSON format');
    }
  }

  // NEW: Method to reset to default categories
  void resetToDefaults() {
    _categories.clear();
    _categories.addAll({
      'Groceries': ['milk', 'bread', 'eggs', 'cheese', 'butter', 'yogurt', 'fruit', 'vegetables'],
      'Transport': ['gas', 'fuel', 'taxi', 'uber', 'lyft', 'bus', 'train', 'parking'],
      'Entertainment': ['movie', 'concert', 'game', 'netflix', 'spotify', 'hulu'],
      'Utilities': ['electricity', 'water', 'gas', 'internet', 'phone'],
      'Shopping': ['clothes', 'shoes', 'electronics', 'books', 'gifts'],
      'Food': ['restaurant', 'cafe', 'fast food', 'delivery'],
      'Other': [],
    });
    
    _personNames.clear();
    _personNames.addAll([
      'saim', 'shamikh', 'suhail', 'mother', 'sister', 'baji', 'father', 'brother', 'mom', 'dad', 'uncle', 'aunt'
    ]);
    
    _saveData();
    notifyListeners();
  }

  Map<String, List<String>> get categories => _categories;
}
